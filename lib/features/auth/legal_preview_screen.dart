import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_button.dart';
import 'onboarding_page.dart';

/// Presentation only: no legal document or consent is created here.
class LegalPreviewScreen extends StatelessWidget {
  const LegalPreviewScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => OnboardingPage(
        title: title,
        description: '디자인 미리보기',
        onBack: () => Navigator.of(context).pop(),
        content: Container(
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: MiCutColors.bgSubtle,
            borderRadius: BorderRadius.circular(Spacing.radius20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined,
                  size: 32, color: MiCutColors.primaryStrong),
              const SizedBox(height: Spacing.xl),
              Text('본문을 준비하고 있어요.', style: MiCutText.heading20Semibold),
              const SizedBox(height: Spacing.lg),
              Text(
                  '실제 문서가 연결되면 이곳에서 확인할 수 있어요.\n'
                  '지금은 화면 디자인만 확인할 수 있으며, 동의 내용은 저장되지 않아요.',
                  style: MiCutText.body16Regular
                      .copyWith(color: MiCutColors.textSubtle)),
            ],
          ),
        ),
        action: MiCutButton(
          label: '확인',
          height: Spacing.primaryButtonHeight,
          radius: Spacing.radius20,
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
}
