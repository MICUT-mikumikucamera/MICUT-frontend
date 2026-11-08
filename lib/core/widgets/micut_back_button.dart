import 'package:flutter/material.dart';
import 'micut_icon.dart';

class MiCutBackButton extends StatelessWidget {
  const MiCutBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '뒤로',
        icon: const MiCutIcon.asset('back'),
        onPressed: () => Navigator.of(context).maybePop(),
      );
}
