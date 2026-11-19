import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/auth/providers.dart';

/// 00 로그인. Figma 402:1403 (어두운 버전).
// TODO(디자인): 로그인 시안이 어두운 것(402:1403)과 밝은 것(402:2500) 두 가지다. 확정 전 어두운 쪽.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 다음 화면 이동은 라우터가 로그인 단계를 보고 정한다.
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (_) {
      if (mounted) setState(() => _error = '로그인하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: MiCutColors.darkBg,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: MiCutGradients.login),
          child: Stack(children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ExcludeSemantics(
                child: Image(
                  image: AssetImage('assets/figma-export/login-hero.png'),
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: Spacing.s32),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.screenH),
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const BrandLogo(variant: BrandLogoVariant.cyan, height: 40),
                  const SizedBox(height: Spacing.s20),
                  Text('미쿠와 함께 만드는 추억, 미컷',
                      textAlign: TextAlign.center,
                      style: MiCutText.heading24Semibold
                          .copyWith(color: MiCutColors.textInverse)),
                  const SizedBox(height: Spacing.s32),
                  if (_error != null) ...[
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: MiCutText.detail14Regular
                            .copyWith(color: MiCutColors.darkTextDim)),
                    const SizedBox(height: Spacing.s12),
                  ],
                  MiCutButton(
                    label: 'Google로 시작하기',
                    type: MiCutButtonType.tertiary,
                    height: Spacing.primaryButtonHeight,
                    radius: Spacing.radius20,
                    loading: _loading,
                    leading: const _GoogleMark(),
                    onPressed: _signIn,
                  ),
                  const SizedBox(height: Spacing.s32),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: Image(
          image: AssetImage('assets/figma-export/google-g.png'),
          width: Spacing.s24,
          height: Spacing.s24,
          filterQuality: FilterQuality.high,
        ),
      );
}
