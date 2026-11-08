import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'micut_icon.dart';

class MiCutLoading extends StatefulWidget {
  const MiCutLoading({super.key});
  @override
  State<MiCutLoading> createState() => _MiCutLoadingState();
}

class _MiCutLoadingState extends State<MiCutLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
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
      child: RotationTransition(
          turns: _rotation,
          child: const MiCutIcon.asset('loading',
              size: 80, color: MiCutColors.cyan100)));
}
