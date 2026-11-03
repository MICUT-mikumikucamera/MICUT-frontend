import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:micut/api.dart';
import 'package:micut/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<Map<String, dynamic>> fixture(String state) async => jsonDecode(
    await rootBundle.loadString('assets/contracts/job_$state.json'),
  );
  test(
    'backend fixtures parse all four states and retry eligibility',
    () async {
      for (final state in ['pending', 'processing', 'done', 'failed']) {
        final job = Job(await fixture(state));
        expect(job.status, state);
        expect(job.active, ['pending', 'processing'].contains(state));
        expect(job.retryable, state == 'failed');
      }
    },
  );
  test(
    'upload uses multipart JPEG and dimensions of the actual encoded file',
    () async {
      final api = JobsApi(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/jobs');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          final body = latin1.decode(request.bodyBytes);
          expect(body, contains('name="w"\r\n\r\n600'));
          expect(body, contains('name="h"\r\n\r\n800'));
          expect(body, contains('name="rotation"\r\n\r\n0'));
          expect(body, contains('name="photo"; filename="capture.jpg"'));
          expect(body, contains('content-type: image/jpeg'));
          expect(body, isNot(contains('name="fx"')));
          return http.Response(
            jsonEncode(await fixture('pending')),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      expect((await api.create(Capture.example())).status, 'pending');
      api.close();
    },
  );
  test('EXIF rotation is normalized and upload dimensions match file', () {
    final image = img.Image(width: 20, height: 30);
    image.exif.imageIfd.orientation = 6;
    final capture = Capture.fromBytes(Uint8List.fromList(img.encodeJpg(image)));
    final encoded = img.decodeJpg(capture.bytes)!;
    expect(capture.w, 30);
    expect(capture.h, 20);
    expect(encoded.width, capture.w);
    expect(encoded.height, capture.h);
    expect(capture.rotation, 0);
  });
  test(
    'failed HTTP 200 is a domain failure; discard 204 has no JSON body',
    () async {
      final requests = <String>[];
      final api = JobsApi(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/discard')) {
            return http.Response('', 204);
          }
          return http.Response(
            jsonEncode(await fixture('failed')),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final job = await api.get('opaque id');
      expect(job.status, 'failed');
      await api.discard(job);
      expect(requests.last, endsWith('/discard'));
      api.close();
    },
  );
  test('structured non-2xx errors retain message and eligibility', () async {
    final api = JobsApi(
      baseUrl: 'https://api.example.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'UPLOAD_TOO_LARGE',
              'message': '사진 용량이 너무 커요',
              'retryable': false,
            },
          }),
          413,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await expectLater(
      api.create(Capture.example()),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.code, 'code', 'UPLOAD_TOO_LARGE')
            .having((e) => e.retryable, 'retryable', false),
      ),
    );
    api.close();
  });
  test(
    'same job retry increments attempt; discarded job cannot retry',
    () async {
      final api = JobsApi(demoFailure: true);
      final pending = await api.create(Capture.example());
      await api.get(pending.id);
      await api.get(pending.id);
      final failed = await api.get(pending.id);
      final retried = await api.retry(failed);
      expect(retried.id, failed.id);
      expect(retried.attempt, 2);
      await api.discard(failed);
      await expectLater(api.retry(failed), throwsA(isA<ApiFailure>()));
      api.close();
    },
  );
  test(
    'gallery and active job survive restart; failed discard keeps recovery',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final model = AppModel(
        JobsApi(),
        prefs,
        pollInterval: const Duration(days: 1),
      );
      model.setCapture(Capture.example());
      await model.create();
      await model.refresh();
      await model.refresh();
      await model.refresh();
      expect(model.photos.length, 1);
      final restored = AppModel(
        JobsApi(),
        prefs,
        pollInterval: const Duration(days: 1),
      );
      await restored.initialize();
      expect(restored.photos.single.id, model.job!.id);
      await restored.deletePhotos({restored.photos.single.id});
      expect(restored.photos, isEmpty);
      model.dispose();
      restored.dispose();
    },
  );
  test('poll requests are serialized and failures preserve the job', () async {
    SharedPreferences.setMockInitialValues({});
    var gets = 0;
    final api = JobsApi(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode(await fixture('pending')),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        gets++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw http.ClientException('offline');
      }),
    );
    final model = AppModel(
      api,
      await SharedPreferences.getInstance(),
      pollInterval: const Duration(days: 1),
    );
    model.setCapture(Capture.example());
    await model.create();
    await Future.wait([model.refresh(), model.refresh()]);
    expect(gets, 1);
    expect(model.job!.status, 'pending');
    expect(model.error, isNotNull);
    model.dispose();
  });
}
