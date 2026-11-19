import 'auth.dart';

/// 로그인 계약. 백엔드가 OAuth 를 맡고 앱은 결과 상태만 받는다.
///
/// 실제 구현([ApiAuthRepository])은 백엔드 계약이 나온 뒤에 만든다.
/// 그 전에는 [FakeAuthRepository] 로 화면 흐름만 돈다.
abstract class AuthRepository {
  /// 앱을 켤 때 저장된 세션을 읽어 현재 단계를 돌려준다.
  Future<AuthStatus> restore();

  /// 구글 로그인. 처음이면 [AuthStatus.needsNickname], 이미 가입했으면 [AuthStatus.signedIn].
  Future<AuthStatus> signInWithGoogle();

  /// 사용 가능한 닉네임인지(중복 포함) 묻는다.
  Future<NicknameCheck> checkNickname(String nickname);

  Future<AuthStatus> saveNickname(String nickname);

  Future<AuthStatus> agreeTerms();

  Future<void> signOut();

  /// 지금 저장된 닉네임. 없으면 null.
  Future<String?> nickname();

  /// Fake 에서만 true. 세션 만료 화면을 기기에서 보기 위한 스위치.
  bool get canSimulateExpiry => false;

  Future<AuthStatus> simulateExpiry() =>
      throw UnsupportedError('세션 만료 시뮬레이션은 Fake 에서만 쓸 수 있어요.');
}
