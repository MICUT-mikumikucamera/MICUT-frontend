import 'package:flutter/material.dart';
import 'micut_icon.dart';

class MiCutBackButton extends StatelessWidget {
  const MiCutBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '뒤로',
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        icon: const Center(child: MiCutIcon.asset('back', size: 24)),
        onPressed: () => Navigator.of(context).maybePop(),
      );
}
