import 'package:flutter/material.dart';

/// MiCut 컬러 토큰.
///
/// 출처: Figma 〈미컷〉 로고 페이지 + 무드보드 컬러칩 (GDG KU 미컷).
/// 두 개의 세계로 나뉜다:
///  - **라이트 월드** (홈·갤러리·컬렉션·결과·설정): 흰 배경 + Tailwind Cyan 스케일이 Primary, Pink가 포인트
///  - **다크 월드** (촬영 가이드·카메라·처리 중·스플래시): 로고와 같은 순흑 + 일렉트릭 시안(#00FAFC)
///
/// 대비 메모 (WCAG AA 4.5:1 기준, 직접 계산):
///  - ink on cyan400  = 5.9  ✅  → Primary 버튼은 "시안 배경 + 검정 글자"
///  - white on cyan400 = 2.4 ❌  → 시안 위에 흰 글자 금지
///  - cyan500 on cyan50 = 4.7 ✅ → Secondary 버튼
///  - white on pink400 = 4.6 ✅  → 삭제/위험 버튼
///  - brandCyan on ink = 15+ ✅   → 다크 월드 강조
abstract final class MiCutColors {
  // ── 로고 원색 (다크 월드·아이콘·스플래시 전용. 라이트 UI 버튼에는 쓰지 않는다) ──
  static const brandCyan = Color(0xFF00FAFC); // 로고 미쿠 실루엣·앱 아이콘 배경
  static const brandPink = Color(0xFFE4007F); // 반전 로고 워드마크
  static const ink = Color(0xFF0B0B0B); // 로고 배경·아이콘 M

  // ── Primary: Cyan (무드보드 칩 100→700) ──
  static const cyan50 = Color(0xFFCFFAFE);
  static const cyan100 = Color(0xFFA5F3FC);
  static const cyan200 = Color(0xFF67E8F9);
  static const cyan300 = Color(0xFF22D3EE);
  static const cyan400 = Color(0xFF06B6D4);
  static const cyan500 = Color(0xFF0E7490);

  // ── Secondary: Pink (무드보드 칩 100→700) ──
  static const pink50 = Color(0xFFFCE7F3);
  static const pink100 = Color(0xFFF9A8D4);
  static const pink200 = Color(0xFFF472B6);
  static const pink300 = Color(0xFFEC4899);
  static const pink400 = Color(0xFFDB2777);
  static const pink500 = Color(0xFFBE185D);

  // ── Neutral ──
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const gray50 = Color(0xFFF7F8F9);
  static const gray100 = Color(0xFFE8EBED);
  static const gray200 = Color(0xFFD0D4D9);
  static const gray400 = Color(0xFF9AA0A6);
  static const gray600 = Color(0xFF5F6368);
  static const gray800 = Color(0xFF26282B);

  // ── 라이트 월드 시맨틱 ──
  static const primary = cyan400;
  static const primaryStrong = cyan500;
  static const primarySoft = cyan50;
  static const onPrimary = ink;
  static const secondary = pink300;
  static const secondaryStrong = pink400;
  static const secondarySoft = pink50;
  static const onSecondarySoft = pink500;
  static const danger = pink400;

  static const background = white;
  static const surface = gray50;
  static const surfaceTint = cyan50;
  static const border = gray100;
  static const borderTint = cyan100;
  static const textPrimary = gray800;
  static const textSecondary = gray600;
  static const textHint = gray400;
  static const placeholder = cyan50;
  static const onPlaceholder = cyan500;
  static const dim = Color(0x80000000);

  // ── 다크 월드 시맨틱 ──
  static const darkBg = ink;
  static const darkSurface = Color(0xFF161718);
  static const darkSurfaceHi = Color(0xFF26282B);
  static const darkText = white;
  static const darkTextDim = Color(0xB3FFFFFF); // 70%
  static const hud = brandCyan;
  static const hudDim = Color(0x9900FAFC); // 60%
  static const hudFaint = Color(0x3300FAFC); // 20%
}

/// 무드보드의 "민트 계열 그라데이션".
abstract final class MiCutGradients {
  /// 홈 히어로 타일. 위에 올리는 글자는 ink.
  static const mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MiCutColors.cyan100, MiCutColors.cyan300],
  );

  /// 진행 바·강조 선.
  static const cyanDeep = LinearGradient(
    colors: [MiCutColors.cyan300, MiCutColors.cyan500],
  );

  /// 컬렉션 타일 등 핑크 포인트 면.
  static const blush = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MiCutColors.pink50, Color(0xFFFBD0E8)],
  );

  /// 다크 월드 상단/하단 비네팅.
  static const darkFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Color(0x00000000)],
  );
}

/// 그림자 토큰.
abstract final class MiCutShadows {
  static const glowCyan = [
    BoxShadow(color: Color(0x6622D3EE), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const glowHud = [
    BoxShadow(color: Color(0x8000FAFC), blurRadius: 24),
  ];
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
