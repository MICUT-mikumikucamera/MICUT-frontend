import 'package:flutter_test/flutter_test.dart';
import 'package:micut/data/auth/auth.dart';
import 'package:micut/data/auth/nickname_validator.dart';

void main() {
  group('validateNickname', () {
    test('2~20자는 통과', () {
      expect(validateNickname('미쿠'), isNull);
      expect(validateNickname('미쿠미쿠'), isNull);
      expect(validateNickname('a' * 20), isNull);
    });

    test('1자 이하는 tooShort', () {
      expect(validateNickname(''), NicknameIssue.tooShort);
      expect(validateNickname('파'), NicknameIssue.tooShort);
    });

    test('21자 이상은 tooLong', () {
      expect(validateNickname('a' * 21), NicknameIssue.tooLong);
    });

    test('공백은 위치와 종류에 상관없이 거절', () {
      expect(validateNickname('미쿠 미쿠'), NicknameIssue.hasWhitespace);
      expect(validateNickname(' 미쿠'), NicknameIssue.hasWhitespace);
      expect(validateNickname('미쿠\t'), NicknameIssue.hasWhitespace);
      expect(validateNickname('미쿠　미쿠'), NicknameIssue.hasWhitespace);
    });

    test('이모지는 거절', () {
      expect(validateNickname('미쿠😀'), NicknameIssue.hasEmoji);
      expect(validateNickname('미쿠❤'), NicknameIssue.hasEmoji);
      expect(validateNickname('미쿠❤️'), NicknameIssue.hasEmoji);
      expect(validateNickname('미쿠👨‍👩‍👧'), NicknameIssue.hasEmoji);
      expect(validateNickname('미쿠🇰🇷'), NicknameIssue.hasEmoji);
      expect(validateNickname('미쿠1️⃣'), NicknameIssue.hasEmoji);
    });

    test('한글·영문·숫자·일반 기호는 허용', () {
      expect(validateNickname('Miku39'), isNull);
      expect(validateNickname('미쿠_미쿠'), isNull);
      expect(validateNickname('ミクミク'), isNull);
    });

    test('길이는 UTF-16 길이가 아니라 보이는 글자 수로 센다', () {
      // 결합 문자: "e" + 악센트 = 1글자
      expect(validateNickname('é'), NicknameIssue.tooShort);
      expect(validateNickname('é' * 20), isNull);
      expect(validateNickname('é' * 21), NicknameIssue.tooLong);
    });
  });
}
