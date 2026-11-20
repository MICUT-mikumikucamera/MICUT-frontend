import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Runtime adapter for the semantic colors and role-based text styles.
ThemeData buildMiCutTheme() {
  const scheme = ColorScheme.light(
    primary: MiCutColors.primary,
    onPrimary: MiCutColors.onPrimary,
    primaryContainer: MiCutColors.primarySoft,
    onPrimaryContainer: MiCutColors.primaryStrong,
    secondary: MiCutColors.secondary,
    onSecondary: MiCutColors.textInverse,
    secondaryContainer: MiCutColors.secondarySoft,
    onSecondaryContainer: MiCutColors.onSecondarySoft,
    surface: MiCutColors.bgDefault,
    onSurface: MiCutColors.textDefault,
    error: MiCutColors.bgDangerDefault,
    onError: MiCutColors.onDanger,
    outline: MiCutColors.borderDefault,
    outlineVariant: MiCutColors.borderSubtle,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: MiCutText.family,
    scaffoldBackgroundColor: MiCutColors.bgDefault,
    disabledColor: MiCutColors.textDisabled,
    iconTheme: const IconThemeData(color: MiCutColors.iconDefault),
    appBarTheme: AppBarTheme(
      backgroundColor: MiCutColors.bgDefault,
      foregroundColor: MiCutColors.textDefault,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 51,
      titleSpacing: Spacing.screenH,
      centerTitle: true,
      titleTextStyle: MiCutText.heading20Semibold,
    ),
    textTheme: TextTheme(
      displaySmall: MiCutText.display,
      headlineLarge: MiCutText.heading24Semibold,
      headlineMedium: MiCutText.heading20Semibold,
      titleLarge: MiCutText.heading20Semibold,
      titleMedium: MiCutText.heading18Semibold,
      titleSmall: MiCutText.heading16Semibold,
      bodyLarge: MiCutText.body18Regular,
      bodyMedium: MiCutText.body16Regular,
      bodySmall: MiCutText.body14Regular,
      labelLarge: MiCutText.label16Semibold,
      labelMedium: MiCutText.label12Medium,
      labelSmall: MiCutText.label11Regular,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MiCutColors.textDefault,
        textStyle: MiCutText.label16Semibold,
      ),
    ),
    dividerTheme:
        const DividerThemeData(color: MiCutColors.borderSubtle, space: 1),
    listTileTheme: ListTileThemeData(
      titleTextStyle: MiCutText.body16Regular,
      subtitleTextStyle:
          MiCutText.detail12Regular.copyWith(color: MiCutColors.textSubtle),
      iconColor: MiCutColors.iconDefault,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MiCutColors.bgDefault,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: MiCutText.heading20Semibold,
      contentTextStyle: MiCutText.body14Regular,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radius16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MiCutColors.bgInverse,
      contentTextStyle:
          MiCutText.body14Regular.copyWith(color: MiCutColors.textInverse),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radius10),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: MiCutColors.primary),
  );
}

/// Used by camera chrome and the collection, not confirmation/info footers.
ThemeData buildMiCutDarkTheme() {
  final light = buildMiCutTheme();
  const scheme = ColorScheme.dark(
    primary: MiCutColors.primary,
    onPrimary: MiCutColors.onPrimary,
    secondary: MiCutColors.secondary,
    onSecondary: MiCutColors.textInverse,
    surface: MiCutColors.bgInverse,
    onSurface: MiCutColors.textInverse,
    error: MiCutColors.bgDangerDefault,
    onError: MiCutColors.onDanger,
    outline: MiCutColors.borderDefault,
    outlineVariant: MiCutColors.borderBolder,
  );
  return light.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: MiCutColors.bgInverse,
    textTheme: light.textTheme.apply(
        bodyColor: MiCutColors.textInverse,
        displayColor: MiCutColors.textInverse),
    appBarTheme: light.appBarTheme.copyWith(
      backgroundColor: MiCutColors.bgInverse,
      foregroundColor: MiCutColors.textInverse,
      titleTextStyle:
          MiCutText.heading18Semibold.copyWith(color: MiCutColors.textInverse),
    ),
    iconTheme: const IconThemeData(color: MiCutColors.iconInverse),
  );
}
