import '../../core/widgets/micut_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/micut_icon_button.dart';
import '../../core/widgets/miku_illust.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';

/// Figma 08 홈 / 08-1 빈 상태.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 48px target, 24px asset, 2.25px transparent inset at the right.
            // Logo shifted 4px left from the matched visible-margin position.
            Padding(
              padding: const EdgeInsets.only(
                  left: Spacing.screenH - 4 + 12 + 2.25 - 4,
                  right: Spacing.screenH - 4),
              child: SizedBox(
                height: 51 + Spacing.pageTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(variant: BrandLogoVariant.cyan, height: 26),
                    MiCutIconButton(
                      tooltip: '설정',
                      icon: const MiCutIcon(Icons.settings_outlined),
                      onPressed: () => context.push(Routes.settings),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeatureTile(
                      label: '촬영하기',
                      description: '미쿠와 사진을 찍어보세요',
                      height: 180,
                      background:
                          'assets/figma-export/home-capture-background.png',
                      icon: Icons.photo_camera_outlined,
                      // Figma 206:7720 — x 167.5, y 4, 187px (오른쪽으로 20px 넘침)
                      illust: MikuIllust.cheer,
                      illustSize: 187,
                      illustTop: 4,
                      illustRight: -20,
                      onTap: () => context.push(Routes.captureGuide),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _FeatureTile(
                      label: '컬렉션',
                      description: '함께한 추억 보기',
                      height: 160,
                      background:
                          'assets/figma-export/home-collection-background.png',
                      icon: Icons.style_outlined,
                      // Figma 176:4762 — x 167.6, y -21, 225px (위·오른쪽으로 넘쳐 잘림)
                      illust: MikuIllust.collection,
                      illustSize: 225,
                      illustTop: -21,
                      illustRight: -57,
                      onTap: () => context.push(Routes.collection),
                    ),
                    const SizedBox(height: Spacing.screenH),
                    ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('최근 사진', style: MiCutText.h3),
                            TextButton(
                              onPressed: () => context.go(Routes.gallery),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 25),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              child: Row(children: [
                                Text('전체 보기', style: MiCutText.detail14Regular),
                                const SizedBox(width: 2),
                                const MiCutIcon.asset('arrow-right', size: 16)
                              ]),
                            ),
                          ],
                        )),
                    const SizedBox(height: Spacing.lg),
                    gallery.when(
                      loading: () => const SizedBox(
                        height: 124,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (items) => items.isEmpty
                          ? _EmptyRecent(
                              onCapture: () =>
                                  context.push(Routes.captureGuide))
                          : SizedBox(
                              height: 124,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length.clamp(0, 10),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: Spacing.s10),
                                itemBuilder: (_, i) => Semantics(
                                  button: true,
                                  label: '최근 사진 ${i + 1} 보기',
                                  child: InkWell(
                                    onTap: () => context.push(
                                        Routes.photoDetailOf(items[i].id)),
                                    child: PhotoPlaceholder(
                                      path: items[i].path,
                                      width: 124,
                                      height: 124,
                                      radius: Spacing.photoRadius,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: Spacing.xl),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(
      {required this.label,
      required this.description,
      required this.icon,
      required this.background,
      required this.height,
      required this.illust,
      required this.illustSize,
      required this.illustTop,
      required this.illustRight,
      required this.onTap});
  final String label, description, background;
  final IconData icon;
  final double height;
  final MikuIllust illust;
  final double illustSize, illustTop, illustRight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(Spacing.radius20),
        clipBehavior: Clip.antiAlias,
        child: Ink.image(
          image: AssetImage(background),
          fit: BoxFit.fill,
          child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                    top: illustTop,
                    right: illustRight,
                    child: IgnorePointer(
                        child: MikuIllustImage(illust, size: illustSize))),
                InkWell(
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.screenH),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: height - 130),
                          MiCutIcon(icon,
                              size: 30, color: MiCutColors.textInverse),
                          const SizedBox(height: Spacing.s6),
                          Text(label,
                              style: MiCutText.heading20Semibold
                                  .copyWith(color: MiCutColors.textInverse)),
                          const SizedBox(height: Spacing.s6),
                          Text(description,
                              style: MiCutText.detail14Regular
                                  .copyWith(color: MiCutColors.textInverse)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
        ),
      );
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onCapture});
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: MiCutColors.bgSubtle,
          borderRadius: BorderRadius.circular(Spacing.radius16)),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('아직 사진이 없어요', style: MiCutText.label16Semibold),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onCapture,
            style: FilledButton.styleFrom(
              backgroundColor: MiCutColors.bgInverse,
              foregroundColor: MiCutColors.textInverse,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacing.radius16)),
            ),
            child: Text('촬영하러 가기',
                style: MiCutText.label18Semibold
                    .copyWith(color: MiCutColors.textInverse)),
          ),
        ],
      ),
    );
  }
}
