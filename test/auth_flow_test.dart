import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/app/router.dart';
import 'package:micut/data/auth/auth.dart';
import 'package:micut/data/auth/auth_repository.dart';
import 'package:micut/data/auth/fake_auth_repository.dart';
import 'package:micut/data/auth/nickname_validator.dart';
import 'package:micut/data/auth/providers.dart';
import 'package:micut/data/local/local_store.dart';
import 'package:micut/features/auth/nickname_screen.dart';
import 'package:micut/features/auth/terms_screen.dart';

/// 파일을 읽지 않는 메모리 구현. 위젯 테스트는 FakeAsync 라 실제 파일 IO 가 끝나지 않는다.
class _MemoryAuth extends AuthRepository {
  AuthStatus status = AuthStatus.signedOut;
  String? saved;

  @override
  Future<AuthStatus> restore() async => status;

  @override
  Future<AuthStatus> signInWithGoogle() async =>
      status = AuthStatus.needsNickname;

  @override
  Future<NicknameCheck> checkNickname(String nickname) async {
    final local = validateNickname(nickname);
    if (local != null) return NicknameCheck(local);
    if (nickname == '미쿠') return const NicknameCheck(NicknameIssue.taken);
    return const NicknameCheck();
  }

  @override
  Future<AuthStatus> saveNickname(String nickname) async {
    saved = nickname;
    return status = AuthStatus.needsTerms;
  }

  @override
  Future<AuthStatus> agreeTerms() async => status = AuthStatus.signedIn;

  @override
  Future<void> signOut() async => status = AuthStatus.signedOut;

  @override
  Future<String?> nickname() async => saved;
}

Widget _app(Widget home, _MemoryAuth auth) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(home: home),
    );

ElevatedButton _button(WidgetTester tester, String label) =>
    tester.widget(find.widgetWithText(ElevatedButton, label));

void main() {
  group('authRedirect', () {
    String? go(AuthStatus s, String at) => authRedirect(AsyncData(s), at);

    test('상태를 읽는 동안은 부트 화면', () {
      expect(authRedirect(const AsyncLoading(), Routes.home), Routes.boot);
      expect(authRedirect(const AsyncLoading(), Routes.boot), isNull);
    });

    test('로그아웃 상태는 로그인 화면만 열린다', () {
      expect(go(AuthStatus.signedOut, Routes.home), Routes.login);
      expect(go(AuthStatus.signedOut, Routes.settings), Routes.login);
      expect(go(AuthStatus.signedOut, Routes.loginNickname), Routes.login);
      expect(go(AuthStatus.signedOut, Routes.login), isNull);
    });

    test('닉네임 → 약관 순서를 건너뛸 수 없다', () {
      expect(go(AuthStatus.needsNickname, Routes.login), Routes.loginNickname);
      expect(go(AuthStatus.needsNickname, Routes.loginTerms),
          Routes.loginNickname);
      expect(go(AuthStatus.needsNickname, Routes.loginNickname), isNull);
    });

    test('약관 단계에서는 닉네임으로 돌아갈 수 있다', () {
      expect(go(AuthStatus.needsTerms, Routes.home), Routes.loginTerms);
      expect(go(AuthStatus.needsTerms, Routes.loginTerms), isNull);
      expect(go(AuthStatus.needsTerms, Routes.loginNickname), isNull);
    });

    test('세션 만료는 만료 화면으로', () {
      expect(go(AuthStatus.sessionExpired, Routes.home), Routes.loginExpired);
      expect(go(AuthStatus.sessionExpired, Routes.loginExpired), isNull);
    });

    test('로그인 완료면 로그인 화면에서 홈으로, 그 밖은 그대로', () {
      expect(go(AuthStatus.signedIn, Routes.boot), Routes.home);
      expect(go(AuthStatus.signedIn, Routes.login), Routes.home);
      expect(go(AuthStatus.signedIn, Routes.loginTerms), Routes.home);
      expect(go(AuthStatus.signedIn, Routes.settings), isNull);
      expect(go(AuthStatus.signedIn, Routes.captureGuide), isNull);
    });

    test('상태 읽기에 실패하면 로그아웃으로 본다', () {
      expect(authRedirect(AsyncError('x', StackTrace.empty), Routes.home),
          Routes.login);
    });
  });

  group('FakeAuthRepository', () {
    late Directory dir;
    late LocalStore store;
    FakeAuthRepository repo() =>
        FakeAuthRepository(store, latency: Duration.zero);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('micut_auth_test');
      store = LocalStore(directory: dir);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('처음 가입: 로그인 → 닉네임 → 약관 → 완료', () async {
      final r = repo();
      expect(await r.restore(), AuthStatus.signedOut);
      expect(await r.signInWithGoogle(), AuthStatus.needsNickname);
      expect(await r.saveNickname('미쿠미쿠'), AuthStatus.needsTerms);
      expect(await r.agreeTerms(), AuthStatus.signedIn);
    });

    test('중복·규칙 위반 닉네임은 저장할 수 없다', () async {
      final r = repo();
      await r.signInWithGoogle();
      expect((await r.checkNickname('미쿠')).issue, NicknameIssue.taken);
      expect((await r.checkNickname('ADMIN')).issue, NicknameIssue.taken);
      expect((await r.checkNickname('파')).issue, NicknameIssue.tooShort);
      await expectLater(r.saveNickname('미쿠'), throwsArgumentError);
      expect(await r.nickname(), isNull);
    });

    test('로그아웃해도 계정은 남아 다시 로그인하면 바로 홈', () async {
      final r = repo();
      await r.signInWithGoogle();
      await r.saveNickname('미쿠미쿠');
      await r.agreeTerms();
      await r.signOut();
      expect(await r.restore(), AuthStatus.signedOut);
      expect(await r.signInWithGoogle(), AuthStatus.signedIn);
    });

    test('앱을 다시 켜도 상태가 이어진다', () async {
      final first = repo();
      await first.signInWithGoogle();
      await first.saveNickname('미쿠미쿠');
      expect(await repo().restore(), AuthStatus.needsTerms);
      expect(await repo().nickname(), '미쿠미쿠');
    });

    test('세션 만료 후 다시 로그인하면 이전 단계 그대로', () async {
      final r = repo();
      await r.signInWithGoogle();
      await r.saveNickname('미쿠미쿠');
      await r.agreeTerms();
      expect(await r.simulateExpiry(), AuthStatus.sessionExpired);
      expect(await r.signInWithGoogle(), AuthStatus.signedIn);
    });
  });

  group('닉네임 화면', () {
    testWidgets('빈 입력은 안내 없이 다음 버튼이 꺼져 있다', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.pump();
      expect(find.text('0/20'), findsOneWidget);
      expect(_button(tester, '다음으로').onPressed, isNull);
    });

    testWidgets('1자는 바로 에러, 다음 버튼은 꺼진 채', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.enterText(find.byType(TextField), '파');
      await tester.pump();
      expect(find.text('닉네임은 최소 2자로 설정해 주세요.'), findsOneWidget);
      expect(find.text('1/20'), findsOneWidget);
      expect(_button(tester, '다음으로').onPressed, isNull);
    });

    testWidgets('공백·이모지는 에러', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.enterText(find.byType(TextField), '미쿠 미쿠');
      await tester.pump();
      expect(find.text('공백은 사용할 수 없어요.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '미쿠😀');
      await tester.pump();
      expect(find.text('이모지는 사용할 수 없어요.'), findsOneWidget);
    });

    testWidgets('사용 가능하면 확인 뒤 다음 버튼이 켜진다', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.enterText(find.byType(TextField), '미쿠미쿠');
      await tester.pump();
      // 서버 확인이 끝나기 전에는 켜지지 않는다.
      expect(_button(tester, '다음으로').onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('사용 가능한 닉네임이에요.'), findsOneWidget);
      expect(_button(tester, '다음으로').onPressed, isNotNull);
    });

    testWidgets('중복 닉네임은 에러', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.enterText(find.byType(TextField), '미쿠');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
      expect(_button(tester, '다음으로').onPressed, isNull);
    });

    testWidgets('입력이 바뀌면 이전 확인 결과는 버린다', (tester) async {
      await tester.pumpWidget(_app(const NicknameScreen(), _MemoryAuth()));
      await tester.enterText(find.byType(TextField), '미쿠미쿠');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField), '미쿠미쿠미');
      await tester.pump();
      expect(find.text('사용 가능한 닉네임이에요.'), findsNothing);
      expect(_button(tester, '다음으로').onPressed, isNull);
    });
  });

  group('약관 화면', () {
    testWidgets('두 항목을 모두 체크해야 시작할 수 있다', (tester) async {
      await tester.pumpWidget(_app(const TermsScreen(), _MemoryAuth()));
      expect(_button(tester, '동의하고 시작하기').onPressed, isNull);

      await tester.tap(find.text('이용약관에 동의합니다.'));
      await tester.pump();
      expect(_button(tester, '동의하고 시작하기').onPressed, isNull);

      await tester.tap(find.text('개인정보 처리방침 확인'));
      await tester.pump();
      expect(_button(tester, '동의하고 시작하기').onPressed, isNotNull);

      // 다시 누르면 해제된다.
      await tester.tap(find.text('이용약관에 동의합니다.'));
      await tester.pump();
      expect(_button(tester, '동의하고 시작하기').onPressed, isNull);
    });

    testWidgets('전체보기는 체크를 바꾸지 않고 안내를 연다', (tester) async {
      await tester.pumpWidget(_app(const TermsScreen(), _MemoryAuth()));
      await tester.tap(find.text('전체보기').first);
      await tester.pumpAndSettle();
      expect(find.text('문서를 준비하고 있어요.'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(_button(tester, '동의하고 시작하기').onPressed, isNull);
    });
  });

  testWidgets('라우터: 부트 → 로그인 → 구글 → 닉네임으로 이동', (tester) async {
    final auth = _MemoryAuth();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authEnabledProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(auth),
      ],
      child: Consumer(
        builder: (context, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(routerProvider)),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Google로 시작하기'), findsOneWidget);

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('다음으로'), findsOneWidget);
    expect(find.textContaining('닉네임을 설정해 주세요'), findsOneWidget);
  });
}
