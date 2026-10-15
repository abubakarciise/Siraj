import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../design/tokens.dart';
import '../features/player/mini_player.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final downloading = ref.watch(downloadsProvider).value?.active.isNotEmpty ?? false;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              destinations: [
                const NavigationDestination(
                    icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                const NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Quran'),
                NavigationDestination(
                  icon: Badge(isLabelVisible: downloading, smallSize: 8, backgroundColor: c.primary,
                      child: const Icon(Icons.headphones_outlined)),
                  selectedIcon: Badge(isLabelVisible: downloading, smallSize: 8, backgroundColor: c.primary,
                      child: const Icon(Icons.headphones_rounded)),
                  label: 'Listen',
                ),
                const NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories_rounded), label: 'Hadith'),
                const NavigationDestination(
                    icon: Icon(Icons.wb_twilight_outlined), selectedIcon: Icon(Icons.wb_twilight_rounded), label: 'Daily'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension NavX on BuildContext {
  void openReader(int page, {String? ayah, int? surah}) {
    final q = [if (ayah != null) 'ayah=$ayah', if (surah != null) 'surah=$surah'].join('&');
    push('/read/$page${q.isEmpty ? '' : '?$q'}');
  }
}
