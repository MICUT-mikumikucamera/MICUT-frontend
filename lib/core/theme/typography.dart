import 'package:flutter/material.dart';
import 'colors.dart';

/// Role-based Text Styles from docs/design-system.md.
abstract final class MiCutText {
  static const family = 'Pretendard';

  static TextStyle _style(double size, FontWeight weight,
          {double height = 1.4}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: size * -0.02,
        color: MiCutColors.textDefault,
        leadingDistribution: TextLeadingDistribution.even,
      );
  static final heading24Semibold = _style(24, FontWeight.w600);
  static final heading24Medium = _style(24, FontWeight.w500);
  static final heading24Regular = _style(24, FontWeight.w400);
  static final heading20Semibold = _style(20, FontWeight.w600);
  static final heading20Medium = _style(20, FontWeight.w500);
  static final heading20Regular = _style(20, FontWeight.w400);
  static final heading18Semibold = _style(18, FontWeight.w600);
  static final heading18Medium = _style(18, FontWeight.w500);
  static final heading18Regular = _style(18, FontWeight.w400);
  static final heading16Semibold = _style(16, FontWeight.w600);
  static final heading16Medium = _style(16, FontWeight.w500);
  static final heading16Regular = _style(16, FontWeight.w400);
  static final heading14Semibold = _style(14, FontWeight.w600);
  static final heading14Medium = _style(14, FontWeight.w500);
  static final heading14Regular = _style(14, FontWeight.w400);
  static final heading12Semibold = _style(12, FontWeight.w600);
  static final heading12Medium = _style(12, FontWeight.w500);
  static final heading12Regular = _style(12, FontWeight.w400);
  static final body24Semibold = _style(24, FontWeight.w600);
  static final body24Medium = _style(24, FontWeight.w500);
  static final body24Regular = _style(24, FontWeight.w400);
  static final body20Semibold = _style(20, FontWeight.w600);
  static final body20Medium = _style(20, FontWeight.w500);
  static final body20Regular = _style(20, FontWeight.w400);
  static final body18Semibold = _style(18, FontWeight.w600, height: 1.5);
  static final body18Medium = _style(18, FontWeight.w500, height: 1.5);
  static final body18Regular = _style(18, FontWeight.w400, height: 1.5);
  static final body16Semibold = _style(16, FontWeight.w600, height: 1.5);
  static final body16Medium = _style(16, FontWeight.w500, height: 1.5);
  static final body16Regular = _style(16, FontWeight.w400, height: 1.5);
  static final body14Semibold = _style(14, FontWeight.w600, height: 1.5);
  static final body14Medium = _style(14, FontWeight.w500, height: 1.5);
  static final body14Regular = _style(14, FontWeight.w400, height: 1.5);
  static final label18Semibold = _style(18, FontWeight.w600);
  static final label18Medium = _style(18, FontWeight.w500);
  static final label18Regular = _style(18, FontWeight.w400);
  static final label16Semibold = _style(16, FontWeight.w600);
  static final label16Medium = _style(16, FontWeight.w500);
  static final label16Regular = _style(16, FontWeight.w400);
  static final label14Semibold = _style(14, FontWeight.w600);
  static final label14Medium = _style(14, FontWeight.w500);
  static final label14Regular = _style(14, FontWeight.w400);
  static final label12Semibold = _style(12, FontWeight.w600);
  static final label12Medium = _style(12, FontWeight.w500);
  static final label12Regular = _style(12, FontWeight.w400);
  static final label10Semibold = _style(10, FontWeight.w600);
  static final label10Medium = _style(10, FontWeight.w500);
  static final label10Regular = _style(10, FontWeight.w400);
  static final detail14Semibold = _style(14, FontWeight.w600);
  static final detail14Medium = _style(14, FontWeight.w500);
  static final detail14Regular = _style(14, FontWeight.w400);
  static final detail12Semibold = _style(12, FontWeight.w600);
  static final detail12Medium = _style(12, FontWeight.w500);
  static final detail12Regular = _style(12, FontWeight.w400);
  static final detail10Semibold = _style(10, FontWeight.w600);
  static final detail10Medium = _style(10, FontWeight.w500);
  static final detail10Regular = _style(10, FontWeight.w400);
  static final label11Regular = _style(11, FontWeight.w400);
  static final label11Semibold = _style(11, FontWeight.w600);
  static final h1 = heading24Semibold;
  static final h2 = heading20Semibold;
  static final h3 = heading18Semibold;
  static final body = body16Regular;
  static final bodyBold = body18Semibold;
  static final caption =
      detail12Regular.copyWith(color: MiCutColors.textSubtle);
  static final label = label11Regular.copyWith(color: MiCutColors.textSubtle);
  static final button = label18Semibold;

  static final cardLabel = heading18Semibold;
  static final cardBody = body16Regular;
  static final cardDate = body16Regular.copyWith(height: 18 / 16);
  // General display; acquisition uses the bundled DungGeunMo explicitly.
  // This is not the design system's display/36-dunggeunmo style.
  static final display = _style(32, FontWeight.w700);
  static final hud = label11Regular.copyWith(color: MiCutColors.hud);
}
