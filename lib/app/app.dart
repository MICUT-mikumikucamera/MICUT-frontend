import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import 'router.dart';

class MiCutApp extends ConsumerWidget {
  const MiCutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MiCut',
      debugShowCheckedModeBanner: false,
      theme: buildMiCutTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
