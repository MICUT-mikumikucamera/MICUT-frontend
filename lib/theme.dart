import 'package:flutter/material.dart';

const ink = Color(0xFF222222);
const paper = Color(0xFFF5F5F5);
const muted = Color(0xFF707070);
const line = Color(0xFFE7E7E7);
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ink,
    primary: ink,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamilyFallback: const [
    'Noto Sans KR',
    'Malgun Gothic',
    'Apple SD Gothic Neo',
  ],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 52),
      backgroundColor: ink,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      foregroundColor: ink,
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 48),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  dividerTheme: const DividerThemeData(color: line, thickness: 1),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.photo_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: paper,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: muted),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (message.isNotEmpty) const SizedBox(height: 8),
          if (message.isNotEmpty)
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.6),
            ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.action});
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(height: 1.5)),
          ?action,
        ],
      ),
    ),
  );
}

class SampleImage extends StatelessWidget {
  const SampleImage({super.key, this.result = false});
  final bool result;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: line,
    child: Center(
      child: Text(
        result ? '결과 이미지' : '사진',
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    ),
  );
}
