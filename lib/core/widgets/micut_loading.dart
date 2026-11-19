import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'miku_illust.dart';

/// 04 처리 중 — 사진 위에 SD 미쿠(미쿠_로딩)가 통통 튀며 흔들리는 로딩.
/// 시스템 "애니메이션 줄이기"가 켜져 있으면 멈춘 상태로 보여준다.
class MiCutLoading extends StatefulWidget {
  const MiCutLoading({super.key, this.size = 200});
  final double size;
  @override
  State<MiCutLoading> createState() => _MiCutLoadingState();
}

class _MiCutLoadingState extends State<MiCutLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _curve =
      CurvedAnimation(parent: _bounce, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _bounce.stop();
      _bounce.value = 0;
    } else if (!_bounce.isAnimating) {
      _bounce.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: '처리 중',
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, child) {
            final t = _curve.value; // 0 → 1 → 0
            return Transform.translate(
              offset: Offset(0, -widget.size * .06 * t),
              child: Transform.rotate(
                angle: (t * 2 - 1) * 5 * math.pi / 180,
                child: child,
              ),
            );
          },
          child: MikuIllustImage(MikuIllust.loading, size: widget.size),
        ),
      );
}
