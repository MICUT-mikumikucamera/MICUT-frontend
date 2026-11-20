import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:micut/core/widgets/word_wrap_text.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/app/app.dart';

import 'package:micut/browser_preview.dart';
import 'package:micut/core/theme/theme.dart';
import 'package:micut/core/widgets/micut_button.dart';
import 'package:micut/core/widgets/micut_loading.dart';
import 'package:micut/core/widgets/miku_illustration.dart';
import 'package:micut/core/widgets/new_collection_overlay.dart';
import 'package:micut/data/local/local_store.dart';
import 'package:micut/features/auth/auth_providers.dart';
import 'package:micut/features/auth/login_screen.dart';
import 'package:micut/features/auth/nickname_rules.dart';
import 'package:micut/features/auth/onboarding_screens.dart';

Finder consentLabel(String label) =>
    find.byWidgetPredicate((w) => w is WordWrapText && w.text == label);
bool consentChecked(WidgetTester tester, String label) => tester
    .widget<Semantics>(find.byKey(ValueKey('consent-$label')))
    .properties
    .checked!;

void main() {
  testWidgets('onboarding wraps Korean at word boundaries', (tester) async {
    for (final width in [280.0, 335.0, 528.0]) {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(MaterialApp(
            home: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                    width: width,
                    child: MediaQuery(
                        data: MediaQueryData(
                            textScaler: TextScaler.linear(scale)),
                        child: const WordWrapText(
                            '반가워요! Micut에서 사용하실 닉네임을 설정해 주세요 공백과 이모지는',
                            style: TextStyle(fontSize: 24)))))));
        final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
            of: find.byType(WordWrapText), matching: find.byType(RichText)));
        final rendered = paragraph.text.toPlainText();
        for (final word in ['사용하실', '공백과', '닉네임을']) {
          final joined = word.split('').join('\u2060');
          final offset = rendered.indexOf(joined);
          final boxes = paragraph.getBoxesForSelection(TextSelection(
              baseOffset: offset, extentOffset: offset + joined.length));
          expect(boxes.map((box) => box.top).toSet().length, 1,
              reason: '$word at width=$width scale=$scale');
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('login follows device brightness without a timed transition',
      (tester) async {
    final platform = tester.binding.platformDispatcher;
    addTearDown(platform.clearPlatformBrightnessTestValue);
    for (final brightness in [Brightness.light, Brightness.dark]) {
      platform.platformBrightnessTestValue = brightness;
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
              theme: buildMiCutTheme(), home: const LoginScreen())));
      await tester.pump();
      final asset = brightness == Brightness.light
          ? 'assets/figma-export/login-light-mask.png'
          : 'assets/figma-export/login-dark-mask.png';
      Finder artwork() => find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == asset);
      expect(artwork(), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(artwork(), findsOneWidget);
    }
    platform.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(find.byKey(const ValueKey(true)), findsOneWidget);
  });
  test('nickname has consistent 2–20 grapheme boundaries', () {
    expect(NicknameRules.isValid('미'), isFalse);
    expect(NicknameRules.isValid('미쿠'), isTrue);
    expect(NicknameRules.isValid('가' * 20), isTrue);
    expect(NicknameRules.isValid('가' * 21), isFalse);
    expect(NicknameRules.length('e\u0301가'), 2);
    expect(NicknameRules.isValid('e\u0301가'), isTrue);
    expect(NicknameRules.isValid(''), isFalse);
  });
  test('spaces and emoji cannot enter an accepted nickname', () {
    for (final value in [
      '미 쿠',
      ' 미쿠',
      '미쿠\n',
      '미쿠\u3000',
      '미쿠😀',
      '미쿠🇰🇷',
      '미쿠1️⃣',
      '미쿠☀',
      '미쿠👩‍💻',
      '미쿠\u200b'
    ]) {
      expect(NicknameRules.isValid(value), isFalse, reason: value);
    }
  });
  test('legal links require an explicit HTTPS destination', () {
    expect(AuthLegalLinks.validUrl(''), isNull);
    expect(AuthLegalLinks.validUrl('javascript:alert(1)'), isNull);
    expect(AuthLegalLinks.validUrl('https://example.org/terms')?.host,
        'example.org');
  });
  testWidgets(
      'preview onboarding validates, preserves edits, and requires both consents',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authPreviewProvider.overrideWithValue(true),
      localStoreProvider.overrideWithValue(BrowserPreviewStore()),
    ], child: const MiCutApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.byType(NicknameScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '미');
    await tester.pump();
    expect(find.text('닉네임은 최소 2자로 설정해 주세요.'), findsOneWidget);
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '가' * 21);
    await tester.pump();
    expect(find.text('21/20'), findsOneWidget);
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '미쿠미쿠');
    await tester.pump();
    expect(find.text('4/20'), findsOneWidget);
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsScreen), findsOneWidget);
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    await tester.tap(consentLabel('이용약관에 동의합니다.'));
    await tester.pump();
    await tester.tap(find.text('전체보기').first);
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is WordWrapText && w.text == '이용약관'),
        findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (w) => w is WordWrapText && w.text == '디자인 미리보기'),
        findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(consentChecked(tester, '이용약관에 동의합니다.'), isTrue);
    await tester.tap(find.text('전체보기').last);
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (w) => w is WordWrapText && w.text == '개인정보 처리방침'),
        findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '미쿠미쿠');
    await tester.tap(find.text('다음으로'));
    await tester.pumpAndSettle();
    await tester.tap(consentLabel('전체 동의'));
    await tester.pump();
    expect(consentChecked(tester, '이용약관에 동의합니다.'), isTrue);
    expect(consentChecked(tester, '개인정보 처리방침 확인'), isTrue);
    await tester.tap(consentLabel('개인정보 처리방침 확인'));
    await tester.pump();
    expect(consentChecked(tester, '전체 동의'), isFalse);
    await tester.tap(consentLabel('전체 동의'));
    await tester.pump();
    await tester.tap(consentLabel('전체 동의'));
    await tester.pump();
    expect(consentChecked(tester, '이용약관에 동의합니다.'), isFalse);
    expect(consentChecked(tester, '개인정보 처리방침 확인'), isFalse);
    await tester.tap(consentLabel('전체 동의'));
    await tester.pump();
    await tester.tap(find.text('동의하고 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('최근 사진'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unfinished Korean composition never enables submission',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: buildMiCutTheme(), home: const NicknameScreen())));
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '미쿠',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2)));
    await tester.pump();
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '미쿠', selection: TextSelection.collapsed(offset: 2)));
    await tester.pump();
    expect(tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed,
        isNotNull);
  });
  testWidgets('production does not fake Google login', (tester) async {
    await tester.pumpWidget(ProviderScope(
        child:
            MaterialApp(theme: buildMiCutTheme(), home: const LoginScreen())));
    await tester.pumpAndSettle();
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('login failures are recoverable and prevent duplicate submits',
      (tester) async {
    final gateway = _FailingGateway();
    await tester.pumpWidget(ProviderScope(
        overrides: [authGatewayProvider.overrideWithValue(gateway)],
        child:
            MaterialApp(theme: buildMiCutTheme(), home: const LoginScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    expect(
        tester.widget<MiCutButton>(find.byType(MiCutButton)).loading, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
    expect(gateway.attempts, 1);
    expect(tester.widget<MiCutButton>(find.byType(MiCutButton)).onPressed,
        isNotNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('auth screens fit $width with 2x text and keyboard',
        (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in [
        const LoginScreen(),
        const NicknameScreen(),
        const TermsScreen(),
        const SessionExpiredScreen()
      ]) {
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
                theme: buildMiCutTheme(),
                home: MediaQuery(
                    data: MediaQueryData(
                        size: Size(width, 640),
                        textScaler: const TextScaler.linear(2),
                        viewInsets: screen is NicknameScreen
                            ? const EdgeInsets.only(bottom: 260)
                            : EdgeInsets.zero,
                        disableAnimations: true),
                    child: screen))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$screen at $width');
      }
    });
  }
  testWidgets('loading respects reduced motion and collection closes only once',
      (tester) async {
    var closes = 0;
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MiCutLoading())));
    await tester.pumpAndSettle();
    expect(find.byType(MikuIllustration), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
        home: NewCollectionOverlay(
            number: 1, name: '브이', imagePath: null, onClose: () => closes++)));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.text('신규 컬렉션 획득!'));
    await tester.pump(const Duration(seconds: 4));
    expect(closes, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('collection auto dismiss and disposal cancel timer',
      (tester) async {
    var closes = 0;
    await tester.pumpWidget(MaterialApp(
        home: NewCollectionOverlay(
            number: 1, name: '브이', imagePath: null, onClose: () => closes++)));
    await tester.pump(const Duration(seconds: 3));
    expect(closes, 1);
    await tester.pumpWidget(MaterialApp(
        home: NewCollectionOverlay(
            key: const ValueKey('new'),
            number: 2,
            name: '브이',
            imagePath: null,
            onClose: () => closes++)));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(closes, 1);
  });
}

class _FailingGateway implements AuthGateway {
  int attempts = 0;
  @override
  Future<bool> signInWithGoogle() async {
    attempts++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    throw StateError('offline');
  }

  @override
  Future<void> completeOnboarding(
      {required String nickname,
      required bool termsAccepted,
      required bool privacyAccepted}) async {}
}
