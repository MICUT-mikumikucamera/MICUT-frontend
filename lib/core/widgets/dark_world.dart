import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// 다크 월드(촬영 가이드·카메라·처리 중) 화면을 감싼다.
/// 로고와 같은 순흑 + 일렉트릭 시안 테마를 적용하고 상태바를 밝은 아이콘으로 바꾼다.
class DarkWorld extends StatelessWidget {
  const DarkWorld({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(data: buildMiCutDarkTheme(), child: child),
    );
  }
}
