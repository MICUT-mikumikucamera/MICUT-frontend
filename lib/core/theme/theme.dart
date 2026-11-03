import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// 라이트 월드 테마 (앱 기본).
ThemeData buildMiCutTheme() {
  const scheme = ColorScheme.light(
    primary: MiCutColors.primary,
    onPrimary: MiCutColors.onPrimary,
    primaryContainer: MiCutColors.primarySoft,
    onPrimaryContainer: MiCutColors.primaryStrong,
    secondary: MiCutColors.secondary,
    onSecondary: MiCutColors.white,
    secondaryContainer: MiCutColors.secondarySoft,
    onSecondaryContainer: MiCutColors.onSecondarySoft,
    surface: MiCutColors.background,
    onSurface: MiCutColors.textPrimary,
    error: MiCutColors.danger,
    onError: MiCutColors.white,
    outline: MiCutColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: MiCutText.family,
    scaffoldBackgroundColor: MiCutColors.background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: MiCutColors.background,
      foregroundColor: MiCutColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: MiCutText.h3,
    ),
    textTheme: TextTheme(
      displaySmall: MiCutText.display,
      headlineLarge: MiCutText.h1,
      headlineMedium: MiCutText.h2,
      titleMedium: MiCutText.h3,
      bodyMedium: MiCutText.body,
      bodySmall: MiCutText.caption,
      labelSmall: MiCutText.label,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MiCutColors.primaryStrong,
        textStyle: MiCutText.bodyBold,
      ),
    ),
    dividerTheme: const DividerThemeData(color: MiCutColors.border, space: 1),
    listTileTheme: ListTileThemeData(
      titleTextStyle: MiCutText.body,
      iconColor: MiCutColors.textSecondary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MiCutColors.background,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: MiCutText.h3,
      contentTextStyle: MiCutText.caption,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MiCutColors.ink,
      contentTextStyle: MiCutText.body.copyWith(color: MiCutColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusSm),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MiCutColors.primary,
    ),
  );
}

/// 다크 월드 테마. 촬영 가이드·카메라·처리 중 화면을 `Theme(data: buildMiCutDarkTheme(), child: ...)`
/// 로 감싸서 쓴다. 로고(순흑 + #00FAFC)와 같은 세계.
ThemeData buildMiCutDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: MiCutColors.hud,
    onPrimary: MiCutColors.ink,
    secondary: MiCutColors.brandPink,
    onSecondary: MiCutColors.white,
    surface: MiCutColors.darkBg,
    onSurface: MiCutColors.darkText,
    error: MiCutColors.pink300,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: MiCutText.family,
    scaffoldBackgroundColor: MiCutColors.darkBg,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MiCutColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: MiCutText.h3.copyWith(color: MiCutColors.darkText),
    ),
    iconTheme: const IconThemeData(color: MiCutColors.darkText),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MiCutColors.darkSurfaceHi,
      contentTextStyle: MiCutText.body.copyWith(color: MiCutColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusSm),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MiCutColors.hud,
    ),
  );
}
