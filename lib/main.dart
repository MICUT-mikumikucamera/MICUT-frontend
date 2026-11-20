import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/theme/appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = await loadAppearance();
  runApp(ProviderScope(overrides: [
    initialAppearanceProvider.overrideWithValue(appearance),
  ], child: const MiCutApp()));
}
