import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_store.dart';
import 'auth.dart';
import 'auth_repository.dart';
import 'fake_auth_repository.dart';

/// 로그인 화면 흐름은 빌드할 때 켠다. 기본은 꺼짐이라 지금 배포하는 APK 는 바뀌지 않는다.
///
///   flutter build apk --release --dart-define=AUTH_ENABLED=true
///
/// 백엔드 로그인 계약이 나오면 [authRepositoryProvider] 에서 실제 구현으로 바꾼다.
const bool kAuthEnabled = bool.fromEnvironment('AUTH_ENABLED');

final authEnabledProvider = Provider<bool>((_) => kAuthEnabled);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FakeAuthRepository(ref.watch(localStoreProvider)),
);

/// 현재 로그인 단계. 라우터가 이 값으로 화면을 보낸다.
class AuthController extends AsyncNotifier<AuthStatus> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthStatus> build() => _repo.restore();

  Future<void> _set(Future<AuthStatus> next) async {
    state = AsyncData(await next);
  }

  Future<void> signInWithGoogle() => _set(_repo.signInWithGoogle());

  Future<void> saveNickname(String nickname) =>
      _set(_repo.saveNickname(nickname));

  Future<void> agreeTerms() => _set(_repo.agreeTerms());

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(AuthStatus.signedOut);
  }

  /// 서버가 401 을 주면 부른다. 화면은 세션 만료 안내로 간다.
  void sessionExpired() => state = const AsyncData(AuthStatus.sessionExpired);

  Future<void> simulateExpiry() => _set(_repo.simulateExpiry());
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthStatus>(AuthController.new);

final nicknameProvider = FutureProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).nickname(),
);
