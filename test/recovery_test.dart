import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/api.dart';
import 'package:micut/main.dart';
import 'package:micut/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'narrow screen failure can retry, then open gallery and confirm deletion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final model = AppModel(
        JobsApi(demoFailure: true),
        await SharedPreferences.getInstance(),
      );
      await tester.pumpWidget(MiCutApp(model: model));
      await tester.pumpAndSettle();
      model.setCapture(Capture.example());
      await tester.tap(find.text('촬영'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('만들기'));
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(find.text('처리가 오래 걸렸어요'), findsOneWidget);
      final id = model.job!.id;
      await tester.tap(find.text('재시도'));
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(model.job!.id, id);
      expect(model.job!.attempt, 2);
      await tester.tap(find.text('갤러리 보기'));
      await tester.pumpAndSettle();
      expect(find.text('갤러리'), findsOneWidget);
      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ResultImage));
      await tester.pumpAndSettle();
      expect(find.text('1장 선택'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('사진 1장을 삭제할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '삭제').last);
      await tester.pumpAndSettle();
      expect(find.text('아직 사진이 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
    },
  );
}
