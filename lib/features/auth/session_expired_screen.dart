import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spacing.dart';
import '../../core/widgets/micut_button.dart';
import '../../core/widgets/miku_illust.dart';
import '../../data/auth/providers.dart';
import 'auth_scaffold.dart';

/// 00-3 세션 만료. Figma 402:2596.
// TODO(디자인): 뒤로 가기 화살표의 동작이 정해지지 않았다. 지금은 로그아웃하고 00 로그인으로.
class SessionExpiredScreen extends ConsumerStatefulWidget {
  const SessionExpiredScreen({super.key});

  @override
  ConsumerState<SessionExpiredScreen> createState() =>
      _SessionExpiredScreenState();
}

class _SessionExpiredScreenState extends ConsumerState<SessionExpiredScreen> {
  bool _loading = false;

  Future<void> _signInAgain() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: '앗, 다시 로그인이 필요해요!',
        subtitle: '로그인한 뒤 이용을 계속할 수 있어요.',
        onBack: () => ref.read(authControllerProvider.notifier).signOut(),
        gapAfterHeader: Spacing.s32,
        cta: MiCutButton(
          label: '다시 로그인하기',
          type: MiCutButtonType.tertiary,
          height: Spacing.primaryButtonHeight,
          radius: Spacing.radius20,
          loading: _loading,
          onPressed: _signInAgain,
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: Spacing.s32),
            child: MikuIllustImage(MikuIllust.empty, size: 205),
          ),
        ),
      );
}
