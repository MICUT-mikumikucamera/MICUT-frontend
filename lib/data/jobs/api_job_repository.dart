import 'dart:convert';
import 'dart:io';
import 'package:cross_file/cross_file.dart';

import 'package:http/http.dart' as http;

import 'job.dart';
import 'job_repository.dart';

/// 실제 서버 구현. 백엔드 명세 v0.3 기준.
///
///   POST   /api/v1/jobs                  multipart(photo, w, h, rotation, fx?, crop JSON)  → Job
///   GET    /api/v1/jobs/{job_id}                                           → Job
///   POST   /api/v1/jobs/{job_id}/retry                                     → Job
///   POST   /api/v1/jobs/{job_id}/discard                                   → 204
///
/// 접수에는 `X-Device-Id` 헤더를 같이 보낸다. 그래야 얻은 카드가 이 기기의
/// 컬렉션에 기록되고 `result.new_card_ids` 가 채워진다 (명세 v0.3 §2).
class ApiJobRepository extends JobRepository {
  ApiJobRepository({required this.baseUrl, this.deviceId, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;

  /// 없으면 헤더를 보내지 않는다. 그 경우 카드는 정해지지만 컬렉션에 기록되지 않는다.
  final Future<String> Function()? deviceId;
  final http.Client _client;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _headers() async {
    final resolve = deviceId;
    if (resolve == null) return const {};
    try {
      return {'X-Device-Id': await resolve()};
    } catch (_) {
      // 기기 ID를 못 읽어도 접수 자체는 막지 않는다. 컬렉션 기록만 빠진다.
      return const {};
    }
  }

  @override
  Future<Job> createJob(XFile photo, CaptureInfo capture) async {
    final req = http.MultipartRequest('POST', _u('/api/v1/jobs'))
      ..headers.addAll(await _headers())
      ..files.add(http.MultipartFile.fromBytes(
          'photo', await photo.readAsBytes(),
          filename: photo.name.isEmpty ? 'photo.jpg' : photo.name))
      ..fields['w'] = capture.w.toString()
      ..fields['h'] = capture.h.toString()
      ..fields['rotation'] = capture.rotation.toString()
      ..fields['crop'] = jsonEncode((capture.crop ??
              CropRegion(x: 0, y: 0, width: capture.w, height: capture.h))
          .toJson());
    if (capture.fx != null) req.fields['fx'] = capture.fx.toString();
    final res = await http.Response.fromStream(await _client.send(req));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      // 업로드 실패는 job 없이 {status: failed, error: {...}} 만 온다.
      throw UploadException(
          JobError.fromJson(body['error'] as Map<String, dynamic>));
    }
    return Job.fromJson(body);
  }

  @override
  Future<Job> getJob(String jobId) async {
    final res = await _client.get(_u('/api/v1/jobs/$jobId'));
    _check(res);
    return Job.fromJson(_json(res));
  }

  @override
  Future<Job> retry(String jobId) async {
    final res = await _client.post(_u('/api/v1/jobs/$jobId/retry'));
    _check(res);
    return Job.fromJson(_json(res));
  }

  @override
  Future<void> discard(String jobId) async {
    final res = await _client.post(_u('/api/v1/jobs/$jobId/discard'));
    _check(res);
  }

  @override
  String resolveImageUrl(String path) =>
      path.startsWith('http') ? path : '$baseUrl$path';

  Map<String, dynamic> _json(http.Response r) =>
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

  void _check(http.Response r) {
    if (r.statusCode >= 400) {
      throw HttpException('${r.statusCode} ${r.request?.url}');
    }
  }
}
