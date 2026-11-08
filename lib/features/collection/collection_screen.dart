import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
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

/// Figma 11: 어두운 컬렉션 배경과 흰 폴라로이드 카드.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collected = ref.watch(collectedCardIdsProvider);
    final gallery = ref.watch(galleryProvider);
    final ids = collected.valueOrNull ?? {};
    final items = gallery.valueOrNull ?? const [];
    final ratio = kPoses.isEmpty ? 0.0 : ids.length / kPoses.length;
    return Scaffold(
      backgroundColor: MiCutColors.bgInverse,
      appBar: AppBar(
        leading: const MiCutBackButton(),
        leadingWidth: 64,
        title: const Text('컬렉션'),
        actions: [
          IconButton(
            tooltip: '스토리 보기',
            icon: const MiCutIcon(Icons.view_carousel_outlined),
            onPressed: kPoses.where((pose) => ids.contains(pose.id)).isEmpty
                ? null
                : () => context.push(Routes.cardStoryOf(
                    kPoses.firstWhere((pose) => ids.contains(pose.id)).id)),
          )
        ],
        backgroundColor: MiCutColors.bgInverse,
        foregroundColor: MiCutColors.textInverse,
        titleTextStyle: MiCutText.heading20Semibold
            .copyWith(color: MiCutColors.textInverse),
      ),
      body: collected.isLoading || gallery.isLoading
          ? const Center(child: CircularProgressIndicator())
          : collected.hasError || gallery.hasError
              ? const SizedBox.shrink()
              : DecoratedBox(
                  decoration:
                      const BoxDecoration(gradient: MiCutGradients.collection),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            Spacing.screenH,
                            Spacing.pageTop,
                            Spacing.screenH,
                            Spacing.collectionProgressBottom),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '진행도 (${ids.length.toString().padLeft(2, '0')}/${kPoses.length.toString().padLeft(2, '0')})',
                                  style: MiCutText.label16Regular.copyWith(
                                      color: MiCutColors.textInverse)),
                              const SizedBox(height: Spacing.sm),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(Spacing.radiusSm),
                                child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: MiCutColors.bgPlaceholder,
                                    color: MiCutColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            Spacing.screenH, 0, Spacing.screenH, Spacing.xxl),
                        sliver: SliverLayoutBuilder(
                            builder: (context, constraints) => SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              ((constraints.crossAxisExtent +
                                                          15) /
                                                      (200 + 15))
                                                  .ceil(),
                                          mainAxisSpacing: 21.46,
                                          crossAxisSpacing: 15,
                                          childAspectRatio: 160 / 207),
                                  delegate: SliverChildBuilderDelegate((_, i) {
                                    final pose = kPoses[i];
                                    final has = ids.contains(pose.id);
                                    return Transform.rotate(
                                        angle: (i % 4 == 0 || i % 4 == 3
                                                ? -2
                                                : 2) *
                                            3.141592653589793 /
                                            180,
                                        child: PoseCard(
                                            number: pose.number,
                                            name: pose.name,
                                            collected: has,
                                            imagePath: items
                                                .where((g) =>
                                                    g.cardIds.contains(pose.id))
                                                .firstOrNull
                                                ?.path,
                                            onTap: has
                                                ? () => context.push(
                                                    Routes.cardDetailOf(
                                                        pose.id))
                                                : null));
                                  }, childCount: kPoses.length),
                                )),
                      ),
                    ],
                  )),
    );
  }
}
