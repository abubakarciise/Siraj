import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../design/tokens.dart';
import '../features/daily/adhkar_mini_player.dart';
import '../features/player/mini_player.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell, required this.location});
  final StatefulNavigationShell shell;

  /// Where the app is, to know if a tab's main page is showing.
  final String location;

  static const _roots = ['/home', '/quran', '/listen', '/hadith', '/daily'];

  /// Swipe left for the next tab, right for the previous one (on a tab's
  /// main page; inside a page, a swipe belongs to the page).
  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 450 || !_roots.contains(location)) return;
    final next = shell.currentIndex + (v < 0 ? 1 : -1);
    if (next >= 0 && next < _roots.length) shell.goBranch(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final downloading = ref.watch(downloadsProvider).value?.active.isNotEmpty ?? false;
    return Scaffold(
      body: GestureDetector(onHorizontalDragEnd: _swipe, child: shell),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          const AdhkarMiniPlayer(),
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.barLine))),
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
