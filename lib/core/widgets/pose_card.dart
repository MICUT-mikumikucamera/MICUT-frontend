import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'photo_placeholder.dart';

/// Figma `PoseCard`. 컬렉션 그리드의 카드 하나.
///
/// 수집함:  흰 카드 + 시안 테두리, 번호는 핑크 칩 (Secondary = 포인트).
/// 미수집:  민트 면 + "?" 실루엣, 전체 톤 다운.
class PoseCard extends StatelessWidget {
  const PoseCard({
    super.key,
    required this.number,
    required this.name,
    this.imagePath,
    this.collected = true,
    this.isNew = false,
    this.onTap,
  });

  final int number;
  final String name;
  final String? imagePath;
  final bool collected;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final numberLabel = '#${number.toString().padLeft(3, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: collected ? MiCutColors.white : MiCutColors.surfaceTint,
          borderRadius: BorderRadius.circular(Spacing.radiusLg),
          border: Border.all(
            color: collected ? MiCutColors.borderTint : MiCutColors.cyan50,
          ),
          boxShadow: collected ? MiCutShadows.card : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (collected)
                    PhotoPlaceholder(
                      path: imagePath,
                      radius: Spacing.radiusMd,
                      label: '포즈',
                    )
                  else
                    const _Unknown(),
                  if (isNew)
                    const Positioned(
                      top: Spacing.sm,
                      right: Spacing.sm,
                      child: _Chip(label: 'NEW', filled: true),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                _Chip(label: numberLabel, filled: false, muted: !collected),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              collected ? name : '미수집',
              style: MiCutText.bodyBold.copyWith(
                color: collected ? MiCutColors.textPrimary : MiCutColors.cyan500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Unknown extends StatelessWidget {
  const _Unknown();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.radiusMd),
      child: const ColoredBox(
        color: MiCutColors.cyan50,
        child: Center(
          child: Icon(Icons.question_mark_rounded,
              size: 32, color: MiCutColors.cyan200),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.filled, this.muted = false});
  final String label;
  final bool filled;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? MiCutColors.secondary
        : (muted ? MiCutColors.cyan100 : MiCutColors.secondarySoft);
    final fg = filled
        ? MiCutColors.white
        : (muted ? MiCutColors.cyan500 : MiCutColors.onSecondarySoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: MiCutText.label.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
