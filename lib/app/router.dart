import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/quran/models.dart';
import '../design/tab_theme.dart';
import '../features/daily/adhkar_screen.dart';
import '../features/daily/daily_screen.dart';
import '../features/daily/prayer_screen.dart';
import '../features/daily/qibla_screen.dart';
import '../features/daily/tasbih_screen.dart';
import '../features/hadith/hadith_screens.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/memorize/memorize_screens.dart';
import '../features/player/player_screen.dart';
import '../features/quran_index/quran_index_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/reciters/reciter_screen.dart';
import '../features/reciters/reciters_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/reminders_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';
import 'tab_switcher.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes: tabs keep their own stacks; reader, player, search and settings
/// are full-screen on the root navigator.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => AppShell(shell: shell, location: state.uri.path),
      // Each tab keeps its own stack, and its own background colour.
      navigatorContainerBuilder: (context, shell, children) => TabSwitcher(
        index: shell.currentIndex,
        children: [
          for (var i = 0; i < children.length; i++) TabTheme(tab: AppTab.values[i], child: children[i]),
        ],
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const TabBackdrop(tab: AppTab.home, child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quran',
              builder: (_, _) => const TabBackdrop(tab: AppTab.quran, child: QuranIndexScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/listen',
              builder: (_, _) => const TabBackdrop(tab: AppTab.listen, child: RecitersScreen()),
              routes: [
                GoRoute(
                  path: 'reciter/:id',
                  builder: (_, s) =>
                      PageBackground(look: PageLook.listen, child: ReciterScreen(reciterId: int.parse(s.pathParameters['id']!))),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/hadith',
              builder: (_, _) => const TabBackdrop(tab: AppTab.hadith, child: HadithHomeScreen()),
              routes: [
                // In the Hadith tab, so a hadith opened from them comes back to them.
                GoRoute(
                  path: 'search',
                  builder: (_, _) => PageBackground(look: PageLook.hadith, child: const HadithSearchScreen()),
                ),
                GoRoute(
                  path: 'saved',
                  builder: (_, _) => PageBackground(look: PageLook.hadith, child: const SavedHadithScreen()),
                ),
                GoRoute(
                  path: ':book',
                  builder: (_, s) => PageBackground(look: PageLook.hadith, child: HadithBookScreen(bookId: s.pathParameters['book']!)),
                  routes: [
                    GoRoute(
                      path: 's/:section',
                      builder: (_, s) => PageBackground(
                        look: PageLook.hadith,
                        child: HadithListScreen(
                          bookId: s.pathParameters['book']!,
                          section: int.tryParse(s.pathParameters['section']!),
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'n/:number',
                      builder: (_, s) => PageBackground(
                        look: PageLook.hadith,
                        child: HadithDetailScreen(
                          bookId: s.pathParameters['book']!,
                          number: num.tryParse(s.pathParameters['number']!) ?? 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/daily',
              builder: (_, _) => const TabBackdrop(tab: AppTab.daily, child: DailyScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/read/:page',
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) {
        final ayah = s.uri.queryParameters['ayah']?.split(':');
        return CustomTransitionPage(
          child: ReaderScreen(
            initialPage: int.parse(s.pathParameters['page']!),
            highlight: ayah == null ? null : AyahRef(int.parse(ayah[0]), int.parse(ayah[1])),
            surah: int.tryParse(s.uri.queryParameters['surah'] ?? ''),
          ),
          transitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (_, a, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/player',
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, _) => CustomTransitionPage(
        child: const PlayerScreen(),
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, a, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(child: const SearchScreen()),
    ),
    GoRoute(
      path: '/prayer',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(look: PageLook.daily, child: const PrayerScreen()),
    ),
    GoRoute(
      path: '/qibla',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(look: PageLook.daily, child: const QiblaScreen()),
    ),
    GoRoute(
      path: '/tasbih',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(look: PageLook.tasbih, child: const TasbihScreen()),
    ),
    GoRoute(
      path: '/adhkar',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(look: PageLook.daily, child: const AdhkarListScreen()),
      routes: [
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootKey,
          builder: (_, s) => PageBackground(
            look: PageLook.daily,
            child: AdhkarScreen(
              categoryId: s.pathParameters['id']!,
              autoListen: s.uri.queryParameters['listen'] == '1',
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(child: const SettingsScreen()),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(child: const RemindersScreen()),
    ),
    GoRoute(
      path: '/library',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(child: const LibraryScreen()),
    ),
    GoRoute(
      path: '/memorize',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(child: const MemorizeScreen()),
    ),
    GoRoute(
      path: '/sunnah',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => PageBackground(look: PageLook.hadith, child: const SunnahListScreen()),
      routes: [
        GoRoute(
          path: ':index',
          parentNavigatorKey: _rootKey,
          builder: (_, s) =>
              PageBackground(look: PageLook.hadith, child: SunnahDetailScreen(index: int.tryParse(s.pathParameters['index']!) ?? -1)),
        ),
      ],
    ),
  ],
);
