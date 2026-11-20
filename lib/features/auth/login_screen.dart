import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/micut_button.dart';
import 'auth_providers.dart';
import '../../core/theme/appearance.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    if (_busy) return;
    final gateway = ref.read(authGatewayProvider);
    if (gateway == null && !ref.read(authPreviewProvider)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final needsOnboarding =
          gateway == null ? true : await gateway.signInWithGoogle();
      if (!mounted) return;
      if (needsOnboarding) {
        context.push(Routes.onboardingNickname);
      } else {
        context.go(Routes.home);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 연결을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(authPreviewProvider) ||
        ref.watch(authGatewayProvider) != null;
    final mode = ref.watch(appearanceProvider);
    final light = mode == ThemeMode.light ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.light);
    return Scaffold(
        body: LayoutBuilder(
            builder: (context, bounds) => Container(
                decoration: BoxDecoration(
                    gradient: RadialGradient(
                        center: const Alignment(0, -.4),
                        radius: 1.3,
                        colors: light
                            ? [
                                MiCutColors.bgDefault,
                                MiCutColors.cyan50,
                                MiCutColors.cyan200
                              ]
                            : [
                                MiCutColors.bgInverse,
                                MiCutColors.bgInverse,
                                MiCutColors.cyan200
                              ],
                        stops: const [.45, .7, 1])),
                child: Stack(children: [
                  Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                          child: Image.asset(
                              'assets/figma-export/login-${light ? 'light' : 'dark'}-mask.png',
                              key: ValueKey(light),
                              width: bounds.maxWidth,
                              height: bounds.maxHeight * .82,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              excludeFromSemantics: true))),
                  SafeArea(
                      child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Spacing.screenH),
                                          child: Column(children: [
                                            SizedBox(
                                                height: (bounds.maxHeight *
                                                            (545 / 844) -
                                                        MediaQuery.paddingOf(
                                                                context)
                                                            .top)
                                                    .clamp(
                                                        0.0, double.infinity)),
                                            const BrandLogo(
                                                variant: BrandLogoVariant.cyan,
                                                height: 40),
                                            const SizedBox(height: 20),
                                            Text('미쿠와 함께 만드는 추억, 미컷',
                                                textAlign: TextAlign.center,
                                                style: MiCutText
                                                    .heading24Semibold
                                                    .copyWith(
                                                        color: light
                                                            ? MiCutColors
                                                                .textDefault
                                                            : MiCutColors
                                                                .textInverse)),
                                            const SizedBox(height: 48),
                                            if (_error != null)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: Spacing.lg),
                                                  child: Semantics(
                                                      liveRegion: true,
                                                      child: Text(_error!,
                                                          style: MiCutText
                                                              .body14Regular
                                                              .copyWith(
                                                                  color: light
                                                                      ? MiCutColors
                                                                          .danger
                                                                      : MiCutColors
                                                                          .textInverse)))),
                                            MiCutButton(
                                                label: 'Google로 시작하기',
                                                type: MiCutButtonType.tertiary,
                                                leading: Image.asset(
                                                    'assets/figma-export/google.png',
                                                    width: 20,
                                                    height: 20,
                                                    excludeFromSemantics: true),
                                                height:
                                                    Spacing.primaryButtonHeight,
                                                radius: Spacing.radius20,
                                                loading: _busy,
                                                onPressed:
                                                    available ? _signIn : null),
                                            const SizedBox(height: 48),
                                          ])))))),
                ]))));
  }
}
