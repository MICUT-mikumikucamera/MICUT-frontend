import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// 로고 페이지의 숨은 레이어 "HUD / 2 Viewfinder Corners" 를 위젯으로 옮긴 것.
/// 뷰파인더 네 모서리 괄호. 카메라·처리 중·홈 히어로 타일에 쓴다.
class HudCorners extends StatelessWidget {
  const HudCorners({
    super.key,
    this.color = MiCutColors.hud,
    this.length = 22,
    this.thickness = 2,
    this.inset = 0,
    this.child,
  });

  final Color color;
  final double length;
  final double thickness;
  final double inset;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CornersPainter(
        color: color,
        length: length,
        thickness: thickness,
        inset: inset,
      ),
      child: child,
    );
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter({
    required this.color,
    required this.length,
    required this.thickness,
    required this.inset,
  });

  final Color color;
  final double length;
  final double thickness;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;
    final r = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final l = length;
    // TL
    canvas.drawLine(r.topLeft, r.topLeft + Offset(l, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + Offset(0, l), p);
    // TR
    canvas.drawLine(r.topRight, r.topRight + Offset(-l, 0), p);
    canvas.drawLine(r.topRight, r.topRight + Offset(0, l), p);
    // BL
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(l, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(0, -l), p);
    // BR
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(-l, 0), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(0, -l), p);
  }

  @override
  bool shouldRepaint(_CornersPainter old) =>
      old.color != color || old.length != length || old.thickness != thickness || old.inset != inset;
}

/// "HUD / 1 AF Focus Box" — 가운데 십자 + 네 모서리. 처리 중 화면의 포커스 애니메이션용.
class HudFocusBox extends StatelessWidget {
  const HudFocusBox({
    super.key,
    this.size = 180,
    this.color = MiCutColors.hud,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: HudCorners(color: color, length: size * 0.18, thickness: 2),
          ),
          Center(
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _CrossPainter(color),
            ),
          ),
          if (label != null)
            Positioned(
              top: -Spacing.xl,
              left: 0,
              child: Text(label!, style: MiCutText.hud.copyWith(color: color)),
            ),
        ],
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1;
    final c = size.center(Offset.zero);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), p);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), p);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}

/// "HUD / 4 Micro Text" 의 REC 점 + 작은 상태 텍스트. 예: `HudStatus(text: 'ANALYZING SCENE')`
class HudStatus extends StatelessWidget {
  const HudStatus({super.key, required this.text, this.blinking = true, this.color = MiCutColors.hud});
  final String text;
  final bool blinking;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color, blinking: blinking),
        const SizedBox(width: Spacing.sm),
        Text(text, style: MiCutText.hud.copyWith(color: color)),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.blinking});
  final Color color;
  final bool blinking;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.blinking) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.blinking ? _c : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
