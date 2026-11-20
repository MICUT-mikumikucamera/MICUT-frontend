import 'package:flutter/material.dart';
import 'miku_illustration.dart';

class MiCutLoading extends StatefulWidget {
  const MiCutLoading({super.key});
  @override
  State<MiCutLoading> createState() => _MiCutLoadingState();
}

class _MiCutLoadingState extends State<MiCutLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
  late final Animation<double> _angle = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -.345), weight: 184),
    TweenSequenceItem(tween: Tween(begin: -.345, end: .226), weight: 205),
    TweenSequenceItem(tween: Tween(begin: .226, end: -.298), weight: 214),
    TweenSequenceItem(tween: Tween(begin: -.298, end: .320), weight: 196),
    TweenSequenceItem(tween: Tween(begin: .320, end: -.269), weight: 214),
    TweenSequenceItem(tween: Tween(begin: -.269, end: 0.0), weight: 187),
  ]).animate(_rotation);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
      _rotation.value = 0;
    } else {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: '처리 중',
      child: AnimatedBuilder(
          animation: _angle,
          builder: (_, child) =>
              Transform.rotate(angle: _angle.value, child: child),
          child: const MikuIllustration(MikuArtwork.loading, size: 209)));
}
