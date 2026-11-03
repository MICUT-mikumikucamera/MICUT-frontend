import 'package:flutter/material.dart';
import 'colors.dart';

/// 글꼴 토큰. 본문은 Pretendard(OFL, assets/fonts).
/// 로고 워드마크는 글꼴이 아니라 이미지(assets/brand)로 쓴다.
abstract final class MiCutText {
  static const family = 'Pretendard';

  static const _base = TextStyle(
    fontFamily: family,
    color: MiCutColors.textPrimary,
    height: 1.3,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final display = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static final h1 = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
  static final h3 = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600);
  static final body = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400);
  static final bodyBold = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
  static final caption = _base.copyWith(fontSize: 13, color: MiCutColors.textSecondary);
  static final label = _base.copyWith(fontSize: 11, color: MiCutColors.textSecondary);
  static final button = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  /// 로고 페이지의 "HUD 마이크로 텍스트" 모티프. 다크 월드에서 상태 표시용.
  /// 예: "REC ● ANALYZING", "AF  ·  MIKU"
  static final hud = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    color: MiCutColors.hud,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
