import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_dialog.dart';
import '../../data/auth/providers.dart';
import 'auth_scaffold.dart';

/// 00-2 이용약관 동의 (미동의 / 완료). Figma 402:2542 · 2569.
///
/// 두 항목을 모두 체크해야 "동의하고 시작하기"가 켜진다.
// TODO(디자인): "전체보기"가 무엇을 여는지(앱 안 화면인지, 웹 페이지인지) 정해지지 않았다.
// 약관 문서가 생기기 전까지는 준비 중 안내만 보여 준다.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _saving = false;

  Future<void> _start() async {
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).agreeTerms();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showDocument(String title) => showDialog<void>(
        context: context,
        barrierColor: MiCutColors.modalDim,
        useSafeArea: false,
        builder: (ctx) => MiCutDialog(
          title: title,
          message: '문서를 준비하고 있어요.',
          confirmLabel: '확인',
          onConfirm: () => Navigator.pop(ctx),
        ),
      );

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: '다음 이용약관에\n동의해 주세요.',
        subtitle: 'Micut을 이용하려면 약관 동의가 필요해요.',
        gapAfterHeader: 80,
        // 닉네임 단계로 돌아간다. 로그인 단계 상태는 그대로 두고 화면만 옮긴다.
        onBack: () => context.go(Routes.loginNickname),
        cta: AuthCta(
          label: '동의하고 시작하기',
          loading: _saving,
          onPressed: _terms && _privacy ? _start : null,
        ),
        child: Column(children: [
          _AgreementRow(
            label: '이용약관에 동의합니다.',
            checked: _terms,
            onChanged: (v) => setState(() => _terms = v),
            onViewAll: () => _showDocument('이용약관'),
          ),
          const SizedBox(height: Spacing.md),
          _AgreementRow(
            label: '개인정보 처리방침 확인',
            checked: _privacy,
            onChanged: (v) => setState(() => _privacy = v),
            onViewAll: () => _showDocument('개인정보 처리방침'),
          ),
        ]),
      );
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.onViewAll,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Material(
        color: MiCutColors.bgSubtle,
        borderRadius: BorderRadius.circular(Spacing.radius20),
        child: InkWell(
          borderRadius: BorderRadius.circular(Spacing.radius20),
          onTap: () => onChanged(!checked),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(children: [
              Expanded(
                child: Row(children: [
                  Flexible(
                    child: Text(label, style: MiCutText.label16Medium),
                  ),
                  const SizedBox(width: Spacing.md),
                  // 행 전체를 누르면 체크가 토글되므로 "전체보기"만 따로 눌린다.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onViewAll,
                    child: Text('전체보기',
                        style: MiCutText.detail14Regular
                            .copyWith(color: MiCutColors.textSubtle)),
                  ),
                ]),
              ),
              Semantics(
                checked: checked,
                label: label,
                child: Icon(Icons.check,
                    size: 20,
                    color: checked
                        ? MiCutColors.cyan300
                        : MiCutColors.iconDisabled),
              ),
            ]),
          ),
        ),
      );
}
