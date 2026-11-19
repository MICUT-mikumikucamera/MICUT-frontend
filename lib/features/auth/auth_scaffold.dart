import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_back_button.dart';
import '../../core/widgets/micut_button.dart';

/// 00-1 ~ 00-3 공통 틀: 뒤로 가기, 제목·설명, 본문, 아래 고정 CTA.
///
/// 키보드가 올라오면 본문이 줄어들고 CTA 가 키보드 위로 따라 올라온다.
/// 아래 여백은 시스템 내비게이션 바(inset)를 피한다.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.cta,
    this.subtitle,
    this.onBack,
    this.gapAfterHeader = 70,
    this.child,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// 제목 블록과 본문 사이 간격. 시안은 닉네임 70, 약관 80.
  final double gapAfterHeader;
  final Widget? child;
  final Widget cta;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: MiCutColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: Spacing.s8),
                child: MiCutBackButton(onPressed: onBack),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                    Spacing.screenH, Spacing.s32, Spacing.screenH, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: MiCutText.heading24Semibold),
                      if (subtitle != null) ...[
                        const SizedBox(height: Spacing.md),
                        Text(subtitle!,
                            style: MiCutText.body16Regular
                                .copyWith(color: MiCutColors.textSubtle)),
                      ],
                      if (child != null) ...[
                        SizedBox(height: gapAfterHeader),
                        child!,
                      ],
                    ]),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: Spacing.s24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.screenH, Spacing.s8, Spacing.screenH, 0),
                child: cta,
              ),
            ),
          ]),
        ),
      );
}

/// 아래 고정 CTA. 시안 높이 57, 반지름 20, 그라데이션 채움.
class AuthCta extends StatelessWidget {
  const AuthCta(
      {super.key,
      required this.label,
      required this.onPressed,
      this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => MiCutButton(
        label: label,
        onPressed: onPressed,
        loading: loading,
        solid: false,
        height: Spacing.primaryButtonHeight,
        radius: Spacing.radius20,
      );
}
