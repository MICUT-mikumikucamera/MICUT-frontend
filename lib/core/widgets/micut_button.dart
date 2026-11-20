import 'micut_icon.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum MiCutButtonType { primary, secondary, tertiary, danger }

/// Shared CTA. Modal confirmations can opt into a solid primary fill.
class MiCutButton extends StatelessWidget {
  const MiCutButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.type = MiCutButtonType.primary,
      this.expand = true,
      this.loading = false,
      this.onDark = false,
      this.icon,
      this.leading,
      this.solid = true,
      this.height = Spacing.buttonHeight,
      this.radius = Spacing.radius16});
  final String label;
  final VoidCallback? onPressed;
  final MiCutButtonType type;
  final bool expand, loading, onDark, solid;
  final IconData? icon;
  final Widget? leading;
  final double height, radius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final primary = type == MiCutButtonType.primary;
    final bg = !enabled
        ? MiCutColors.bgDisabled
        : switch (type) {
            MiCutButtonType.primary => MiCutColors.primary,
            MiCutButtonType.secondary => MiCutColors.bgSubtle,
            MiCutButtonType.tertiary => MiCutColors.bgDefault,
            MiCutButtonType.danger => MiCutColors.danger,
          };
    final fg = !enabled
        ? MiCutColors.textDisabled
        : type == MiCutButtonType.danger
            ? MiCutColors.textInverse
            : MiCutColors.textDefault;
    final borderRadius = BorderRadius.circular(radius);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: bg,
              borderRadius: borderRadius,
              gradient:
                  enabled && primary && !solid ? MiCutGradients.primary : null),
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: fg,
              disabledForegroundColor: fg,
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: Size(0, height),
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.sm),
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              textStyle: MiCutText.button,
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MiCutColors.iconDisabled))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: Spacing.ctaGap)
                        ],
                        if (icon != null) ...[
                          MiCutIcon(icon, size: 18),
                          const SizedBox(width: Spacing.ctaGap)
                        ],
                        Flexible(
                            child: Text(label, textAlign: TextAlign.center)),
                      ]),
          ),
        ),
      ),
    );
  }
}
