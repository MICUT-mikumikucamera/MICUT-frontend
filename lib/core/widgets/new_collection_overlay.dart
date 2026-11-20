import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'miku_illustration.dart';
import 'pose_card.dart';

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
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  Timer? _dismiss;
  bool _closed = false;
  @override
  void initState() {
    super.initState();
    _dismiss = Timer(const Duration(seconds: 3), _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    _dismiss?.cancel();
    widget.onClose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating && _motion.value == 0) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: '신규 컬렉션 획득! ${widget.name}. 닫기',
      button: true,
      onTap: _close,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: LayoutBuilder(builder: (context, constraints) {
            final scale = (constraints.maxWidth / 375).clamp(0.0, 1.0);
            return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                    child: Padding(
                        padding: EdgeInsets.only(
                            top: constraints.maxHeight * 130 / 812,
                            bottom: 24 * scale),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Material(
                              color: MiCutColors.bgInverse,
                              child: Padding(
                                  padding: EdgeInsets.all(10 * scale),
                                  child: Text('신규 컬렉션 획득!',
                                      textAlign: TextAlign.center,
                                      style: MiCutText.display.copyWith(
                                          fontSize: 36 * scale,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'DungGeunMo',
                                          color: MiCutColors.cyan200)))),
                          SizedBox(height: 15 * scale),
                          Stack(alignment: Alignment.center, children: [
                            Transform.rotate(
                                angle: 3 * 3.141592653589793 / 180,
                                child: SizedBox(
                                    width: 327 * scale,
                                    height: 424 * scale,
                                    child: PoseCard(
                                        number: widget.number,
                                        name: widget.name,
                                        imagePath: widget.imagePath,
                                        onTap: _close))),
                            IgnorePointer(
                                child: AnimatedBuilder(
                                    animation: _motion,
                                    child: MikuIllustration(MikuArtwork.capture,
                                        size: 216 * scale),
                                    builder: (context, child) {
                                      if (MediaQuery.disableAnimationsOf(
                                          context)) {
                                        return child!;
                                      }
                                      final t = _motion.value;
                                      final opacity = t < .1
                                          ? 0.0
                                          : t < .55
                                              ? Curves.easeInOut
                                                  .transform((t - .1) / .45)
                                              : t < .76
                                                  ? 1.0
                                                  : 1 -
                                                      Curves.easeInOut
                                                          .transform(
                                                              (t - .76) / .24);
                                      final dy = t < .55
                                          ? 55 - 41 * (t / .55)
                                          : t < .76
                                              ? 14.0
                                              : 14 - 49 * ((t - .76) / .24);
                                      return Opacity(
                                          opacity: opacity.clamp(0, 1),
                                          child: Transform.translate(
                                              offset: Offset(0, dy * scale),
                                              child: child));
                                    })),
                          ]),
                        ]))));
          })));
}
