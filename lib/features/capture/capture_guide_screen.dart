import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/dark_world.dart';
import '../../core/widgets/hud_frame.dart';
import '../../core/widgets/micut_button.dart';

/// Figma 01 촬영 가이드 — 다크 월드 입구. 로고 색 조합(순흑 + 시안)으로 "카메라 모드" 전환을 알린다.
///
/// TODO(AI 확인 필요): 백엔드 에러 코드(PERSON_NOT_FOUND, FOOT_LOW_CONFIDENCE)는
/// 사람이 찍혀야 하는 전제인데 와이어프레임 문구는 "사람이 없는 장소". 확정되면 문구 교체.
class CaptureGuideScreen extends StatelessWidget {
  const CaptureGuideScreen({super.key});

  static const guideText = '사람이 없는 장소를 찍어주세요';

  @override
  Widget build(BuildContext context) {
    return DarkWorld(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(variant: BrandLogoVariant.cyan, height: 18),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                const HudStatus(text: 'GUIDE · 01'),
                const SizedBox(height: Spacing.lg),
                HudCorners(
                  length: 26,
                  child: Container(
                    width: 220,
                    height: 250,
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.landscape_outlined,
                            size: 56, color: MiCutColors.hudDim),
                        const SizedBox(height: Spacing.md),
                        Text('가이드 일러스트',
                            style: MiCutText.label.copyWith(color: MiCutColors.darkTextDim)),
                        const SizedBox(height: Spacing.xl),
                        // 와이어프레임의 "바닥 라인"
                        Container(height: 2, color: MiCutColors.hud),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
                Text(
                  guideText,
                  textAlign: TextAlign.center,
                  style: MiCutText.h2.copyWith(color: MiCutColors.darkText),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  '미쿠가 설 자리를 비워두면 더 자연스러워요',
                  textAlign: TextAlign.center,
                  style: MiCutText.caption.copyWith(color: MiCutColors.darkTextDim),
                ),
                const Spacer(flex: 3),
                MiCutButton(
                  label: '확인',
                  onDark: true,
                  onPressed: () => context.pushReplacement(Routes.captureCamera),
                ),
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
