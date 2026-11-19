import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'miku_illust.dart';
import 'pose_card.dart';

/// 05-1 결과 (신규 컬렉션). 카드가 떠오른 뒤 사진 위로 SD 미쿠가 튀어나온다.
/// 화면을 탭하면 닫힌다. 애니메이션은 한 번만 재생(반복 없음).
class NewCollectionOverlay extends StatefulWidget {
  const NewCollectionOverlay(
      {super.key,
      required this.number,
      required this.name,
      required this.imagePath,
      required this.onClose});
  final int number;
  final String name;
  final String? imagePath;
  final VoidCallback onClose;

  @override
  State<NewCollectionOverlay> createState() => _NewCollectionOverlayState();
}

class _NewCollectionOverlayState extends State<NewCollectionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  // 0~35%: 제목·카드가 아래에서 떠오름 / 30~100%: 미쿠 팝인(탄성)
  late final Animation<double> _card = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, .35, curve: Curves.easeOutCubic));
  late final Animation<double> _miku = CurvedAnimation(
      parent: _intro, curve: const Interval(.3, 1, curve: Curves.elasticOut));

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = (constraints.maxWidth / 375).clamp(0.0, 1.0);
          final cardW = 327 * scale, cardH = 424 * scale;
          // PoseCard 안 사진 영역: 위 16, 좌우 16, 아래 텍스트 블록(약 91).
          final photoTop = 16 * scale, photoH = cardH - (16 + 91) * scale;
          return Stack(children: [
            Positioned(
                top: constraints.maxHeight * 130 / 812,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                    animation: _card,
                    builder: (context, child) => Opacity(
                        opacity: _card.value,
                        child: Transform.translate(
                            offset: Offset(0, 40 * scale * (1 - _card.value)),
                            child: child)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Material(
                          color: MiCutColors.bgInverse,
                          child: Padding(
                              padding: EdgeInsets.all(10 * scale),
                              child: Text('신규 컬렉션 획득!',
                                  style: MiCutText.display.copyWith(
                                      fontSize: 36 * scale,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'DungGeunMo',
                                      color: MiCutColors.cyan200)))),
                      SizedBox(height: 15 * scale),
                      Transform.rotate(
                          angle: 3 * 3.141592653589793 / 180,
                          child: SizedBox(
                              width: cardW,
                              height: cardH,
                              child: Stack(children: [
                                Positioned.fill(
                                    child: PoseCard(
                                        number: widget.number,
                                        name: widget.name,
                                        imagePath: widget.imagePath,
                                        onTap: widget.onClose)),
                                // Figma 177:7305 — 사진 가운데 205px 미쿠.
                                Positioned(
                                    top: photoTop,
                                    left: 0,
                                    right: 0,
                                    height: photoH,
                                    child: IgnorePointer(
                                        child: Center(
                                            child: ScaleTransition(
                                                scale: _miku,
                                                child: MikuIllustImage(
                                                    MikuIllust.cheer,
                                                    size: 205 * scale))))),
                              ]))),
                    ])))
          ]);
        }),
      );
}
