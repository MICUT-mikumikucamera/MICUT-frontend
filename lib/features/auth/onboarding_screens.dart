import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_button.dart';
import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/word_wrap_text.dart';
import '../../core/widgets/miku_illustration.dart';
import 'auth_providers.dart';
import 'nickname_rules.dart';
import 'onboarding_page.dart';
import 'legal_preview_screen.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});
  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(onboardingNicknameProvider));
    _text.addListener(_changed);
  }

  void _changed() {
    ref.read(onboardingNicknameProvider.notifier).state = _text.text;
    setState(() {});
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _composing =>
      _text.value.composing.isValid && !_text.value.composing.isCollapsed;
  void _next() {
    if (!_composing && NicknameRules.isValid(_text.text)) {
      FocusScope.of(context).unfocus();
      context.push(Routes.onboardingTerms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _composing ? null : NicknameRules.error(_text.text);
    final valid = !_composing && NicknameRules.isValid(_text.text);
    return OnboardingPage(
      title: '반가워요! Micut에서 사용하실\n닉네임을 설정해 주세요\u00a0♬',
      description: '닉네임은 2~20자까지 설정이 가능하며, 공백과 이모지는 사용할 수 없어요.',
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.login),
      content:
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: _text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _next(),
            style: MiCutText.body16Regular,
            decoration: InputDecoration(
                labelText: '닉네임',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: MiCutText.body16Regular,
                contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
                hintText: '닉네임을 입력해 주세요',
                hintStyle: MiCutText.body16Regular
                    .copyWith(color: MiCutColors.textSubtle),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: error == null
                            ? MiCutColors.borderDefault
                            : MiCutColors.borderDanger)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: error == null
                            ? MiCutColors.borderDefault
                            : MiCutColors.borderDanger)))),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: valid || error != null
                  ? Semantics(
                      liveRegion: true,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                    valid ? Icons.check_circle : Icons.error,
                                    size: 16,
                                    color: valid
                                        ? MiCutColors.success
                                        : MiCutColors.danger)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(valid ? '사용 가능한 닉네임이에요.' : error!,
                                    style: MiCutText.detail14Regular.copyWith(
                                        color: MiCutColors.textSubtle))),
                          ]))
                  : const SizedBox.shrink()),
          const SizedBox(width: 12),
          Text('${NicknameRules.length(_text.text)}/${NicknameRules.maxLength}',
              style: MiCutText.detail14Regular),
        ]),
      ]),
      action: MiCutButton(
          label: '다음으로',
          solid: false,
          height: Spacing.primaryButtonHeight,
          radius: Spacing.radius20,
          onPressed: valid ? _next : null),
    );
  }
}

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});
  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _terms = false, _privacy = false, _busy = false;
  String? _error;
  VoidCallback? _viewDocument(String address, String title) {
    if (_busy) return null;
    if (ref.read(authPreviewProvider)) {
      return () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => LegalPreviewScreen(title: title)));
    }
    return AuthLegalLinks.validUrl(address) == null
        ? null
        : () => _open(address);
  }

  Future<void> _open(String address) async {
    final uri = AuthLegalLinks.validUrl(address);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        setState(() => _error = '네트워크 연결을 확인해 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 연결을 확인해 주세요.');
    }
  }

  Future<void> _complete() async {
    final nickname = ref.read(onboardingNicknameProvider);
    if (_busy || !_terms || !_privacy) return;
    if (!NicknameRules.isValid(nickname)) {
      context.go(Routes.onboardingNickname);
      return;
    }
    final gateway = ref.read(authGatewayProvider);
    if (gateway == null && !ref.read(authPreviewProvider)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (gateway != null) {
        await gateway.completeOnboarding(
            nickname: nickname,
            termsAccepted: _terms,
            privacyAccepted: _privacy);
      }
      // Preview navigation is ephemeral: no account, token, or legal consent is saved.
      if (mounted) context.go(Routes.home);
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 연결을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(authPreviewProvider);
    final connected = ref.watch(authGatewayProvider) != null;
    final legalReady = AuthLegalLinks.validUrl(AuthLegalLinks.terms) != null &&
        AuthLegalLinks.validUrl(AuthLegalLinks.privacy) != null;
    return PopScope(
        canPop: !_busy,
        child: OnboardingPage(
            title: '다음 이용약관에\n동의해 주세요.',
            contentGap: 80,
            description: 'Micut을 이용하려면 약관 동의가 필요해요.',
            onBack: _busy
                ? null
                : () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.onboardingNickname),
            content: Column(children: [
              _ConsentRow(
                  label: '이용약관에 동의합니다.',
                  value: _terms,
                  onChanged: _busy ? null : (v) => setState(() => _terms = v),
                  onView: _viewDocument(AuthLegalLinks.terms, '이용약관')),
              const SizedBox(height: 12),
              _ConsentRow(
                  label: '개인정보 처리방침 확인',
                  value: _privacy,
                  onChanged: _busy ? null : (v) => setState(() => _privacy = v),
                  onView: _viewDocument(AuthLegalLinks.privacy, '개인정보 처리방침')),
              const SizedBox(height: 12),
              _ConsentRow(
                  label: '전체 동의',
                  value: _terms && _privacy,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            _terms = value;
                            _privacy = value;
                          }),
                  onView: null),
            ]),
            action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.lg),
                        child: Semantics(
                            liveRegion: true,
                            child: Text(_error!,
                                style: MiCutText.body14Regular
                                    .copyWith(color: MiCutColors.danger)))),
                  MiCutButton(
                      label: '동의하고 시작하기',
                      loading: _busy,
                      solid: false,
                      height: Spacing.primaryButtonHeight,
                      radius: Spacing.radius20,
                      onPressed: _terms &&
                              _privacy &&
                              (preview || (connected && legalReady))
                          ? _complete
                          : null),
                ])));
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow(
      {required this.label,
      required this.value,
      required this.onChanged,
      required this.onView});
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onView;
  @override
  Widget build(BuildContext context) => Semantics(
      key: ValueKey('consent-$label'),
      checked: value,
      child: Material(
        color: MiCutColors.bgSubtle,
        borderRadius: BorderRadius.circular(Spacing.radius20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    WordWrapText(label, style: MiCutText.label16Regular),
                    if (label != '전체 동의')
                      TextButton(
                          onPressed: onView,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: MiCutColors.textSubtle,
                            textStyle: MiCutText.detail14Regular
                                .copyWith(decoration: TextDecoration.underline),
                          ),
                          child: const Text('전체보기')),
                  ],
                )),
                const SizedBox(width: 12),
                MiCutIcon.asset('check',
                    size: 20,
                    color:
                        value ? MiCutColors.cyan300 : MiCutColors.iconDisabled),
              ]),
            ),
          ),
        ),
      ));
}

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});
  @override
  Widget build(BuildContext context) => OnboardingPage(
      title: '앗, 다시 로그인이 필요해요!',
      description: '로그인한 뒤 이용을 계속할 수 있어요.',
      content: const Center(child: MikuIllustration(MikuArtwork.empty)),
      action: MiCutButton(
          label: '다시 로그인하기',
          solid: false,
          height: Spacing.primaryButtonHeight,
          radius: Spacing.radius20,
          onPressed: () => context.go(Routes.login)));
}
