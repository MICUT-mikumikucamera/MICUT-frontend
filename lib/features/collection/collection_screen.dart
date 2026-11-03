import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/pose_card.dart';
import '../../data/local/local_store.dart';
import '../../data/local/poses.dart';

/// Figma 11 컬렉션 (홈 타일에서 진입하는 하위 화면)
///
/// Secondary(핑크)가 주인공인 유일한 화면. 상단 요약 띠 + 카드 그리드.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collected = ref.watch(collectedCardIdsProvider).valueOrNull ?? {};
    final gallery = ref.watch(galleryProvider).valueOrNull ?? const [];

    String? thumbFor(String poseId) =>
        gallery.where((g) => g.cardIds.contains(poseId)).firstOrNull?.path;

    return Scaffold(
      appBar: AppBar(title: const Text('컬렉션')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Spacing.screenH, Spacing.sm, Spacing.screenH, Spacing.lg),
            sliver: SliverToBoxAdapter(
              child: _Summary(collected: collected.length, total: kPoses.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Spacing.screenH, 0, Spacing.screenH, Spacing.xxl),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Spacing.md,
                crossAxisSpacing: Spacing.md,
                childAspectRatio: 157 / 215,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final pose = kPoses[i];
                  final has = collected.contains(pose.id);
                  return PoseCard(
                    number: pose.number,
                    name: pose.name,
                    collected: has,
                    imagePath: thumbFor(pose.id),
                    onTap: has ? () => context.push(Routes.cardDetailOf(pose.id)) : null,
                  );
                },
                childCount: kPoses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.collected, required this.total});
  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : collected / total;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: MiCutGradients.blush,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('포즈 수집', style: MiCutText.caption.copyWith(color: MiCutColors.pink500)),
                const SizedBox(height: Spacing.xs),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$collected', style: MiCutText.display.copyWith(color: MiCutColors.pink500)),
                    TextSpan(text: ' / $total', style: MiCutText.h3.copyWith(color: MiCutColors.textSecondary)),
                  ]),
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
              ],
            ),
          ),
          const SizedBox(width: Spacing.lg),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: MiCutColors.white, shape: BoxShape.circle),
            child: const Icon(Icons.style_rounded, color: MiCutColors.secondary, size: 28),
          ),
        ],
      ),
    );
  }
}
