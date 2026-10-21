import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../design/theme.dart';
import '../l10n/l10n.dart';
import 'router.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final kind = settings.resolve(platformDark);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      // The languages Siraj speaks: one lib/l10n/app_<code>.arb file each.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(kind),
      themeAnimationDuration: const Duration(milliseconds: 320),
      routerConfig: appRouter,
      // Large tablets and landscape: keep a readable column instead of
      // stretching lines across the whole screen.
      builder: (context, child) {
        // Notifications and other code without a BuildContext follow the
        // app's language too.
        setL10nLocale(Localizations.localeOf(context));
        final media = MediaQuery.of(context);
        const maxWidth = 760.0;
        if (media.size.width <= maxWidth + 120 || child == null) return child ?? const SizedBox();
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: MediaQuery(data: media.copyWith(size: Size(maxWidth, media.size.height)), child: child),
            ),
          ),
        );
      },
    );
  }
}
