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
import '../../data/collection/providers.dart';
import '../../data/local/local_store.dart';

/// Figma 11: 어두운 컬렉션 배경과 흰 폴라로이드 카드.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);
    final gallery = ref.watch(galleryProvider);
    final summary = collection.valueOrNull;
    final cards = summary?.cards ?? const [];
    final items = gallery.valueOrNull ?? const <GalleryItem>[];
    final acquired = summary?.acquiredCount ?? 0;
    final total = summary?.total ?? cards.length;
    final ratio = total == 0 ? 0.0 : acquired / total;

    /// 서버는 이미지 주소를 주지 않는다. 카드가 얻은 사진의 job_id 로
    /// 기기에 저장된 결과 사진을 찾는다. 못 찾으면 자리 표시만 보여준다.
    String? thumbnail(String cardId) {
      final card = summary?.card(cardId);
      if (card == null || card.photos.isEmpty) return null;
      final jobIds = {for (final photo in card.photos) photo.jobId};
      return items
          .where((g) => g.jobId != null && jobIds.contains(g.jobId))
          .firstOrNull
          ?.path;
    }

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
            onPressed: cards.where((card) => card.acquired).isEmpty
                ? null
                : () => context.push(Routes.cardStoryOf(
                    cards.firstWhere((card) => card.acquired).id)),
          )
        ],
        backgroundColor: MiCutColors.bgInverse,
        foregroundColor: MiCutColors.textInverse,
        titleTextStyle: MiCutText.heading20Semibold
            .copyWith(color: MiCutColors.textInverse),
      ),
      body: collection.isLoading || gallery.isLoading
          ? const Center(child: CircularProgressIndicator())
          : collection.hasError || gallery.hasError
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
                                  '진행도 (${acquired.toString().padLeft(2, '0')}/${total.toString().padLeft(2, '0')})',
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
                                    final card = cards[i];
                                    final has = card.acquired;
                                    return Transform.rotate(
                                        angle: (i % 4 == 0 || i % 4 == 3
                                                ? -2
                                                : 2) *
                                            3.141592653589793 /
                                            180,
                                        child: PoseCard(
                                            number: card.no,
                                            name: card.name,
                                            collected: has,
                                            imagePath: thumbnail(card.id),
                                            onTap: has
                                                ? () => context.push(
                                                    Routes.cardDetailOf(
                                                        card.id))
                                                : null));
                                  }, childCount: cards.length),
                                )),
                      ),
                    ],
                  )),
    );
  }
}
