import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/jobs/job.dart';

/// 사람 선택(계약 2026-11-18) — 원본 사진 위에 AI가 찾은 사람 박스를 그린다.
///
/// `bbox_norm` 은 접수 때 보낸 **원본 사진** 기준 비율이라, 원본을
/// [BoxFit.contain] 으로 그린 영역에 그대로 대응시킨다. 크롭 변환은 하지 않는다.
class PersonPickerOverlay extends StatelessWidget {
  const PersonPickerOverlay({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
    required this.people,
    required this.selectedId,
    required this.onSelect,
  });

  final int imageWidth, imageHeight;
  final List<DetectedPerson> people;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (imageWidth <= 0 || imageHeight <= 0) return const SizedBox.shrink();
        final scale = (c.maxWidth / imageWidth) < (c.maxHeight / imageHeight)
            ? c.maxWidth / imageWidth
            : c.maxHeight / imageHeight;
        final w = imageWidth * scale, h = imageHeight * scale;
        final dx = (c.maxWidth - w) / 2, dy = (c.maxHeight - h) / 2;
        return Stack(children: [
          for (final (i, p) in people.indexed)
            if (p.bboxNorm.length == 4)
              Positioned(
                left: dx + p.bboxNorm[0].clamp(0.0, 1.0) * w,
                top: dy + p.bboxNorm[1].clamp(0.0, 1.0) * h,
                width: ((p.bboxNorm[2] - p.bboxNorm[0]).clamp(0.0, 1.0)) * w,
                height: ((p.bboxNorm[3] - p.bboxNorm[1]).clamp(0.0, 1.0)) * h,
                child: _PersonBox(
                  index: i + 1,
                  eligible: p.eligible,
                  selected: p.personId == selectedId,
                  onTap: p.eligible ? () => onSelect(p.personId) : null,
                ),
              ),
        ]);
      });
}

class _PersonBox extends StatelessWidget {
  const _PersonBox(
      {required this.index,
      required this.eligible,
      required this.selected,
      required this.onTap});
  final int index;
  final bool eligible, selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = !eligible
        ? MiCutColors.gray400
        : selected
            ? MiCutColors.primary
            : MiCutColors.white;
    return Semantics(
      button: eligible,
      selected: selected,
      enabled: eligible,
      label: eligible ? '사람 $index' : '사람 $index, 너무 작아서 고를 수 없음',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected
                ? MiCutColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: selected ? 3 : 1.5),
          ),
        ),
      ),
    );
  }
}
