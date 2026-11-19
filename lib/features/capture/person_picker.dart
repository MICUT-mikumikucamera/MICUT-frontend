import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/jobs/job.dart';

/// 크롭 화면 위에 그릴 사람 한 명.
class PersonInCrop {
  const PersonInCrop(this.person, this.rect);
  final DetectedPerson person;

  /// 크롭 영역 기준 0~1 비율 사각형 (크롭 밖으로 나간 부분은 잘림).
  final Rect rect;
}

/// AI 의 `bbox_norm`(원본 전체 기준) → 크롭 화면 기준으로 바꾼다.
///
/// 결과 사진은 크롭 영역만 나오므로, 박스 **중심이 크롭 밖**인 사람은
/// 결과에 안 나온다고 보고 목록에서 뺀다(숨김 + 선택 불가).
/// [crop] 이 없으면 원본 전체를 크롭으로 본다.
List<PersonInCrop> peopleInCrop(
  List<DetectedPerson> people, {
  required int imageWidth,
  required int imageHeight,
  CropRegion? crop,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) return const [];
  final c = crop == null
      ? Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble())
      : Rect.fromLTWH(crop.x.toDouble(), crop.y.toDouble(),
          crop.width.toDouble(), crop.height.toDouble());
  if (c.width <= 0 || c.height <= 0) return const [];

  final out = <PersonInCrop>[];
  for (final p in people) {
    if (p.bboxNorm.length != 4) continue;
    final box = Rect.fromLTRB(
      p.bboxNorm[0] * imageWidth,
      p.bboxNorm[1] * imageHeight,
      p.bboxNorm[2] * imageWidth,
      p.bboxNorm[3] * imageHeight,
    );
    if (box.width <= 0 || box.height <= 0) continue;
    if (!c.contains(box.center)) continue;
    final clipped = box.intersect(c);
    out.add(PersonInCrop(
      p,
      Rect.fromLTRB(
        (clipped.left - c.left) / c.width,
        (clipped.top - c.top) / c.height,
        (clipped.right - c.left) / c.width,
        (clipped.bottom - c.top) / c.height,
      ),
    ));
  }
  return out;
}

/// 사람 선택(계약 2026-11-18) — 크롭된 사진 위에 사람 박스를 그린다.
/// 사진은 [BoxFit.contain] 으로 그려지므로 [aspectRatio](크롭 가로/세로)로 위치를 맞춘다.
class PersonPickerOverlay extends StatelessWidget {
  const PersonPickerOverlay({
    super.key,
    required this.aspectRatio,
    required this.people,
    required this.selectedId,
    required this.onSelect,
  });

  final double aspectRatio;
  final List<PersonInCrop> people;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (aspectRatio <= 0) return const SizedBox.shrink();
        var w = c.maxWidth, h = c.maxWidth / aspectRatio;
        if (h > c.maxHeight) {
          h = c.maxHeight;
          w = h * aspectRatio;
        }
        final dx = (c.maxWidth - w) / 2, dy = (c.maxHeight - h) / 2;
        return Stack(children: [
          for (final (i, p) in people.indexed)
            Positioned(
              left: dx + p.rect.left * w,
              top: dy + p.rect.top * h,
              width: p.rect.width * w,
              height: p.rect.height * h,
              child: _PersonBox(
                index: i + 1,
                eligible: p.person.eligible,
                selected: p.person.personId == selectedId,
                onTap: p.person.eligible
                    ? () => onSelect(p.person.personId)
                    : null,
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
