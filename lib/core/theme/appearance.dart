import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/appearance_storage.dart';

final initialAppearanceProvider =
    Provider<ThemeMode>((ref) => ThemeMode.system);
final appearanceWriterProvider =
    Provider<Future<void> Function(String)>((ref) => writeAppearance);
final appearanceProvider =
    StateNotifierProvider<AppearanceController, ThemeMode>((ref) =>
        AppearanceController(ref.read(initialAppearanceProvider),
            ref.read(appearanceWriterProvider)));

class AppearanceController extends StateNotifier<ThemeMode> {
  AppearanceController(super.state, this.write);
  final Future<void> Function(String) write;
  Future<void> select(ThemeMode mode) async {
    await write(mode.name);
    if (mounted) state = mode;
  }
}

Future<ThemeMode> loadAppearance() async {
  try {
    final stored = await readAppearance();
    return ThemeMode.values.firstWhere((mode) => mode.name == stored,
        orElse: () => ThemeMode.system);
  } catch (_) {
    return ThemeMode.system;
  }
}

String appearanceLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => '기기 설정 따르기',
      ThemeMode.light => '라이트 모드',
      ThemeMode.dark => '다크 모드',
    };
