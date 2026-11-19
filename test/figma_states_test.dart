import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/theme.dart';
import 'package:micut/core/theme/colors.dart';
import 'package:micut/core/widgets/micut_button.dart';
import 'package:micut/core/widgets/micut_dialog.dart';
import 'package:micut/core/widgets/micut_icon.dart';
import 'package:micut/core/widgets/photo_placeholder.dart';
import 'package:micut/core/widgets/micut_tab_bar.dart';
import 'package:micut/core/widgets/new_collection_overlay.dart';
import 'package:micut/data/local/local_store.dart';
import 'package:micut/data/collection/collection.dart';
import 'package:micut/data/collection/providers.dart';
import 'package:micut/data/local/poses.dart';
import 'package:micut/features/capture/camera_screen.dart';
import 'package:micut/features/capture/capture_guide_screen.dart';
import 'package:micut/features/capture/capture_view.dart';
import 'package:micut/features/collection/card_detail_screen.dart';
import 'package:micut/features/collection/collection_screen.dart';
import 'package:micut/features/gallery/gallery_screen.dart';
import 'package:micut/features/gallery/photo_detail_screen.dart';
import 'package:micut/features/home/home_screen.dart';
import 'package:micut/features/settings/settings_screen.dart';
import 'camera_controls_test.dart' show TestCamera, back, front;

class ReferenceCamera extends TestCamera {
  ReferenceCamera(super.description, this.photo);
  final Uint8List photo;
  @override
  Widget buildPreview() => Image.memory(photo, fit: BoxFit.cover);
}

/// 서버 컬렉션 응답 대역. 실제 호출 없이 화면만 그린다.
CollectionSummary fakeCollection({
  Map<String, List<String>> photos = const {},
}) =>
    CollectionSummary(
      acquiredCount: photos.keys.where((id) => photos[id]!.isNotEmpty).length,
      total: kPoses.length,
      cards: [
        for (final pose in kPoses)
          CollectionCard(
            id: pose.id,
            no: pose.no,
            name: pose.name,
            photos: [
              for (final jobId in photos[pose.id] ?? const <String>[])
                CardPhoto(jobId: jobId, acquiredAt: DateTime(2026, 11, 6)),
            ],
          ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String capture, result;
  late Uint8List captureBytes;
  setUpAll(() async {
    captureBytes = await File('test/fixtures/capture.png').readAsBytes();
    capture = Uri.dataFromBytes(captureBytes, mimeType: 'image/png').toString();
    result = Uri.dataFromBytes(
            await File('test/fixtures/result.png').readAsBytes(),
            mimeType: 'image/png')
        .toString();
    final fonts = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final display = FontLoader('DungGeunMo')
      ..addFont(rootBundle.load('assets/fonts/DungGeunMo.ttf'));
    await display.load();
  });
  testWidgets('all Figma states render at source size and keep source geometry',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: 57, bottom: 24);
    addTearDown(tester.view.reset);
    final photos = List.generate(
        10,
        (i) => GalleryItem(
            id: '$i',
            path: result,
            createdAt: DateTime(2026, 11, 6),
            jobId: 'job-$i',
            cardIds: ['v_sign']));
    Widget flow(String message,
            {bool busy = false,
            bool saved = false,
            bool single = false,
            bool done = false}) =>
        CaptureView(
            topActions: done
                ? [
                    IconButton(
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        alignment: Alignment.topCenter,
                        icon:
                            const MiCutIcon(Icons.ios_share_outlined, size: 28))
                  ]
                : [],
            photoPath: done ? result : capture,
            message: message,
            onClose: () {},
            processing: busy,
            actionNotice: saved ? '사진첩에 저장했어요' : null,
            actions: single
                ? SizedBox(
                    width: 160,
                    child: MiCutButton(
                        label: busy ? '취소' : '재시도',
                        type: MiCutButtonType.secondary,
                        onPressed: () {}))
                : Row(children: [
                    Expanded(
                        child: MiCutButton(
                            label: '다시 찍기',
                            type: MiCutButtonType.secondary,
                            onPressed: () {})),
                    const SizedBox(width: 12),
                    Expanded(
                        child: MiCutButton(
                            label: done
                                ? saved
                                    ? '갤러리 보기'
                                    : '저장'
                                : '확인',
                            onPressed: () {})),
                  ]));
    final states = <String, Widget>{
      '12-guide': const CaptureGuideScreen(),
      '13-camera': CameraScreen(
          cameraLoader: () async => [back, front],
          controllerFactory: (d) => ReferenceCamera(d, captureBytes)),
      '14-permission': CameraScreen(
          cameraLoader: () async =>
              throw CameraException('CameraAccessDenied', 'Denied')),
      '15-confirmation': flow('이 사진에 미쿠를 불러올까요?'),
      '16-processing': flow('미쿠 사진을 만드는 중...', busy: true, single: true),
      '17-failure': flow('처리에 실패했어요. 다시 시도해 주세요.', single: true),
      '18-network': flow('네트워크 연결을 확인해 주세요.', single: true),
      '19-result': flow('생성 완료!', done: true),
      '20-new-collection': flow('생성 완료!', done: true),
      '21-saved': flow('생성 완료!', done: true, saved: true),
      '22-unsaved': flow('생성 완료!', done: true),
      '34-home': const HomeScreen(),
      '35-home-empty': const HomeScreen(),
      '36-gallery': const GalleryScreen(),
      '37-gallery-empty': const GalleryScreen(),
      '38-gallery-edit': const GalleryScreen(),
      '39-gallery-delete': const GalleryScreen(),
      '40-photo-detail': const PhotoDetailScreen(id: '0'),
      '41-collection': const CollectionScreen(),
      '42-card-detail': const CardDetailScreen(id: 'v_sign'),
      '43-story': const CardDetailScreen(id: 'v_sign', story: true),
      '44-settings': const SettingsScreen(),
    };
    for (final entry in states.entries) {
      final navigator = GlobalKey<NavigatorState>();
      final repaint = GlobalKey();
      final tabbed =
          entry.key.contains('home') || entry.key.contains('gallery');
      Widget home = entry.value;
      if (tabbed) {
        home = Consumer(
            builder: (context, ref, _) => Scaffold(
                body: entry.value,
                bottomNavigationBar: ref.watch(galleryEditingProvider)
                    ? null
                    : MiCutTabBar(
                        currentIndex: entry.key.contains('home') ? 0 : 1,
                        onTabSelected: (_) {},
                        onCapture: () {})));
      }
      await tester.pumpWidget(ProviderScope(
          overrides: [
            galleryProvider.overrideWith(
                (ref) async => entry.key.contains('empty') ? [] : photos),
            collectionProvider
                .overrideWith((ref) async => fakeCollection(photos: {
                      'v_sign': [for (var i = 0; i < 10; i++) 'job-$i']
                    })),
            cardMemoProvider('v_sign').overrideWith((ref) async => ''),
          ],
          child: MaterialApp(
              theme: buildMiCutTheme(),
              navigatorKey: navigator,
              debugShowCheckedModeBanner: false,
              builder: (_, child) =>
                  RepaintBoundary(key: repaint, child: child!),
              home: home)));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.runAsync(() async {
        final context = navigator.currentContext!;
        await precacheImage(MemoryImage(captureBytes), context);
        await precacheImage(
            MemoryImage(Uri.parse(result).data!.contentAsBytes()), context);
        for (final file
            in Directory('assets/figma-export').listSync().whereType<File>()) {
          if (file.path.endsWith('.png')) {
            await precacheImage(
                AssetImage(file.path.replaceAll('\\', '/')), context);
          }
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      if (entry.key.contains('gallery-edit') ||
          entry.key.contains('gallery-delete')) {
        await tester.tap(find.text('편집'));
        await tester.pumpAndSettle();

        await tester.tap(find
            .ancestor(
                of: find.byType(PhotoPlaceholder).at(0),
                matching: find.byType(GestureDetector))
            .first);
        await tester.pump();
        await tester.tap(find
            .ancestor(
                of: find.byType(PhotoPlaceholder).at(3),
                matching: find.byType(GestureDetector))
            .first);
        await tester.pump();
      }
      if (entry.key == '39-gallery-delete' || entry.key == '22-unsaved') {
        final deletion = entry.key.startsWith('39');
        showDialog<void>(
            context: navigator.currentContext!,
            barrierColor: MiCutColors.modalDim,
            useSafeArea: false,
            builder: (ctx) => MiCutDialog(
                padding: deletion ? 25 : 21,
                title: deletion ? '사진 2장을 삭제할까요?' : '저장하지 않고 나갈까요?',
                message: deletion
                    ? '사진첩에 저장하지 않은 이미지는 사라져요'
                    : '사진을 저장하지 않으면 갤러리에 남지 않아요.',
                confirmLabel: deletion ? '삭제' : '확인',
                danger: true,
                onConfirm: () => Navigator.pop(ctx)));
        await tester.pumpAndSettle();
      }
      if (entry.key == '20-new-collection') {
        showDialog<void>(
            context: navigator.currentContext!,
            barrierColor: MiCutColors.modalDim,
            useSafeArea: false,
            builder: (ctx) => NewCollectionOverlay(
                number: 1,
                name: '브이',
                imagePath: result,
                onClose: () => Navigator.pop(ctx)));
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: entry.key);
      if (entry.key == '15-confirmation') {
        final rect = tester.getRect(find.byType(PhotoPlaceholder));
        expect(rect.left, 0);
        expect(rect.top, 100);
        expect(rect.width, 375);
        expect(rect.height, closeTo(540, 1));
      }
      if (entry.key == '36-gallery') {
        final rect = tester.getRect(find.byType(PhotoPlaceholder).first);
        expect(rect.left, 24);
        expect(rect.top, 126);
        expect(rect.width, 157);
        expect(rect.height, 200);
      }
      if (const bool.fromEnvironment('WRITE_PREVIEWS')) {
        await tester.runAsync(() async {
          final boundary = repaint.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/figma-audit').create(recursive: true);
          await File('build/figma-audit/${entry.key}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });
}
