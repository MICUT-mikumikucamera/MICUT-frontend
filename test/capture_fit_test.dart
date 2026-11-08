import 'dart:convert';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/features/capture/capture_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in [const Size(320, 640), const Size(1200, 700)]) {
    for (final source in [
      const Size(300, 500),
      const Size(500, 300),
      const Size(400, 400),
    ]) {
      testWidgets(
          'contains ${source.width.toInt()}x${source.height.toInt()} photo '
          'in ${viewport.width.toInt()}x${viewport.height.toInt()} viewport',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final sourceImage = img.Image(
            width: source.width.toInt(), height: source.height.toInt());
        final path =
            'data:image/png;base64,${base64Encode(img.encodePng(sourceImage))}';

        await tester.pumpWidget(MaterialApp(
          home: CaptureView(
            photoPath: path,
            message: '촬영 확인',
            onClose: () {},
            actions: const SizedBox(height: 50),
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final photo = tester.widget<Image>(find
            .byWidgetPredicate((w) => w is Image && w.image is MemoryImage));
        expect(photo.fit, BoxFit.contain);
      });
    }
  }
}
