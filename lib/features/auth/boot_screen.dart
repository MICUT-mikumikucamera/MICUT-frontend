import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/widgets/brand_logo.dart';

/// 저장된 로그인 상태를 읽는 동안만 보인다. 네이티브 스플래시와 같은 순흑 + 시안 로고라
/// 홈이 잠깐 비쳐 보이지 않고 이어진다.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: MiCutColors.darkBg,
        body: Center(
            child: BrandLogo(variant: BrandLogoVariant.cyan, height: 40)),
      );
}
