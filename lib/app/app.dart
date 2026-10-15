import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../design/theme.dart';
import 'router.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final kind = settings.resolve(platformDark);
    return MaterialApp.router(
      title: 'Siraj',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(kind),
      themeAnimationDuration: const Duration(milliseconds: 320),
      routerConfig: appRouter,
    );
  }
}
