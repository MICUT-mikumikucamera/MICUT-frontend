import 'package:flutter/widgets.dart';

import 'auth.dart';

final _emoji = RegExp(
  '[\u{1F000}-\u{1FAFF}\u{2190}-\u{21FF}\u{2300}-\u{23FF}'
  '\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{20E3}]',
  unicode: true,
);
final _whitespace = RegExp(r'\s', unicode: true);

/// 서버에 묻지 않고 기기에서 확인할 수 있는 규칙만 본다. 중복은 서버가 판단한다.
///
/// 길이는 보이는 글자(grapheme) 수로 센다. 빈 입력은 [NicknameIssue.tooShort] 이므로,
/// 비어 있을 때 에러 문구를 숨기는 것은 화면이 정한다.
NicknameIssue? validateNickname(String input) {
  if (_whitespace.hasMatch(input)) return NicknameIssue.hasWhitespace;
  if (_emoji.hasMatch(input)) return NicknameIssue.hasEmoji;
  final length = input.characters.length;
  if (length < nicknameMinLength) return NicknameIssue.tooShort;
  if (length > nicknameMaxLength) return NicknameIssue.tooLong;
  return null;
}
