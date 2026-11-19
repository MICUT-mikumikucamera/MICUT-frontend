/// 앱이 지금 어느 로그인 단계에 있는지.
///
/// 순서: signedOut → needsNickname → needsTerms → signedIn.
/// 서버 세션이 끊기면 어느 단계에서든 sessionExpired.
enum AuthStatus {
  signedOut,
  needsNickname,
  needsTerms,
  signedIn,
  sessionExpired
}

/// 닉네임이 쓸 수 없는 이유. 규칙은 Figma 00-1 안내문 기준
/// ("2~20자, 공백과 이모지는 사용할 수 없어요").
enum NicknameIssue { tooShort, tooLong, hasWhitespace, hasEmoji, taken }

/// 닉네임 검사 결과. [issue] 가 null 이면 사용 가능.
class NicknameCheck {
  const NicknameCheck([this.issue]);
  final NicknameIssue? issue;
  bool get available => issue == null;
}

const nicknameMinLength = 2;
const nicknameMaxLength = 20;
