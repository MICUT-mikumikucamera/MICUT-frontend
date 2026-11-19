import '../local/local_store.dart';
import 'auth.dart';
import 'auth_repository.dart';
import 'nickname_validator.dart';

/// 서버 없이 로그인 화면 흐름을 돌리기 위한 가짜 구현.
///
/// 계정은 하나뿐이고 구글 로그인 버튼을 누르면 바로 그 계정으로 들어간다.
/// 로그아웃해도 닉네임·약관 동의는 남겨 두어, 다시 로그인하면 바로 홈으로 간다
/// (서버 계정이 남아 있는 상황과 같다). 앱 데이터를 지우면 처음부터 다시 한다.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this._store,
      {this.latency = const Duration(milliseconds: 400)});

  final LocalStore _store;
  final Duration latency;

  /// 중복으로 취급하는 닉네임.
  static const takenNicknames = {'관리자', '운영자', 'admin', 'micut', '미컷', '미쿠'};

  bool _signedIn = false;
  bool _expired = false;
  String? _nickname;
  bool _termsAgreed = false;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final saved = await _store.loadAuthState();
    _signedIn = saved?['signed_in'] as bool? ?? false;
    _nickname = saved?['nickname'] as String?;
    _termsAgreed = saved?['terms_agreed'] as bool? ?? false;
    _loaded = true;
  }

  Future<void> _save() => _store.saveAuthState({
        'signed_in': _signedIn,
        if (_nickname != null) 'nickname': _nickname,
        'terms_agreed': _termsAgreed,
      });

  AuthStatus get _status {
    if (_expired) return AuthStatus.sessionExpired;
    if (!_signedIn) return AuthStatus.signedOut;
    if (_nickname == null) return AuthStatus.needsNickname;
    if (!_termsAgreed) return AuthStatus.needsTerms;
    return AuthStatus.signedIn;
  }

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<AuthStatus> restore() async {
    await _load();
    return _status;
  }

  @override
  Future<AuthStatus> signInWithGoogle() async {
    await _load();
    await _wait();
    _signedIn = true;
    _expired = false;
    await _save();
    return _status;
  }

  @override
  Future<NicknameCheck> checkNickname(String nickname) async {
    await _wait();
    final local = validateNickname(nickname);
    if (local != null) return NicknameCheck(local);
    if (takenNicknames.contains(nickname.toLowerCase())) {
      return const NicknameCheck(NicknameIssue.taken);
    }
    return const NicknameCheck();
  }

  @override
  Future<AuthStatus> saveNickname(String nickname) async {
    final check = await checkNickname(nickname);
    if (!check.available) {
      throw ArgumentError('사용할 수 없는 닉네임: ${check.issue}');
    }
    _nickname = nickname;
    await _save();
    return _status;
  }

  @override
  Future<AuthStatus> agreeTerms() async {
    await _wait();
    _termsAgreed = true;
    await _save();
    return _status;
  }

  @override
  Future<void> signOut() async {
    await _load();
    _signedIn = false;
    _expired = false;
    await _save();
  }

  @override
  Future<String?> nickname() async {
    await _load();
    return _nickname;
  }

  @override
  bool get canSimulateExpiry => true;

  @override
  Future<AuthStatus> simulateExpiry() async {
    _expired = true;
    return _status;
  }
}
