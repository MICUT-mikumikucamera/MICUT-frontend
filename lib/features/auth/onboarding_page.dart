import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/word_wrap_text.dart';

/// Scroll the form independently while keeping its action above the keyboard.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage(
      {super.key,
      required this.title,
      required this.description,
      required this.content,
      required this.action,
      this.contentGap = 70,
      this.onBack});
  final String title, description;
  final Widget content, action;
  final double contentGap;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: MiCutColors.bgDefault,
      appBar: AppBar(
          toolbarHeight: 51,
          leading: onBack == null
              ? null
              : IconButton(
                  tooltip: '뒤로',
                  onPressed: onBack,
                  icon: const MiCutIcon.asset('back')),
          automaticallyImplyLeading: false),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(Spacing.screenH,
                        Spacing.xxl, Spacing.screenH, Spacing.xl),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WordWrapText(title,
                              style: MiCutText.heading24Semibold),
                          const SizedBox(height: 12),
                          WordWrapText(description,
                              style: MiCutText.body16Regular
                                  .copyWith(color: MiCutColors.textSubtle)),
                          SizedBox(height: contentGap),
                          content,
                        ]))),
            Padding(
                padding: EdgeInsets.fromLTRB(
                    Spacing.screenH,
                    8,
                    Spacing.screenH,
                    (32 - MediaQuery.paddingOf(context).bottom)
                        .clamp(0.0, 32.0)),
                child: action),
          ])));
}
