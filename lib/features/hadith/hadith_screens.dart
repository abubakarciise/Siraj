import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hadith/hadith.dart';
import '../../core/providers.dart';
import '../../core/quran/arabic.dart';
import '../../core/reminders/reminders.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/hero.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Approximate download size (Arabic + English) per collection.
const _sizeMb = {'bukhari': 15, 'muslim': 13, 'abudawud': 11, 'tirmidhi': 9, 'nasai': 10, 'ibnmajah': 8, 'malik': 4};

/// Classical sigla used by hadith scholars (e.g. Ibn Hajar's Taqrib).
const _sigla = {
  'bukhari': 'خ',
  'muslim': 'م',
  'abudawud': 'د',
  'tirmidhi': 'ت',
  'nasai': 'س',
  'ibnmajah': 'ق',
  'malik': 'ط',
  'nawawi': '٤٠',
  'qudsi': '٤٠',
};

const _tagLabels = {
  'friday': "Jumu'ah",
  'mon_thu_eve': 'Mondays & Thursdays',
  'white_days': 'White Days',
  'ramadan': 'Ramadan',
  'last_ten': 'Last ten nights',
  'shawwal': 'Shawwal',
  'dhul_hijjah': 'Dhul Hijjah',
  'arafah': 'Arafah',
  'ashura': 'Ashura',
  'morning': 'Morning',
  'evening': 'Evening',
  'sleep': 'Before sleep',
  'night': 'Night',
  'fajr': 'Fajr',
};

extension _BookName on WidgetRef {
  String bookName(String id) => watch(hadithBooksProvider).value?.where((b) => b.id == id).firstOrNull?.nameEn ?? id;
}

// =============================================================================
// Hadith tab
// =============================================================================

class HadithHomeScreen extends ConsumerWidget {
  const HadithHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final books = ref.watch(hadithBooksProvider).value ?? const [];
    final repo = ref.read(hadithRepoProvider);
    final tags = ReminderComposer.occasions(DateTime.now(), ref.watch(dailyRemindersProvider).hijriOffset);
    final sunnah = [...repo.sunnah.indexed]
      ..sort((a, b) => (b.$2.tags.any(tags.contains) ? 1 : 0) - (a.$2.tags.any(tags.contains) ? 1 : 0));

    // The great collections to download (Bukhari, Muslim…) first, then the
    // forty-hadith books that come with the app.
    final collections = [...books.where((b) => !b.bundled), ...books.where((b) => b.bundled)];
    return Scaffold(
      backgroundColor: Colors.transparent, // the tab's art shows through (TabBackdrop)
      body: CustomScrollView(
        slivers: [
          HeroSliverAppBar(
            title: 'Hadith & Sunnah',
            subtitle: 'الحديث والسنة',
            art: HeroArt.hadith,
            actions: [
              IconButton(
                tooltip: 'Search hadith',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/hadith/search'),
              ),
              IconButton(
                tooltip: 'Saved hadith',
                icon: const Icon(Icons.bookmarks_outlined),
                onPressed: () => context.push('/hadith/saved'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SectionTitle(
              'Sunnah to practise',
              trailing: TextButton(onPressed: () => context.push('/sunnah'), child: const Text('See all')),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42 + context.ts(90),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                itemCount: 12,
                separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                itemBuilder: (_, i) {
                  final (index, item) = sunnah[i];
                  final now = item.tags.any(tags.contains) && !item.tags.contains('general');
                  return _SunnahChip(index: index, item: item, highlight: now);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Collections')),
          SliverList.separated(
            itemCount: collections.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: _BookTile(book: collections[i]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.xxxl),
              child: Text(
                'Texts and grades from the open hadith-api project (public domain). Large collections download '
                'once and then work offline.',
                style: context.text.bodySmall?.copyWith(color: c.inkFaint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunnahChip extends StatelessWidget {
  const _SunnahChip({required this.index, required this.item, required this.highlight});
  final int index;
  final SunnahItem item;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tag = item.tags.where(_tagLabels.containsKey).firstOrNull;
    final accent = highlight ? c.primary : c.gold;
    return AppCard(
      width: 210,
      onTap: () => context.push('/sunnah/$index'),
      tint: accent,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(highlight ? Icons.event_available_rounded : Icons.spa_rounded, color: accent, size: 30),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  highlight && tag != null ? 'TODAY · ${_tagLabels[tag]!.toUpperCase()}' : 'SUNNAH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
        ],
      ),
    );
  }
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book});
  final HadithBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dl = ref.watch(hadithDownloadsProvider).value?[book.id];
    final repo = ref.read(hadithRepoProvider);
    Widget trailing;
    if (book.available) {
      trailing = Icon(Icons.chevron_right_rounded, color: c.inkFaint);
    } else if (dl != null) {
      trailing = SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          value: dl.stage == HadithDlStage.saving || dl.progress == 0 ? null : dl.progress,
        ),
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_sizeMb[book.id] ?? 5} MB', style: context.text.bodySmall),
          const SizedBox(width: Space.xs),
          Icon(Icons.download_rounded, color: c.primary),
        ],
      );
    }

    Future<void> download() async {
      final sub = repo.downloads.where((d) => d.book == book.id).listen((d) {
        if (d.stage == HadithDlStage.failed && context.mounted) showToast(context, d.error ?? 'Download failed');
        if (d.stage == HadithDlStage.done && context.mounted) showToast(context, '${book.nameEn} is ready offline');
      });
      await repo.download(book.id);
      await sub.cancel();
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      onTap: book.available
          ? () => context.push('/hadith/${book.id}')
          : dl != null
          ? null
          : download,
      onLongPress: book.available && !book.bundled
          ? () async {
              final ok = await showAppDialog(
                context,
                icon: Icons.delete_outline_rounded,
                title: 'Remove ${book.nameEn}?',
                message: 'It will be deleted from this device. You can download it again any time.',
                confirmLabel: 'Remove',
                destructive: true,
              );
              if (ok) {
                await repo.remove(book.id);
                ref.invalidate(hadithBooksProvider);
              }
            }
          : null,
      child: Row(
        children: [
          // A medallion: emerald ringed with gold (grey until downloaded).
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: book.available
                    ? [Color.lerp(c.primary, Colors.white, 0.15)!, c.primary]
                    : [c.surfaceAlt, Color.lerp(c.surfaceAlt, c.ink, 0.08)!],
              ),
              border: Border.all(color: book.available ? c.gold : c.divider, width: 2),
            ),
            child: Text(
              _sigla[book.id] ?? book.nameAr.substring(0, 1),
              style: TextStyle(fontFamily: kNaskhFont, fontSize: 22, color: book.available ? Colors.white : c.inkMuted),
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.nameEn, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  dl == null
                      ? '${book.count} hadith · ${book.nameAr}'
                      : dl.stage == HadithDlStage.saving
                      ? 'Saving…'
                      : dl.progress == 0
                      ? 'Downloading…'
                      : 'Downloading ${(dl.progress * 100).round()}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          trailing,
        ],
      ),
    );
  }
}

// =============================================================================
// Book → chapters → hadith
// =============================================================================

class HadithBookScreen extends ConsumerStatefulWidget {
  const HadithBookScreen({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

/// A collection with chapters: the chapters, or (while searching) the hadith
/// of the whole collection that match.
class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  String _q = '';
  List<Hadith>? _found;
  Timer? _debounce;
  bool _searching = false;

  void _search(String q) {
    setState(() => _q = q.trim());
    _debounce?.cancel();
    if (_q.length < 2) {
      setState(() => _found = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      setState(() => _searching = true);
      final r = await ref.read(hadithRepoProvider).search(_q, book: widget.bookId);
      if (mounted) setState(() => (_found = r, _searching = false));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bookId = widget.bookId;
    final book = ref.watch(hadithBooksProvider).value?.where((b) => b.id == bookId).firstOrNull;
    final sections = ref.watch(hadithSectionsProvider(bookId)).value;
    if (book == null || sections == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (sections.length <= 1) return HadithListScreen(bookId: bookId, section: sections.firstOrNull?.number);
    final q = _q.toLowerCase();
    final chapters = q.isEmpty
        ? sections
        : sections.where((s) => s.title.toLowerCase().contains(q) || '${s.number}' == q).toList();
    final found = _found;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.nameEn, style: context.headerTitle),
            Text('${sections.length} books · ${book.nameAr}', style: context.headerSub),
          ],
        ),
        bottom: CollectionSearchBar(hint: 'Search ${book.nameEn}', onChanged: _search, busy: _searching),
      ),
      body: AnimatedSwitcher(
        duration: Motion.quick,
        child: found == null
            ? ListView.separated(
                key: const ValueKey('chapters'),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: Space.xxxl),
                itemCount: chapters.length,
                separatorBuilder: (_, _) => Divider(indent: 76, color: c.divider),
                itemBuilder: (_, i) {
                  final s = chapters[i];
                  return ListTile(
                    leading: StarMedallion(number: s.number, size: 40),
                    title: Text(s.title, style: context.text.titleMedium),
                    subtitle: Text('${s.count} hadith'),
                    trailing: Icon(Icons.chevron_right_rounded, color: c.inkFaint),
                    onTap: () => context.push('/hadith/$bookId/s/${s.number}'),
                  );
                },
              )
            : _Results(
                key: ValueKey('found $_q'),
                list: [
                  // Matching chapter titles first, then the hadith.
                  for (final s in chapters)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: StarMedallion(number: s.number, size: 36),
                      title: Text(s.title, style: context.text.titleMedium),
                      subtitle: Text('Chapter · ${s.count} hadith'),
                      onTap: () => context.push('/hadith/$bookId/s/${s.number}'),
                    ),
                  for (final h in found) HadithCard(hadith: h),
                ],
                empty: 'Nothing in ${book.nameEn} matches "$_q"',
              ),
      ),
    );
  }
}

class HadithListScreen extends ConsumerStatefulWidget {
  const HadithListScreen({super.key, required this.bookId, this.section});
  final String bookId;
  final int? section;

  @override
  ConsumerState<HadithListScreen> createState() => _HadithListScreenState();
}

/// The hadith of a collection (or one of its chapters), filtered as you type:
/// English, Arabic (with or without harakat) or a hadith number.
class _HadithListScreenState extends ConsumerState<HadithListScreen> {
  String _q = '';

  bool _matches(Hadith h) {
    final q = _q.trim();
    if (q.isEmpty) return true;
    if (int.tryParse(q) != null) return h.numberLabel == q || h.numberLabel.startsWith('$q.');
    if (isArabic(q)) return normalizeArabic(h.arabic).contains(normalizeArabic(q));
    return h.english.toLowerCase().contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId;
    final all = ref.watch(hadithListProvider((bookId, widget.section))).value;
    final sections = ref.watch(hadithSectionsProvider(bookId)).value ?? const [];
    final title = sections.where((s) => s.number == widget.section).firstOrNull?.title;
    final bookName = ref.bookName(bookId);
    final list = all?.where(_matches).toList();
    final searching = _q.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title == null || title == bookName ? bookName : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.headerTitle,
            ),
            if (title != null && title != bookName) Text(bookName, style: context.headerSub),
          ],
        ),
        bottom: CollectionSearchBar(
          hint: all == null ? 'Search' : 'Search ${all.length} hadith · word or number',
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: Motion.quick,
              child: _Results(
                key: ValueKey(searching ? 'q' : 'all'),
                list: [for (final h in list) HadithCard(hadith: h)],
                empty: 'No hadith match "${_q.trim()}"',
                count: searching ? list.length : null,
              ),
            ),
    );
  }
}

/// A rounded search field under a collection's title.
class CollectionSearchBar extends StatefulWidget implements PreferredSizeWidget {
  const CollectionSearchBar({super.key, required this.hint, required this.onChanged, this.busy = false});
  final String hint;
  final ValueChanged<String> onChanged;
  final bool busy;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CollectionSearchBar> createState() => _CollectionSearchBarState();
}

class _CollectionSearchBarState extends State<CollectionSearchBar> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(99),
      borderSide: BorderSide(color: color),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _text,
          onChanged: (v) {
            setState(() {});
            widget.onChanged(v);
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: c.surface,
            contentPadding: EdgeInsets.zero,
            prefixIcon: widget.busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Icon(Icons.search_rounded, color: c.inkMuted),
            suffixIcon: _text.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _text.clear();
                      setState(() {});
                      widget.onChanged('');
                    },
                  ),
            border: border(c.divider),
            enabledBorder: border(c.divider),
            focusedBorder: border(c.primary),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.list, required this.empty, this.count});
  final List<Widget> list;
  final String empty;
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Text(
            empty,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted),
          ),
        ),
      );
    }
    final head = count == null ? 0 : 1;
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxxl),
      itemCount: list.length + head,
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (_, i) {
        if (head == 1 && i == 0) return Text(count == 1 ? '1 hadith' : '$count hadith', style: context.text.labelSmall);
        return list[i - head];
      },
    );
  }
}

class HadithCard extends StatelessWidget {
  const HadithCard({super.key, required this.hadith, this.showBook});
  final Hadith hadith;

  /// Shown in search results and saved lists.
  final String? showBook;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (narrator, body) = hadith.narratorAndBody;
    final grade = hadith.grades.firstOrNull;
    return AppCard(
      onTap: () => context.push('/hadith/${hadith.book}/n/${hadith.numberLabel}'),
      accent: c.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill('${showBook ?? 'Hadith'} ${hadith.numberLabel}', color: c.primary),
              const Spacer(),
              if (grade != null) Pill(grade.grade, color: _gradeColor(c, grade.grade)),
            ],
          ),
          if (hadith.arabic.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(
              hadith.arabic,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: kNaskhFont, fontSize: 18, height: 1.7, color: c.ink),
            ),
          ],
          const SizedBox(height: Space.sm),
          if (narrator != null)
            Text(
              narrator,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: c.gold),
            ),
          Text(
            body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

Color _gradeColor(AppColors c, String grade) {
  final g = grade.toLowerCase();
  if (g.contains('daif') || g.contains("da'if") || g.contains('mawdu') || g.contains('munkar')) return c.danger;
  if (g.contains('sahih') || g.contains('hasan')) return c.primary;
  return c.inkMuted;
}

// =============================================================================
// One hadith
// =============================================================================

class HadithDetailScreen extends ConsumerStatefulWidget {
  const HadithDetailScreen({super.key, required this.bookId, required this.number});
  final String bookId;
  final num number;

  @override
  ConsumerState<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends ConsumerState<HadithDetailScreen> {
  bool? _saved;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = ref.watch(hadithProvider((widget.bookId, widget.number))).value;
    final bookName = ref.bookName(widget.bookId);
    if (h == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: Text(
              'Download $bookName in the Hadith tab to read this hadith offline.',
              textAlign: TextAlign.center,
              style: context.text.bodyLarge,
            ),
          ),
        ),
      );
    }
    final repo = ref.read(hadithRepoProvider);
    if (_saved == null) repo.isBookmarked(h).then((v) => mounted ? setState(() => _saved = v) : null);
    final sections = ref.watch(hadithSectionsProvider(h.book)).value ?? const [];
    final section = sections.where((s) => s.number == h.section).firstOrNull?.title;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$bookName ${h.numberLabel}', style: context.headerTitle),
            if (section != null && section != bookName)
              Text(section, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.headerSub),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _saved == true ? 'Remove from saved' : 'Save',
            icon: Icon(
              _saved == true ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _saved == true ? c.primary : null,
            ),
            onPressed: () async {
              final on = !(_saved ?? false);
              await repo.setBookmark(h, on);
              HapticFeedback.lightImpact();
              ref.invalidate(hadithBookmarksProvider);
              setState(() => _saved = on);
            },
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: '${h.arabic}\n\n${h.english}\n— $bookName ${h.numberLabel}'.trim()),
              );
              showToast(context, 'Hadith copied');
            },
          ),
        ],
      ),
      body: HadithBody(hadith: h, bookName: bookName),
    );
  }
}

/// Arabic text, translation and grades of one hadith.
class HadithBody extends StatelessWidget {
  const HadithBody({super.key, required this.hadith, required this.bookName, this.header});
  final Hadith hadith;
  final String bookName;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (narrator, body) = hadith.narratorAndBody;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.xxxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        ?header,
        if (hadith.arabic.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: cardBorder(c),
              boxShadow: cardShadow(c),
            ),
            child: SelectableText(
              hadith.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(fontFamily: kNaskhFont, fontSize: 21, height: 2.0, color: c.ink),
            ),
          ),
        const SizedBox(height: Space.xl),
        if (narrator != null) ...[
          Text(narrator, style: context.text.titleMedium?.copyWith(color: c.gold)),
          const SizedBox(height: Space.sm),
        ],
        SelectableText(body, style: context.text.bodyLarge?.copyWith(height: 1.65)),
        const SizedBox(height: Space.xl),
        Text('$bookName · ${hadith.numberLabel}', style: context.text.labelLarge?.copyWith(color: c.inkMuted)),
        if (hadith.grades.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text('GRADING', style: context.text.labelSmall),
          const SizedBox(height: Space.sm),
          for (final g in hadith.grades)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(g.by, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                  ),
                  Pill(g.grade, color: _gradeColor(c, g.grade)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// =============================================================================
// Sunnah practices
// =============================================================================

class SunnahListScreen extends ConsumerWidget {
  const SunnahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = ref.read(hadithRepoProvider).sunnah;
    return Scaffold(
      appBar: AppBar(title: const Text('Sunnah to practise')),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(indent: Space.gutter, color: c.divider),
        itemBuilder: (_, i) {
          final s = items[i];
          final tags = s.tags.where(_tagLabels.containsKey).map((t) => _tagLabels[t]!).join(' · ');
          return ListTile(
            title: Text(s.title, style: context.text.titleMedium),
            subtitle: Text('${ref.bookName(s.book)} ${s.number}${tags.isEmpty ? '' : ' · $tags'}'),
            trailing: Icon(Icons.chevron_right_rounded, color: c.inkFaint),
            onTap: () => context.push('/sunnah/$i'),
          );
        },
      ),
    );
  }
}

class SunnahDetailScreen extends ConsumerWidget {
  const SunnahDetailScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = ref.read(hadithRepoProvider).sunnah;
    if (index < 0 || index >= items.length) return Scaffold(appBar: AppBar());
    final s = items[index];
    final h = Hadith(
      book: s.book,
      number: s.number,
      section: 0,
      arabic: s.arabic,
      english: s.english,
      grades: [if (s.grade != null) HadithGrade('Grade', s.grade!)],
    );
    final tags = s.tags.where(_tagLabels.containsKey).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunnah'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: '${s.title}\n\n${s.english}\n— ${ref.bookName(s.book)} ${s.number}'),
              );
              showToast(context, 'Copied');
            },
          ),
        ],
      ),
      body: HadithBody(
        hadith: h,
        bookName: ref.bookName(s.book),
        header: Padding(
          padding: const EdgeInsets.only(bottom: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title, style: context.text.headlineSmall),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final t in tags) Pill(_tagLabels[t]!, color: c.primary, icon: Icons.event_rounded)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Search & saved
// =============================================================================

class HadithSearchScreen extends ConsumerStatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  ConsumerState<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends ConsumerState<HadithSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Hadith> _results = const [];
  String? _book;
  bool _searching = false;

  void _run() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searching = true);
      final r = await ref.read(hadithRepoProvider).search(_query.text, book: _book);
      if (mounted) setState(() => (_results = r, _searching = false));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final books = (ref.watch(hadithBooksProvider).value ?? const []).where((b) => b.available).toList();
    final names = {for (final b in books) b.id: b.nameEn};
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Space.lg),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => _run(),
            decoration: const InputDecoration(
              hintText: 'Search hadith (English or Arabic)',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 6),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _book == null,
                  onSelected: (_) {
                    setState(() => _book = null);
                    _run();
                  },
                ),
                for (final b in books) ...[
                  const SizedBox(width: Space.sm),
                  ChoiceChip(
                    label: Text(b.nameEn),
                    selected: _book == b.id,
                    onSelected: (_) {
                      setState(() => _book = b.id);
                      _run();
                    },
                  ),
                ],
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.xxl),
                      child: Text(
                        _query.text.trim().length < 2
                            ? 'Searches every collection on this device. Download more collections in the Hadith tab.'
                            : 'No hadith found',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxxl),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                    itemBuilder: (_, i) => HadithCard(hadith: _results[i], showBook: names[_results[i].book]),
                  ),
          ),
        ],
      ),
    );
  }
}

class SavedHadithScreen extends ConsumerWidget {
  const SavedHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(hadithBookmarksProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved hadith')),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? Center(
              child: Text(
                'Tap the bookmark on any hadith to save it here.',
                style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxxl),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.md),
              itemBuilder: (_, i) => HadithCard(hadith: list[i], showBook: ref.bookName(list[i].book)),
            ),
    );
  }
}
