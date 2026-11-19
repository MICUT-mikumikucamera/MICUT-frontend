import 'package:flutter/material.dart';
import 'micut_icon.dart';

class MiCutBackButton extends StatelessWidget {
  const MiCutBackButton({super.key, this.onPressed});

  /// 없으면 이전 화면으로. 로그인 단계처럼 스택이 아니라 상태로 움직이는 곳에서 넘긴다.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '뒤로',
        icon: const MiCutIcon.asset('back'),
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      );
}
