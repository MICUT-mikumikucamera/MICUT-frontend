import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'job.dart';
import 'job_repository.dart';

/// 실제 서버 구현. 엔드포인트는 백엔드 명세 v0 기준 추정이며,
/// 백엔드가 확정되면 경로/필드명을 여기서만 고친다.
///
/// 가정한 엔드포인트:
///   POST   /api/v1/jobs                  multipart(photo) + capture(json)  → Job
///   GET    /api/v1/jobs/{job_id}                                           → Job
///   POST   /api/v1/jobs/{job_id}/retry                                     → Job
///   POST   /api/v1/jobs/{job_id}/discard                                   → 204
class ApiJobRepository extends JobRepository {
  ApiJobRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<Job> createJob(File photo, CaptureInfo capture) async {
    final req = http.MultipartRequest('POST', _u('/api/v1/jobs'))
      ..files.add(await http.MultipartFile.fromPath('photo', photo.path))
      ..fields['capture'] = jsonEncode(capture.toJson());
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
