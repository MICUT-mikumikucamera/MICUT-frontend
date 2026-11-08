import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/colors.dart';
import 'package:micut/core/theme/spacing.dart';
import 'package:micut/core/theme/typography.dart';

void main() {
  test(
    'text roles retain the documented body exceptions and percentage tracking',
    () {
      for (final style in [MiCutText.body24Regular, MiCutText.body20Semibold]) {
        expect(style.height, 1.4);
      }
      for (final style in [
        MiCutText.body18Medium,
        MiCutText.body16Regular,
        MiCutText.body14Semibold,
      ]) {
        expect(style.height, 1.5);
      }
      for (final style in [
        MiCutText.heading24Semibold,
        MiCutText.body20Medium,
        MiCutText.label11Regular,
        MiCutText.detail10Regular,
      ]) {
        expect(style.fontFamily, 'Pretendard');
        expect(style.letterSpacing, closeTo(style.fontSize! * -0.02, 0.0001));
      }
      expect(MiCutText.label11Regular.fontWeight, FontWeight.w400);
      expect(MiCutText.h1, MiCutText.heading24Semibold);
      expect(MiCutText.body, MiCutText.body16Regular);
    },
  );

  test('neutral semantics distinguish text, icon and disabled backgrounds', () {
    expect(MiCutColors.bgDefault, const Color(0xFFFEFEFE));
    expect(MiCutColors.bgInverse, const Color(0xFF09090B));
    expect(MiCutColors.bgDisabled, const Color(0xFFE4E4E7));
    expect(MiCutColors.bgPlaceholder, const Color(0xFF52525B));
    expect(MiCutColors.textSubtle, const Color(0xFF71717A));
    expect(MiCutColors.iconSubtle, const Color(0xFFD4D4D8));
    expect(MiCutColors.textSubtle, isNot(MiCutColors.iconSubtle));
    expect(MiCutColors.textDisabled, const Color(0xFFA1A1AA));
    expect(MiCutColors.borderDefault, MiCutColors.gray500);
    expect(MiCutColors.borderSubtle, MiCutColors.gray200);
    expect(MiCutColors.background, MiCutColors.bgDefault);
    expect(MiCutColors.placeholder, MiCutColors.bgPlaceholder);
  });

  test(
    'default layout and component gaps use the supplied spacing primitives',
    () {
      expect(Spacing.screenH, 20);
      expect(Spacing.contentGap, 20);
      expect(Spacing.modalPadding, 20);
      expect(Spacing.modalGap, 16);
      expect(Spacing.ctaGap, 8);
      expect(Spacing.cardGap, 8);
      expect(Spacing.tabLabelGap, 4);
      expect([
        Spacing.radiusSm,
        Spacing.radiusMd,
        Spacing.radiusLg,
        Spacing.radiusXl,
      ], everyElement(isIn([10.0, 12.0, 16.0, 20.0, 24.0])));
    },
  );
}
