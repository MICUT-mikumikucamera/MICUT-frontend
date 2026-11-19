import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/theme.dart';
import 'package:micut/core/widgets/micut_button.dart';
import 'package:micut/core/widgets/micut_tab_bar.dart';
import 'package:micut/data/local/local_store.dart';
import 'package:micut/data/collection/collection.dart';
import 'package:micut/data/collection/providers.dart';
import 'package:micut/data/local/poses.dart';
import 'package:micut/features/home/home_screen.dart';
import 'package:micut/features/capture/capture_guide_screen.dart';
import 'package:micut/features/gallery/photo_detail_screen.dart';
import 'package:micut/features/collection/card_detail_screen.dart';
import 'package:micut/features/collection/collection_screen.dart';
import 'package:micut/features/gallery/gallery_screen.dart';
import 'package:micut/features/capture/capture_view.dart';

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
  setUpAll(() async {
    final loader = FontLoader('Pretendard');
    loader.addFont(rootBundle.load('assets/fonts/Pretendard-Regular.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Figma screens fit ${width.toInt()}px and enlarged text',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 1.5]) {
        for (final entry in <String, Widget>{
          'guide': const CaptureGuideScreen(),
          'photo-detail': const PhotoDetailScreen(id: 'fixture'),
          'card-detail': const CardDetailScreen(id: 'v_sign'),
          'home': const HomeScreen(),
          'gallery': const GalleryScreen(),
          'collection': const CollectionScreen(),
          'confirmation': CaptureView(
              photoPath: null,
              message: '이 사진에 미쿠를 불러올까요?',
              onClose: () {},
              actions: Row(children: [
                Expanded(
                    child: MiCutButton(
                        label: '다시 찍기',
                        type: MiCutButtonType.secondary,
                        onPressed: () {})),
                const SizedBox(width: 8),
                Expanded(child: MiCutButton(label: '확인', onPressed: () {})),
              ])),
        }.entries) {
          final key = GlobalKey();
          await tester.pumpWidget(ProviderScope(
              overrides: [
                galleryProvider
                    .overrideWith((ref) async => entry.key.contains('detail')
                        ? [
                            GalleryItem(
                                id: 'fixture',
                                path: 'assets/figma-export/pose-locked.png',
                                createdAt: DateTime(2026, 11, 6),
                                jobId: 'job-detail',
                                cardIds: ['v_sign'])
                          ]
                        : <GalleryItem>[]),
                cardMemoProvider('v_sign').overrideWith((ref) async => ''),
                collectionProvider
                    .overrideWith((ref) async => fakeCollection(photos: const {
                          'v_sign': ['job-detail']
                        })),
              ],
              child: MaterialApp(
                  theme: buildMiCutTheme(),
                  debugShowCheckedModeBanner: false,
                  home: MediaQuery(
                      data: MediaQueryData(
                          size: Size(width, 844),
                          textScaler: TextScaler.linear(scale)),
                      child: RepaintBoundary(
                          key: key,
                          child: entry.key == 'home' || entry.key == 'gallery'
                              ? Scaffold(
                                  body: entry.value,
                                  bottomNavigationBar: MiCutTabBar(
                                      currentIndex: entry.key == 'home' ? 0 : 1,
                                      onTabSelected: (_) {},
                                      onCapture: () {}))
                              : entry.value)))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${entry.key} width=$width scale=$scale');
          if (width == 390 &&
              scale == 1 &&
              const bool.fromEnvironment('WRITE_PREVIEWS')) {
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await Directory('build/design-previews').create(recursive: true);
              await File('build/design-previews/${entry.key}.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
    });
  }
}
