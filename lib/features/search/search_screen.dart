import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../../core/providers.dart';
import '../../core/quran/arabic.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';
  List<SearchHit> _hits = const [];
  bool _loading = false;
  Timer? _debounce;

  static final _refPattern = RegExp(r'^\s*(\d{1,3})\s*[:.\s]\s*(\d{1,3})\s*$');

  void _onChanged(String v) {
    setState(() => _q = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      if (v.trim().length < 2) {
        setState(() => _hits = const []);
        return;
      }
      setState(() => _loading = true);
      final slug = ref.read(settingsProvider).translation;
      final hits = await ref.read(quranDbProvider).search(v, translationSlug: slug.isEmpty ? 'en_sahih' : slug);
      if (mounted && v == _q) {
        setState(() {
          _hits = hits;
          _loading = false;
        });
      }
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
    final db = ref.watch(quranDbProvider);
    final q = _q.trim().toLowerCase();
    final qAr = normalizeArabic(_q);
    String latin(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z]'), '').replaceFirst(RegExp('^(al|an|ar|as|at|ad|az)'), '');
    final qLatin = latin(q);
    final surahHits = q.isEmpty
        ? const <Surah>[]
        : db.surahs
            .where((s) =>
                (qLatin.length >= 2 && latin(s.nameEn).contains(qLatin)) ||
                (q.length >= 3 && s.meaning.toLowerCase().contains(q)) ||
                '${s.id}' == q ||
                (isArabic(_q) && normalizeArabic(s.nameAr).contains(qAr)))
            .take(6)
            .toList();
    final refMatch = _refPattern.firstMatch(_q);
    AyahRef? jump;
    if (refMatch != null) {
      final s = int.parse(refMatch.group(1)!), a = int.parse(refMatch.group(2)!);
      if (s >= 1 && s <= 114 && a >= 1 && a <= db.surah(s).ayahCount) jump = AyahRef(s, a);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Space.lg),
          child: TextField(
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.searchHint,
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (jump != null)
            ListTile(
              leading: Icon(Icons.subdirectory_arrow_right_rounded, color: c.primary),
              title: Text(context.l10n.goTo(db.surah(jump.surah).nameEn, '$jump')),
              onTap: () async {
                final page = await db.pageOf(jump!);
                if (context.mounted) context.openReader(page, ayah: jump.toString());
              },
            ),
          if (surahHits.isNotEmpty) ...[
            SectionTitle(context.l10n.surahs),
            for (final s in surahHits)
              ListTile(
                leading: StarMedallion(number: s.id, size: 38),
                title: Text(s.nameEn),
                subtitle: Text(context.l10n.meaningAndAyahs(s.meaning, s.ayahCount)),
                trailing: Text(s.nameAr, style: TextStyle(fontFamily: kQuranFont, fontSize: 20, color: c.ink)),
                onTap: () => context.openReader(s.pageStart, surah: s.id),
              ),
          ],
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_hits.isNotEmpty) ...[
            SectionTitle(context.l10n.ayahsFound(_hits.length >= 100 ? '100+' : '${_hits.length}')),
            for (final h in _hits)
              InkWell(
                onTap: () => context.openReader(h.ayah.page, ayah: h.ayah.ref.toString()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(context.l10n.searchHitReference(db.surah(h.ayah.ref.surah).nameEn, '${h.ayah.ref}', h.ayah.page),
                        style: context.text.labelSmall?.copyWith(color: c.gold)),
                    const SizedBox(height: 6),
                    h.isTranslation
                        ? Text(h.snippet, maxLines: 4, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium)
                        : Text(
                            h.snippet,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontFamily: kQuranFont, fontSize: 21, height: 1.8, color: c.ink),
                          ),
                  ]),
                ),
              ),
          ],
          if (!_loading && _q.trim().length >= 2 && _hits.isEmpty && surahHits.isEmpty && jump == null)
            Padding(
              padding: const EdgeInsets.all(Space.xxxl),
              child: Text(context.l10n.noResults, textAlign: TextAlign.center, style: context.text.bodyMedium),
            ),
        ],
      ),
    );
  }
}
