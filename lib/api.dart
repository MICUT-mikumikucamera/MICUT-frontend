import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

class ApiFailure implements Exception {
  const ApiFailure(
    this.message, {
    this.code = 'NETWORK',
    this.retryable = false,
  });
  final String message, code;
  final bool retryable;
  @override
  String toString() => message;
}

class Capture {
  Capture(this.bytes, this.w, this.h, this.rotation, {this.sample = false});
  final Uint8List bytes;
  final int w, h, rotation;
  final bool sample;
  static const cameraAspectRatio = 3 / 4;

  static Capture fromCameraBytes(Uint8List bytes) =>
      _decode(bytes, cropToCamera: true);
  static Capture fromBytes(Uint8List bytes) => _decode(bytes);

  static Capture _decode(Uint8List bytes, {bool cropToCamera = false}) {
    final photo = img.decodeImage(bytes);
    if (photo == null) {
      throw const ApiFailure('이 사진 형식을 읽을 수 없어요. JPEG 또는 PNG 사진을 선택해 주세요.');
    }
    // Normalize EXIF, including mirrored orientations. w/h describe the actual
    // encoded upload before rotation; upright JPEGs therefore use rotation=0.
    var normalized = img.bakeOrientation(photo);
    if (cropToCamera) {
      // Same centered BoxFit.cover viewport as the camera. Encode the crop too,
      // so confirmation, upload and the server result use the same aspect ratio.
      final units = (normalized.width ~/ 3) < (normalized.height ~/ 4)
          ? normalized.width ~/ 3
          : normalized.height ~/ 4;
      if (units < 1) throw const ApiFailure('사진 크기가 너무 작아요. 다시 찍어 주세요.');
      final width = units * 3;
      final height = units * 4;
      normalized = img.copyCrop(
        normalized,
        x: (normalized.width - width) ~/ 2,
        y: (normalized.height - height) ~/ 2,
        width: width,
        height: height,
      );
    }
    return Capture(
      Uint8List.fromList(img.encodeJpg(normalized, quality: 95)),
      normalized.width,
      normalized.height,
      0,
    );
  }

  static Capture example() {
    final photo = img.Image(width: 600, height: 800);
    img.fill(photo, color: img.ColorRgb8(231, 231, 231));
    return Capture(
      Uint8List.fromList(img.encodeJpg(photo)),
      600,
      800,
      0,
      sample: true,
    );
  }
}

class Job {
  Job(this.json) {
    if (json['job_id'] is! String ||
        !['pending', 'processing', 'done', 'failed'].contains(json['status'])) {
      throw const ApiFailure('서버 응답을 확인할 수 없어요.', code: 'INVALID_RESPONSE');
    }
    if (status == 'done' && imagePath == null) {
      throw const ApiFailure('결과 이미지 주소가 없어요.', code: 'INVALID_RESPONSE');
    }
  }
  final Map<String, dynamic> json;
  String get id => json['job_id'] as String;
  String get status => json['status'] as String;
  bool get active => status == 'pending' || status == 'processing';
  int get attempt => (json['attempt'] as num?)?.toInt() ?? 1;
  String? get imagePath => (json['result'] as Map?)?['image_url'] as String?;
  List<String> get tags =>
      List<String>.from((json['result'] as Map?)?['tags'] ?? []);
  bool get retryable => (json['error'] as Map?)?['retryable'] == true;
  String get errorMessage =>
      (json['error'] as Map?)?['message'] as String? ??
      '사진을 만들지 못했어요. 다시 찍어 주세요.';
}

class JobsApi {
  JobsApi({this.baseUrl = '', http.Client? client, this.demoFailure = false})
    : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  final bool demoFailure;
  final Map<String, int> _polls = {}, _attempts = {};
  final Set<String> _discarded = {};
  bool get demo => baseUrl.isEmpty;
  Uri endpoint(String path) {
    final base = Uri.parse(baseUrl);
    if (!['http', 'https'].contains(base.scheme) || base.host.isEmpty) {
      throw const ApiFailure('서버 주소 설정을 확인해 주세요.');
    }
    final uri = base.resolve(path);
    if (uri.origin != base.origin) throw const ApiFailure('올바르지 않은 이미지 주소예요.');
    return uri;
  }

  Future<Job> _example(String status, String id) async {
    final json =
        jsonDecode(
              await rootBundle.loadString('assets/contracts/job_$status.json'),
            )
            as Map<String, dynamic>;
    json['job_id'] = id;
    json['attempt'] = _attempts[id] ?? 1;
    if (_discarded.contains(id) && json['error'] is Map) {
      json['error']['retryable'] = false;
    }
    return Job(json);
  }

  Future<Job> create(Capture photo) async {
    if (demo) {
      final id = 'demo_${DateTime.now().microsecondsSinceEpoch}';
      _polls[id] = 0;
      _attempts[id] = 1;
      return _example('pending', id);
    }
    final request = http.MultipartRequest('POST', endpoint('/api/v1/jobs'))
      ..fields.addAll({
        'w': '${photo.w}',
        'h': '${photo.h}',
        'rotation': '${photo.rotation}',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photo.bytes,
          filename: 'capture.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    return _request(request, expected: 201);
  }

  Future<Job> get(String id) async {
    if (demo) {
      final count = (_polls[id] ?? 0) + 1;
      _polls[id] = count;
      return _example(
        count < 3
            ? 'processing'
            : demoFailure && (_attempts[id] ?? 1) == 1
            ? 'failed'
            : 'done',
        id,
      );
    }
    return _request(
      http.Request('GET', endpoint('/api/v1/jobs/${Uri.encodeComponent(id)}')),
    );
  }

  Future<Job> retry(Job job) async {
    if (job.status != 'failed' ||
        !job.retryable ||
        _discarded.contains(job.id)) {
      throw const ApiFailure('이 사진은 재시도할 수 없어요. 다시 찍어 주세요.');
    }
    if (demo) {
      _polls[job.id] = 0;
      _attempts[job.id] = job.attempt + 1;
      return _example('pending', job.id);
    }
    return _request(
      http.Request(
        'POST',
        endpoint('/api/v1/jobs/${Uri.encodeComponent(job.id)}/retry'),
      ),
    );
  }

  Future<void> discard(Job job) async {
    if (demo) {
      _discarded.add(job.id);
      return;
    }
    await _send(
      http.Request(
        'POST',
        endpoint('/api/v1/jobs/${Uri.encodeComponent(job.id)}/discard'),
      ),
      expected: 204,
    );
  }

  Future<Job> _request(http.BaseRequest request, {int expected = 200}) async {
    final response = await _send(request, expected: expected);
    try {
      final job = Job(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
      if (job.imagePath != null) endpoint(job.imagePath!);
      return job;
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure('서버 응답 형식을 확인할 수 없어요.');
    }
  }

  Future<http.Response> _send(
    http.BaseRequest request, {
    int expected = 200,
  }) async {
    try {
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != expected) {
        Map? error;
        try {
          error =
              (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['error']
                  as Map?;
        } catch (_) {}
        throw ApiFailure(
          error?['message'] as String? ??
              '서버에 연결하지 못했어요 (${response.statusCode}). 다시 확인해 주세요.',
          code: error?['code'] as String? ?? 'HTTP_${response.statusCode}',
          retryable: error?['retryable'] == true,
        );
      }
      return response;
    } on ApiFailure {
      rethrow;
    } on TimeoutException {
      throw const ApiFailure('응답이 늦어지고 있어요. 연결 상태를 확인해 주세요.');
    } on http.ClientException {
      throw const ApiFailure('서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.');
    }
  }

  Future<Uint8List> imageBytes(String path) async =>
      (await _send(http.Request('GET', endpoint(path)))).bodyBytes;
  void close() => client.close();
}
