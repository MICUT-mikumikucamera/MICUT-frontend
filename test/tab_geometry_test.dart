import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/widgets/micut_tab_bar.dart';
import 'package:micut/core/widgets/micut_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final textScale in [1.0, 1.5]) {
    for (final bottomInset in [0.0, 24.0]) {
      testWidgets(
          'tab hit regions match at text scale $textScale with '
          '${bottomInset.toInt()}px bottom inset', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: TextScaler.linear(textScale),
                viewPadding: EdgeInsets.only(bottom: bottomInset),
              ),
              child: Scaffold(
                bottomNavigationBar: MiCutTabBar(
                  currentIndex: 0,
                  onTabSelected: (_) {},
                  onCapture: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
        expect(inkWells, hasLength(3));
        final rects = tester.widgetList<InkWell>(find.byType(InkWell)).map(
              (inkWell) => tester.getRect(find.byWidget(inkWell)),
            );
        final hitRects = rects.toList();
        expect(hitRects[0].width, closeTo(hitRects[1].width, 0.01));
        expect(hitRects[1].width, closeTo(hitRects[2].width, 0.01));
        expect(hitRects[0].height, closeTo(hitRects[1].height, 0.01));
        expect(hitRects[1].height, closeTo(hitRects[2].height, 0.01));
        expect(hitRects[0].top, hitRects[1].top);
        expect(hitRects[1].top, hitRects[2].top);

        expect(find.byType(Text), findsNothing);
        final icons = find.byType(MiCutIcon);
        expect(icons, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          final center = tester.getCenter(icons.at(i));
          expect(center.dx, closeTo(hitRects[i].center.dx, .01));
          expect(
              center.dy, closeTo(hitRects[i].center.dy - bottomInset / 2, .01));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
