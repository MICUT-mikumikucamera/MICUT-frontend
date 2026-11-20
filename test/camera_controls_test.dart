import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:micut/core/theme/theme.dart';
import 'package:micut/features/capture/camera_screen.dart';
import 'package:micut/features/capture/capture_guide_screen.dart';
import 'package:micut/features/capture/capture_crop.dart';

const back = CameraDescription(
    name: 'back',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90);
const front = CameraDescription(
    name: 'front',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 90);

class TestCamera extends CameraController {
  TestCamera(CameraDescription description, {this.supportsFlash = true})
      : super(description, ResolutionPreset.high);
  final bool supportsFlash;
  final flashes = <FlashMode>[];
  bool wasDisposed = false;
  int photos = 0;
  @override
  Future<void> initialize() async {
    value =
        value.copyWith(isInitialized: true, previewSize: const Size(640, 480));
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    if (!supportsFlash) throw CameraException('unsupported', 'No flash');
    flashes.add(mode);
    value = value.copyWith(flashMode: mode);
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Colors.blueGrey);
  @override
  Future<XFile> takePicture() async {
    photos++;
    return XFile.fromData(
        Uint8List.fromList(img.encodeJpg(img.Image(width: 640, height: 480))));
  }

  @override
  Future<void> dispose() async {
    wasDisposed = true;
    await super.dispose();
  }
}

void main() {
  test('capture crops the center to each selected portrait ratio', () {
    final source = img.Image(width: 400, height: 300);
    img.fill(source, color: img.ColorRgb8(240, 20, 20));
    img.fillRect(source,
        x1: 100, y1: 0, x2: 299, y2: 299, color: img.ColorRgb8(10, 200, 30));
    final bytes = Uint8List.fromList(img.encodePng(source));
    for (final ratio in CaptureRatio.values) {
      final result = img.decodeJpg(cropCameraJpeg(bytes, ratio.value))!;
      expect(result.width / result.height, closeTo(ratio.value, .004));
      final center = result.getPixel(result.width ~/ 2, result.height ~/ 2);
      expect(center.g, greaterThan(center.r));
    }
    expect(img.decodePng(bytes)!.width, 400); // Original input remains intact.
  });

  test('unsupported image bytes fail before navigation/upload', () {
    expect(() => cropCameraJpeg(Uint8List.fromList([1, 2, 3]), 3 / 4),
        throwsFormatException);
  });

  testWidgets(
      'ratio timer flash and lens controls retain behavior across switches',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controllers = <TestCamera>[];
    await tester.pumpWidget(MaterialApp(
        theme: buildMiCutTheme(),
        home: CameraScreen(
          cameraLoader: () async => [back, front],
          controllerFactory: (description) {
            final camera =
                TestCamera(description, supportsFlash: description == back);
            controllers.add(camera);
            return camera;
          },
        )));
    await tester.pumpAndSettle();
    expect(find.byTooltip('사진 비율 4:3'), findsOneWidget);
    await tester.tap(find.byTooltip('사진 비율 4:3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-ratio-1')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('사진 비율 1:1'), findsOneWidget);
    await tester.tap(find.byTooltip('사진 비율 1:1'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('사진 비율 1:1'), findsOneWidget);
    expect(find.text('16:9'), findsNothing);

    await tester.tap(find.byTooltip('타이머 끄기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-timer-1')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('타이머 3초'), findsOneWidget);
    await tester.tap(find.byTooltip('타이머 3초'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-timer-3')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('타이머 7초'), findsOneWidget);

    await tester.tap(find.byTooltip('플래시 끄기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-flash-2')));
    await tester.pumpAndSettle();
    expect(controllers.first.flashes, [FlashMode.off, FlashMode.auto]);
    await tester.tap(find.byTooltip('플래시 자동'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('option-flash-1')));
    await tester.pumpAndSettle();
    expect(controllers.first.flashes.last, FlashMode.always);

    await tester.tap(find.byTooltip('전후면 카메라 전환'));
    await tester.pumpAndSettle();
    expect(controllers.first.wasDisposed, isTrue);
    expect(controllers.last.description, front);
    expect(find.byTooltip('사진 비율 1:1'), findsOneWidget);
    expect(find.byTooltip('타이머 7초'), findsOneWidget);
    final unsupported = tester.widget<IconButton>(find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '플래시 끄기'));
    expect(unsupported.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(controllers.last.wasDisposed, isTrue);
  });

  testWidgets(
      'camera unavailable retains controls and disables hardware actions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMiCutTheme(),
        home: CameraScreen(cameraLoader: () async => [])));
    await tester.pumpAndSettle();
    expect(find.byTooltip('사진 비율 4:3'), findsOneWidget);
    expect(find.byTooltip('플래시 끄기'), findsOneWidget);
    expect(find.byTooltip('타이머 끄기'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == '전후면 카메라 전환'))
            .onPressed,
        isNull);
    expect(find.text('다시 시도'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('guide contains the original confirmation without a close button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildMiCutTheme(), home: const CaptureGuideScreen()));
    expect(find.byTooltip('닫기'), findsNothing);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('permission denial offers real native application settings',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call.method);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
        theme: buildMiCutTheme(),
        home: CameraScreen(cameraLoader: () async {
          throw CameraException('CameraAccessDenied', 'Denied');
        })));
    await tester.pumpAndSettle();
    expect(find.text('권한 확인'), findsOneWidget);
    expect(find.text('카메라 권한을 확인해 주세요. 확인 클릭시 설정 화면으로 이동합니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(calls, ['openAppSettings']);
    expect(find.text('권한 확인'), findsNothing);
  });
}
