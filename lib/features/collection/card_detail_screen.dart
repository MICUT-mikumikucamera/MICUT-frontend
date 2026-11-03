import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';
import '../../data/local/poses.dart';

/// Figma 12 카드 상세. 같은 포즈로 찍은 사진들을 가로로 넘겨본다.
/// 카드 프레임은 흰 면 + 시안 테두리, 번호는 핑크 칩.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pose = kPoses.where((p) => p.id == id).firstOrNull;
    final photos = (ref.watch(galleryProvider).valueOrNull ?? const [])
        .where((g) => g.cardIds.contains(id))
        .toList();

    if (pose == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('없는 카드예요')));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        children: [
          SizedBox(
            height: 417,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.88),
              itemCount: photos.isEmpty ? 1 : photos.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: MiCutColors.white,
                    borderRadius: BorderRadius.circular(Spacing.radiusXl),
                    border: Border.all(color: MiCutColors.borderTint),
                    boxShadow: MiCutShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PhotoPlaceholder(
                          path: photos.isEmpty ? null : photos[i].path,
                          width: double.infinity,
                          radius: Spacing.radiusMd,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: MiCutColors.secondarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('#${pose.id}',
                                style: MiCutText.label.copyWith(
                                    color: MiCutColors.onSecondarySoft, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          if (photos.length > 1)
                            Text('${i + 1} / ${photos.length}', style: MiCutText.label),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(pose.name, style: MiCutText.h2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('날짜', style: MiCutText.caption),
                const SizedBox(height: Spacing.sm),
                Text(photos.isEmpty ? '-' : _fmt(photos.first.createdAt), style: MiCutText.body),
                const SizedBox(height: Spacing.xl),
                Text('메모', style: MiCutText.caption),
                const SizedBox(height: Spacing.sm),
                Text('메모를 입력해주세요.', style: MiCutText.body.copyWith(color: MiCutColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
