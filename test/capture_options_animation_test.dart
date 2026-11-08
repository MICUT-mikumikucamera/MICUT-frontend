import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/colors.dart';
import 'package:micut/core/widgets/micut_icon.dart';
import 'package:micut/features/capture/capture_option_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ratio picker fades siblings before move and opens the menu',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selected = <int>[];
    await tester.pumpWidget(_picker(selected));
    final flashKey = const ValueKey('trigger-flash');
    final ratioKey = const ValueKey('trigger-ratio');
    final flashOpacity = find.ancestor(
      of: find.byKey(flashKey),
      matching: find.byType(Opacity),
    );
    final initialRatioCenter = tester.getCenter(find.byKey(ratioKey));

    await tester.tap(find.byKey(ratioKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.widget<Opacity>(flashOpacity.first).opacity, closeTo(0, .02));
    expect(
        tester.getCenter(find.byKey(const ValueKey('moving-camera-option'))).dy,
        closeTo(initialRatioCenter.dy, 1));

    await tester.pump(const Duration(milliseconds: 182));
    final movedCenter =
        tester.getCenter(find.byKey(const ValueKey('moving-camera-option')));
    expect(movedCenter.dy, closeTo(320, 1));
    expect(
        tester
            .widget<Opacity>(find
                .ancestor(
                  of: find.byKey(const ValueKey('option-ratio-1')),
                  matching: find.byType(Opacity),
                )
                .first)
            .opacity,
        0);

    await tester.pump(const Duration(milliseconds: 148));
    expect(find.byKey(const ValueKey('option-ratio-1')), findsOneWidget);
    final selectedIcon = tester.widget<MiCutIcon>(find.descendant(
      of: find.byKey(const ValueKey('moving-camera-option')),
      matching: find.byType(MiCutIcon),
    ));
    expect(selectedIcon.color, MiCutColors.cyan200);
    final background = find.byKey(const ValueKey('capture-options-background'));
    final bounds = tester.getRect(background);
    expect(bounds.width, 40);
    expect(bounds.height, 128);
    expect(
        (tester.widget<Container>(background).decoration as BoxDecoration)
            .borderRadius,
        BorderRadius.circular(20));
    expect(bounds.center.dy, 360);
    expect(bounds.center.dx, initialRatioCenter.dx);
    expect(
        (tester.widget<Container>(background).decoration as BoxDecoration)
            .color,
        const Color(0x99000000));
    expect(find.text('1:1'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('option-ratio-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 336));
    expect(
        tester.getCenter(find.byKey(const ValueKey('moving-camera-option'))).dy,
        closeTo(initialRatioCenter.dy, 1));
    expect(tester.widget<Opacity>(flashOpacity.first).opacity, closeTo(0, .02));
    expect(selected, isEmpty);

    await tester.pumpAndSettle();
    expect(selected, [1]);
    expect(find.byKey(ratioKey), findsOneWidget);
    expect(find.byKey(const ValueKey('moving-camera-option')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'outside tap and Escape reverse the rail before restoring triggers',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_picker([]));

    await tester.tap(find.byKey(const ValueKey('trigger-ratio')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('capture-options-dismiss')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 336));
    expect(find.byKey(const ValueKey('trigger-flash')), findsOneWidget);
    final flashOpacity = find.ancestor(
      of: find.byKey(const ValueKey('trigger-flash')),
      matching: find.byType(Opacity),
    );
    expect(
        tester.widget<Opacity>(flashOpacity.first).opacity, closeTo(0, 1e-9));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trigger-ratio')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trigger-flash')), findsOneWidget);
    expect(find.byKey(const ValueKey('moving-camera-option')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back and reduced motion close the active picker',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_picker([]));

    await tester.tap(find.byKey(const ValueKey('trigger-ratio')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('moving-camera-option')), findsNothing);

    await tester.pumpWidget(_picker([], disableAnimations: true));
    await tester.tap(find.byKey(const ValueKey('trigger-ratio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('option-ratio-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture-options-dismiss')));
    await tester.pump();
    expect(find.byKey(const ValueKey('moving-camera-option')), findsNothing);
    expect(find.byKey(const ValueKey('trigger-flash')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _picker(List<int> selected, {bool disableAnimations = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 720),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: CaptureOptionsRail(groups: [
            CaptureOptionGroup(
              id: 'flash',
              tooltip: '플래시 끄기',
              selectedIndex: 0,
              enabled: true,
              options: const [
                CaptureOption(asset: 'flash-off', label: '끄기'),
                CaptureOption(asset: 'flash-on', label: '켜기'),
                CaptureOption(asset: 'flash-auto', label: '자동'),
              ],
              onSelected: selected.add,
            ),
            CaptureOptionGroup(
              id: 'timer',
              tooltip: '타이머 끄기',
              selectedIndex: 0,
              enabled: true,
              options: const [
                CaptureOption(asset: 'timer-0', label: '끄기'),
                CaptureOption(asset: 'timer-3', label: '3초'),
                CaptureOption(asset: 'timer-5', label: '5초'),
                CaptureOption(asset: 'timer-7', label: '7초'),
              ],
              onSelected: selected.add,
            ),
            CaptureOptionGroup(
              id: 'ratio',
              edgePadding: 4,
              tooltip: '사진 비율 4:3',
              selectedIndex: 0,
              enabled: true,
              options: const [
                CaptureOption(asset: 'ratio-portrait', label: '4:3'),
                CaptureOption(asset: 'ratio-square', label: '1:1'),
                CaptureOption(asset: 'ratio-tall', label: '16:9'),
              ],
              onSelected: selected.add,
            ),
          ]),
        ),
      ),
    );
