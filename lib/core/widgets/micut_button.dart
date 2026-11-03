import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum MiCutButtonType { primary, secondary, danger }

/// Figma `Button` 컴포넌트 (Type=Primary / Type=Secondary) + 삭제용 danger.
///
/// 라이트 월드:
///   primary   = cyan400 배경 + ink 글자  (대비 5.9)
///   secondary = cyan50 배경 + cyan500 글자 (대비 4.7)
///   danger    = pink400 배경 + 흰 글자   (대비 4.6)
/// 다크 월드([onDark] = true):
///   primary   = 일렉트릭 시안 배경 + ink 글자
///   secondary = 투명 + 흰 테두리/글자
class MiCutButton extends StatelessWidget {
  const MiCutButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = MiCutButtonType.primary,
    this.expand = true,
    this.loading = false,
    this.onDark = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final MiCutButtonType type;
  final bool expand;
  final bool loading;
  final bool onDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = _palette();

    return SizedBox(
      height: Spacing.buttonHeight,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: bg.a * 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: side,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
          ),
          textStyle: MiCutText.button,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  (Color, Color, BorderSide?) _palette() {
    if (onDark) {
      return switch (type) {
        MiCutButtonType.primary => (MiCutColors.hud, MiCutColors.ink, null),
        MiCutButtonType.secondary => (
            Colors.transparent,
            MiCutColors.white,
            const BorderSide(color: MiCutColors.darkTextDim),
          ),
        MiCutButtonType.danger => (MiCutColors.pink300, MiCutColors.white, null),
      };
    }
    return switch (type) {
      MiCutButtonType.primary => (MiCutColors.primary, MiCutColors.onPrimary, null),
      MiCutButtonType.secondary => (
          MiCutColors.primarySoft,
          MiCutColors.primaryStrong,
          null,
        ),
      MiCutButtonType.danger => (MiCutColors.danger, MiCutColors.white, null),
    };
  }
}
