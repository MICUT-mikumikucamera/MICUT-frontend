import 'package:characters/characters.dart';

/// Count user-perceived characters, including composed Korean input.
abstract final class NicknameRules {
  static const minLength = 2;
  static const maxLength = 20;
  static int length(String value) => value.characters.length;
  static String? error(String value) {
    if (value.isEmpty) return null;
    if (RegExp(r'\s', unicode: true).hasMatch(value) ||
        value.runes.any(
            (r) => r == 0x200b || r == 0x200c || r == 0x200d || r == 0xfeff)) {
      return '공백과 이모지는 사용할 수 없어요.';
    }
    if (value.runes.any((r) =>
        (r >= 0x1f000 && r <= 0x1faff) ||
        (r >= 0x2600 && r <= 0x27bf) ||
        (r >= 0x2300 && r <= 0x23ff) ||
        (r >= 0x2b00 && r <= 0x2bff) ||
        r == 0xfe0f ||
        r == 0x20e3 ||
        r == 0x00a9 ||
        r == 0x00ae ||
        r == 0x203c ||
        r == 0x2049 ||
        r == 0x2122 ||
        r == 0x2139 ||
        r == 0x3030 ||
        r == 0x303d ||
        r == 0x3297 ||
        r == 0x3299)) {
      return '공백과 이모지는 사용할 수 없어요.';
    }
    if (length(value) < minLength) return '닉네임은 최소 2자로 설정해 주세요.';
    if (length(value) > maxLength) return '닉네임은 최대 20자로 설정해 주세요.';
    return null;
  }

  static bool isValid(String value) => value.isNotEmpty && error(value) == null;
}
