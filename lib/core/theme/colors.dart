import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Neutral values are verified against docs/design-system.md.
/// Used brand fills are verified from the 2026-11-06 browser-exported .fig.
abstract final class MiCutColors {
  // Existing logo asset colors; not aliases for the unverified brand palette.
  static const brandCyan = Color(0xFF00FAFC);
  static const brandPink = Color(0xFFE4007F);
  static const ink = gray950;
  // Legacy alias names are retained for compatibility; their numeric suffixes
  // are not the source primary/secondary variable step numbers.
  static const cyan50 = Color(0xFFCFFAFE);
  static const cyan100 = Color(0xFFA5F3FC);
  static const cyan200 = Color(0xFF67E8F9);
  static const cyan300 = Color(0xFF22D3EE);
  static const cyan400 = Color(0xFF06B6D4);
  static const cyan500 = Color(0xFF0E7490);
  static const pink50 = Color(0xFFFCE7F3);
  static const pink100 = Color(0xFFF9A8D4);
  static const pink200 = Color(0xFFF472B6);
  static const pink300 = Color(0xFFEC4899);
  static const pink400 = Color(0xFFDB2777);
  static const pink500 = Color(0xFFBE185D);

  static const gray0 = Color(0xFFFEFEFE);
  static const gray100 = Color(0xFFF4F4F5);
  static const gray200 = Color(0xFFE4E4E7);
  static const gray300 = Color(0xFFD4D4D8);
  static const gray400 = Color(0xFFA1A1AA);
  static const gray500 = Color(0xFF71717A);
  static const gray600 = Color(0xFF52525B);
  static const gray700 = Color(0xFF3F3F46);
  static const gray950 = Color(0xFF09090B);
  // Unspecified legacy gray steps remain provisional.
  static const gray50 = Color(0xFFFAFAFA);
  static const gray800 = Color(0xFF27272A);
  static const white = gray0;
  static const black = Color(0xFF000000);

  static const bgDefault = gray0;
  static const bgSubtle = gray100;
  static const bgInverse = gray950;
  static const bgDisabled = gray200;
  static const bgPlaceholder = gray600;
  static const textDefault = gray950;
  static const textSubtle = gray500;
  static const textInverse = gray0;
  static const textDisabled = gray400;
  static const iconDefault = gray950;
  static const iconSubtle = gray300;
  static const iconInverse = gray0;
  static const iconDisabled = gray400;
  static const iconSelected = gray950;
  static const borderDefault = gray500;
  static const borderSubtle = gray200;
  static const borderBolder = gray700;
  static const borderDisabled = gray400;

  static const primary = cyan200;
  static const primaryStrong = cyan500;
  static const primarySoft = cyan50;
  static const onPrimary = textDefault;
  static const secondary = pink300;
  static const secondaryStrong = pink400;
  static const secondarySoft = pink50;
  static const onSecondarySoft = pink500;
  // Figma color/bg/danger/default → red/500.
  static const danger = Color(0xFFEF4444);
  static const bgDangerDefault = danger;
  static const onDanger = textInverse;

  static const background = bgDefault;
  static const surface = bgSubtle;
  static const surfaceTint = cyan50;
  static const border = borderSubtle;
  static const borderTint = cyan100;
  static const textPrimary = textDefault;
  static const textSecondary = textSubtle;
  static const textHint = textDisabled;
  static const placeholder = bgPlaceholder;
  static const onPlaceholder = textInverse;
  static const modalDim = Color(0x802D2D2D);
  static const dim = Color(0x80000000);

  static const darkBg = bgInverse;
  static const darkSurface = Color(0xFF262626);
  // Guide source #3D3D3D beneath its 35% black dim layer.
  static const savedNotice = Color(0xE6212121);
  static const guideBackground = Color(0xFF282828);
  static const darkSurfaceHi = gray700;
  static const darkText = textInverse;
  static const darkTextDim = gray300;
  // Compatibility for unused legacy HUD widgets.
  static const hud = brandCyan;
  static const hudDim = Color(0x9900FAFC);
  static const hudFaint = Color(0x3300FAFC);
}

/// Endpoints read from exported CTA and TabBar nodes.
abstract final class MiCutGradients {
  static const primary = _FigmaPrimaryGradient();
  static const capture = RadialGradient(
    colors: [MiCutColors.cyan300, MiCutColors.cyan50],
  );
  // Figma collection background node206:8678 extends below the frame.
  static const collection = LinearGradient(
    begin: Alignment(0, .23),
    end: Alignment(0, 1.58),
    colors: [MiCutColors.bgInverse, MiCutColors.primary],
  );
  static const storyTop = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xB3000000), Color(0x00000000)]);
  static const storyBottom = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0xCC000000)]);
  static const mint = primary;
  static const cyanDeep = LinearGradient(
    colors: [MiCutColors.cyan300, MiCutColors.cyan500],
  );
  static const blush = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [MiCutColors.pink300, MiCutColors.pink200],
  );
  static const darkFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Color(0x00000000)],
  );
}

/// Compatibility only. The current design does not add decorative glow.
abstract final class MiCutShadows {
  static const List<BoxShadow> glowCyan = [];
  static const List<BoxShadow> glowHud = [];
  static const List<BoxShadow> card = [];
}

/// Linked fill style 213:9266, including its affine gradient coordinates.
/// Instance paint caches contain older endpoints; the linked style matches PDF.
class _FigmaPrimaryGradient extends LinearGradient {
  const _FigmaPrimaryGradient()
      : super(colors: const [MiCutColors.cyan200, MiCutColors.cyan50]);
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final gx = .8273298740386963 / rect.width;
    final gy = .30039188265800476 / rect.height;
    final norm = gx * gx + gy * gy;
    const c = -.09662528336048126;
    final start = rect.topLeft + Offset(-c * gx / norm, -c * gy / norm);
    final end = start + Offset(gx / norm, gy / norm);
    return ui.Gradient.linear(start, end, colors);
  }
}
