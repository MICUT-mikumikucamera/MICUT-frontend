import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/hud_frame.dart';
import '../../core/widgets/micut_button.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';
import '../../data/local/poses.dart';

/// Figma 08 홈 / 08-1 홈 빈 상태
///
/// 라이트 월드. 히어로(촬영하기)는 민트 그라데이션 + 뷰파인더 코너,
/// 컬렉션 타일은 Secondary(핑크) 면으로 "시각적 변화".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);
    final collected = ref.watch(collectedCardIdsProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
          children: [
            const SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrandLogo(variant: BrandLogoVariant.black, height: 22),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: MiCutColors.textSecondary,
                  onPressed: () => context.push(Routes.settings),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            _HeroTile(onTap: () => context.push(Routes.captureGuide)),
            const SizedBox(height: Spacing.md),

            _CollectionTile(
              collected: collected?.length ?? 0,
              total: kPoses.length,
              onTap: () => context.push(Routes.collection),
            ),
            const SizedBox(height: Spacing.xxl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('최근 사진', style: MiCutText.h3),
                if (gallery.valueOrNull?.isNotEmpty ?? false)
                  TextButton(
                    onPressed: () => context.go(Routes.gallery),
                    child: const Text('전체 보기 ›'),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            gallery.when(
              loading: () => const SizedBox(
                height: 124,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('불러오지 못했어요', style: MiCutText.caption),
              data: (items) => items.isEmpty
                  ? _EmptyRecent(onCapture: () => context.push(Routes.captureGuide))
                  : SizedBox(
                      height: 124,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length.clamp(0, 10),
                        separatorBuilder: (_, __) => const SizedBox(width: Spacing.md),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => context.push(Routes.photoDetailOf(items[i].id)),
                          child: PhotoPlaceholder(
                            path: items[i].path,
                            width: 124,
                            height: 124,
                            radius: Spacing.radiusMd,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}

/// 타일/촬영하기 — 앱의 주 행동. 민트 그라데이션 위에 ink 글자(대비 ≥ 5.9).
class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.radiusXl),
        boxShadow: MiCutShadows.glowCyan,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Spacing.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 210,
          decoration: const BoxDecoration(gradient: MiCutGradients.mint),
          child: InkWell(
            onTap: onTap,
            child: HudCorners(
            color: MiCutColors.cyan500.withValues(alpha: 0.55),
            inset: Spacing.lg,
            length: 18,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: MiCutColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_camera_rounded,
                            color: MiCutColors.brandCyan),
                      ),
                      Text('REC', style: MiCutText.hud.copyWith(color: MiCutColors.cyan500)),
                    ],
                  ),
                  const Spacer(),
                  Text('촬영하기', style: MiCutText.h1.copyWith(color: MiCutColors.ink)),
                  const SizedBox(height: Spacing.xs),
                  Text('미쿠의 사진을 찍어보세요',
                      style: MiCutText.caption.copyWith(color: MiCutColors.cyan500)),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// 타일/컬렉션 — 전체 너비. 핑크 면 + 진행 바.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collected,
    required this.total,
    required this.onTap,
  });
  final int collected;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : collected / total;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Spacing.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: 112,
        decoration: const BoxDecoration(gradient: MiCutGradients.blush),
        child: InkWell(
          onTap: onTap,
          child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: MiCutColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.style_rounded, color: MiCutColors.secondary),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('컬렉션', style: MiCutText.h3),
                        Text('$collected/$total',
                            style: MiCutText.bodyBold.copyWith(color: MiCutColors.pink500)),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: MiCutColors.white,
                        color: MiCutColors.secondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text('포즈 수집하기', style: MiCutText.label),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              const Icon(Icons.chevron_right, color: MiCutColors.pink500),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onCapture});
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: MiCutColors.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(color: MiCutColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('아직 사진이 없어요', style: MiCutText.bodyBold),
          const SizedBox(height: Spacing.md),
          MiCutButton(
            label: '사진 촬영하러 가기',
            expand: false,
            onPressed: onCapture,
          ),
        ],
      ),
    );
  }
}
