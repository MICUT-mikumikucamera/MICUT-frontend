import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:micut/data/jobs/api_job_repository.dart';
import 'package:micut/data/jobs/job.dart';
import 'package:micut/features/capture/capture_crop.dart';

void main() {
  Uint8List sourceBytes() {
    final source = img.Image(width: 400, height: 300);
    img.fill(source, color: img.ColorRgb8(230, 20, 20));
    img.fillRect(source,
        x1: 90, y1: 0, x2: 309, y2: 299, color: img.ColorRgb8(10, 200, 30));
    return Uint8List.fromList(img.encodePng(source));
  }

  test('upload keeps the full field while preview uses the declared crop', () {
    final draft = prepareCapture(sourceBytes(), 9 / 16);
    final original = img.decodeJpg(draft.originalBytes)!;
    final preview = img.decodeJpg(draft.previewBytes)!;
    expect([original.width, original.height], [400, 300]);
    expect(original.getPixel(0, 150).r, greaterThan(200));
    expect(preview.getPixel(0, 150).g, greaterThan(150));
    expect(draft.capture.crop!.width, preview.width);
    expect(draft.capture.crop!.height, preview.height);
    expect(draft.capture.rotation, 0);
  });

  test('all crop ratios fit the source and album defaults to the full image',
      () {
    for (final size in [(400, 300), (300, 400), (333, 333)]) {
      for (final ratio in [3 / 4, 1.0, 9 / 16]) {
        final crop = centeredCrop(size.$1, size.$2, ratio);
        expect(crop.x, greaterThanOrEqualTo(0));
        expect(crop.y, greaterThanOrEqualTo(0));
        expect(crop.x + crop.width, lessThanOrEqualTo(size.$1));
        expect(crop.y + crop.height, lessThanOrEqualTo(size.$2));
        expect(crop.width / crop.height, closeTo(ratio, .005));
      }
    }
    expect(prepareCapture(sourceBytes(), null).capture.crop!.toJson(),
        {'x': 0, 'y': 0, 'width': 400, 'height': 300});
    expect(() => centeredCrop(400, 300, 0), throwsArgumentError);
    expect(
        () => applyCaptureCrop(
            sourceBytes(), const CropRegion(x: -1, y: 0, width: 1, height: 1)),
        throwsArgumentError);
  });

  test('EXIF orientation is baked before measuring original and crop', () {
    for (final orientation in [2, 3, 4, 5, 6, 7, 8]) {
      final source = img.decodePng(sourceBytes())!;
      source.exif.imageIfd.orientation = orientation;
      final draft =
          prepareCapture(Uint8List.fromList(img.encodeJpg(source)), 1);
      final rotated = orientation >= 5;
      expect([draft.capture.w, draft.capture.h],
          rotated ? [300, 400] : [400, 300]);
      expect(draft.capture.rotation, 0);
      expect(draft.capture.crop!.width, 300);
      expect(draft.capture.crop!.height, 300);
    }
  });

  test('multipart sends full photo and explicit crop contract', () async {
    final draft = prepareCapture(sourceBytes(), 1);
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/jobs');
      final body = latin1.decode(request.bodyBytes);
      for (final field in ['photo', 'w', 'h', 'rotation', 'crop']) {
        expect(body, contains('name="$field"'));
      }
      expect(body, isNot(contains('name="capture"')));
      expect(body, contains(jsonEncode(draft.capture.crop!.toJson())));
      final start = body.indexOf('\r\n\r\n', body.indexOf('filename=')) + 4;
      final boundary = request.headers['content-type']!
          .split('boundary=')[1]
          .replaceAll('"', '');
      final end = body.indexOf('\r\n--$boundary', start);
      final uploaded = img.decodeJpg(
          Uint8List.fromList(latin1.encode(body.substring(start, end))))!;
      expect([uploaded.width, uploaded.height], [400, 300]);
      expect(uploaded.getPixel(0, 150).r, greaterThan(200));
      return http.Response(
          jsonEncode({
            'job_id': 'test',
            'photo': '/uploads/test.jpg',
            'capture': draft.capture.toJson(),
            'status': 'pending',
            'attempt': 1,
            'created_at': '2026-11-07T12:00:00+09:00',
            'updated_at': '2026-11-07T12:00:00+09:00',
          }),
          201);
    });
    final job =
        await ApiJobRepository(baseUrl: 'http://localhost', client: client)
            .createJob(draft.original, draft.capture);
    expect(job.capture.crop!.x, 50);
    client.close();
  });
}
