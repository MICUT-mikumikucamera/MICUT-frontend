import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A 48×48 icon control with its icon and interaction feedback centered.
class MiCutIconButton extends StatelessWidget {
  const MiCutIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        alignment: Alignment.center,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          overlayColor: MiCutColors.gray200,
        ),
        icon: Center(child: icon),
      );
}
