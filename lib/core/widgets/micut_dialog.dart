import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'micut_button.dart';

/// Figma modal: 335 wide, 24 padding + 1 border, 16 gaps, 48 high CTAs.
class MiCutDialog extends StatelessWidget {
  const MiCutDialog(
      {super.key,
      required this.title,
      required this.message,
      required this.confirmLabel,
      required this.onConfirm,
      this.danger = false,
      this.padding = 21});
  final String title, message, confirmLabel;
  final VoidCallback? onConfirm;
  final bool danger;
  final double padding;

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenH, vertical: Spacing.xl),
        constraints: const BoxConstraints(maxWidth: 335),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radius16),
            side: const BorderSide(color: MiCutColors.borderDefault)),
        child: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MiCutText.heading18Semibold),
                const SizedBox(height: Spacing.modalGap),
                Text(message,
                    style: MiCutText.body16Regular
                        .copyWith(color: MiCutColors.textSubtle)),
                const SizedBox(height: Spacing.modalGap),
                Row(children: [
                  Expanded(
                      child: MiCutButton(
                          label: '취소',
                          height: 48,
                          type: MiCutButtonType.secondary,
                          onPressed: () => Navigator.of(context).pop(false))),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                      child: MiCutButton(
                          label: confirmLabel,
                          height: 48,
                          type: danger
                              ? MiCutButtonType.danger
                              : MiCutButtonType.primary,
                          onPressed: onConfirm)),
                ]),
              ]),
        )),
      );
}
