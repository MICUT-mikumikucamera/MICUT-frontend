import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/api.dart';
import 'package:micut/main.dart';
import 'package:micut/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'home, empty gallery, collection and sample capture at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final model = AppModel(JobsApi(), await SharedPreferences.getInstance());
      await tester.pumpWidget(MiCutApp(model: model));
      await tester.pumpAndSettle();
      expect(find.text('MiCut'), findsOneWidget);
      await tester.tap(find.text('갤러리'));
      await tester.pumpAndSettle();
      expect(find.text('아직 사진이 없어요'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('컬렉션').last);
      await tester.pumpAndSettle();
      expect(find.text('브이'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      model.setCapture(Capture.example());
      await tester.tap(find.text('촬영'));
      await tester.pumpAndSettle();
      expect(find.text('이 사진에 미쿠를 불러올까요?'), findsOneWidget);
      await tester.tap(find.text('만들기'));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(find.text('결과 이미지'), findsOneWidget);
      expect(model.photos.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
    },
  );
}
