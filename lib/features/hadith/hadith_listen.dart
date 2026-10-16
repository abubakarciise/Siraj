import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hadith/hadith.dart';
import '../../core/hadith/hadith_reader.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Starts reading [items] aloud from [from]. Without an Arabic voice on the
/// phone, explains how to add one and offers English instead.
Future<void> listenToHadith(BuildContext context, WidgetRef ref, String key, List<Hadith> items, int from) async {
  final reader = ref.read(hadithReaderProvider);
  var language = reader.language;
  if (language == 'ar' && !await reader.hasArabic()) {
    if (!context.mounted) return;
    if (!await _offerEnglish(context)) return;
    language = 'en';
  }
  reader.onError = (_) async {
    // The voice failed while reading (usually: Arabic voice data not downloaded yet).
    if (!context.mounted) return;
    if (reader.language == 'ar' && await _offerEnglish(context)) {
      await reader.start(key, items, reader.index, language: 'en');
    } else if (context.mounted) {
      showToast(context, 'The phone could not read this aloud');
    }
  };
  await reader.start(key, items, from, language: language);
}

Future<bool> _offerEnglish(BuildContext context) => showAppDialog(
      context,
      icon: Icons.record_voice_over_outlined,
      title: 'Arabic voice not ready',
      message: 'To hear hadith in Arabic, add the Arabic voice: Settings › Accessibility (or System) › '
          'Text-to-speech › Speech Services by Google › Install voice data › Arabic.\n\n'
          'You can listen in English now.',
      confirmLabel: 'Listen in English',
    );

/// Controls while hadith are read aloud.
class HadithListenBar extends StatelessWidget {
  const HadithListenBar({super.key, required this.reader});
  final HadithReader reader;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final single = reader.length <= 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
            side: BorderSide(color: c.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, Space.sm),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    single ? 'Listening' : 'Hadith ${reader.index + 1} of ${reader.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: context.text.bodySmall,
                    ),
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('عربي')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {reader.language},
                    onSelectionChanged: (v) => reader.setLanguage(v.first),
                  ),
                ]),
              ),
              if (!single)
                IconButton(
                  tooltip: 'Previous',
                  onPressed: reader.index > 0 ? () => reader.skip(-1) : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
              Material(
                color: c.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: reader.playing ? reader.pause : reader.resume,
                  child: SizedBox.square(
                    dimension: 52,
                    child: Icon(reader.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: c.onPrimary, size: 30),
                  ),
                ),
              ),
              if (!single)
                IconButton(
                  tooltip: 'Next',
                  onPressed: reader.index < reader.length - 1 ? () => reader.skip(1) : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              IconButton(
                tooltip: 'Stop listening',
                onPressed: reader.stop,
                icon: Icon(Icons.close_rounded, color: c.inkMuted),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
