import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:micut/api.dart';
import 'package:micut/main.dart';
import 'package:micut/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('camera crop is centered, 3:4, and encoded dimensions match upload', () {
    for (final size in [(160, 90), (90, 160), (120, 120), (120, 160)]) {
      final source = img.Image(width: size.$1, height: size.$2);
      img.fill(source, color: img.ColorRgb8(255, 0, 0));
      img.fillRect(
        source,
        x1: size.$1 ~/ 2 - 8,
        y1: size.$2 ~/ 2 - 8,
        x2: size.$1 ~/ 2 + 8,
        y2: size.$2 ~/ 2 + 8,
        color: img.ColorRgb8(0, 255, 0),
      );
      final capture = Capture.fromCameraBytes(img.encodePng(source));
      final encoded = img.decodeJpg(capture.bytes)!;
      expect(capture.w / capture.h, Capture.cameraAspectRatio);
      expect(encoded.width, capture.w);
      expect(encoded.height, capture.h);
      expect(capture.rotation, 0);
      expect(
        encoded.getPixel(capture.w ~/ 2, capture.h ~/ 2).g,
        greaterThan(200),
      );
    }
  });
  test(
    'camera cropping follows EXIF correction; album keeps original aspect',
    () {
      final source = img.Image(width: 160, height: 90);
      source.exif.imageIfd.orientation = 6;
      final bytes = img.encodeJpg(source);
      final capture = Capture.fromCameraBytes(bytes);
      expect(capture.w, 90);
      expect(capture.h, 120);
      final album = Capture.fromBytes(bytes);
      expect(album.w, 90);
      expect(album.h, 160);
    },
  );
  testWidgets('confirmation keeps 3:4; Android system back returns to home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final model = AppModel(JobsApi(), await SharedPreferences.getInstance());
    model.setCapture(Capture.example());
    await tester.pumpWidget(MiCutApp(model: model));
    await tester.tap(find.text('촬영'));
    await tester.pumpAndSettle();
    final frame = find.descendant(
      of: find.byType(WorkflowScreen),
      matching: find.byType(AspectRatio),
    );
    expect(frame, findsOneWidget);
    final size = tester.getSize(frame);
    expect(size.width / size.height, closeTo(3 / 4, .0001));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WorkflowScreen), findsNothing);
    expect(find.text('MiCut'), findsOneWidget);
    expect(model.capture, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
}
