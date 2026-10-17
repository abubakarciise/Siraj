import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Confirms a multi-surah download (selection, Juz 'Amma, whole Quran) and
/// shows its exact size first. Returns the chosen Wi-Fi-only flag, or null if
/// the user cancelled.
Future<bool?> confirmDownload(
  BuildContext context, {
  required Reciter reciter,
  required Recitation recitation,
  required List<int> surahs,
  required String title,
}) {
  return showAppSheet<bool>(
    context,
    builder: (_) => _DownloadSheetBody(reciter: reciter, recitation: recitation, surahs: surahs, title: title),
  );
}

class _DownloadSheetBody extends ConsumerStatefulWidget {
  const _DownloadSheetBody({required this.reciter, required this.recitation, required this.surahs, required this.title});
  final Reciter reciter;
  final Recitation recitation;
  final List<int> surahs;
  final String title;

  @override
  ConsumerState<_DownloadSheetBody> createState() => _DownloadSheetBodyState();
}

class _DownloadSheetBodyState extends ConsumerState<_DownloadSheetBody> {
  late bool _wifiOnly = ref.read(settingsProvider).wifiOnly;
  final _checked = ValueNotifier<(int, int)>((0, 0));
  late final Future<int?> _size = ref
      .read(downloadManagerProvider)
      .estimateBytes(widget.recitation, widget.surahs, progress: (d, t) => _checked.value = (d, t));

  @override
  void dispose() {
    _checked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dl = ref.watch(downloadsProvider).value;
    final pending = widget.surahs.where((s) => !(dl?.isDownloaded(widget.recitation.key, s) ?? false)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        ReciterAvatar(id: widget.reciter.id, nameAr: widget.reciter.nameAr, size: 56),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: context.text.titleLarge),
            Text('${widget.reciter.name} · ${widget.recitation.shortName}',
                style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
      const SizedBox(height: Space.xl),
      Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Column(children: [
          _Row(icon: Icons.library_music_outlined, label: 'Surahs', value: '$pending to download'),
          const SizedBox(height: Space.md),
          FutureBuilder<int?>(
            future: _size,
            builder: (_, snap) => snap.connectionState != ConnectionState.done
                ? _Row(
                    icon: Icons.sd_storage_outlined,
                    label: 'Size',
                    valueWidget: ValueListenableBuilder<(int, int)>(
                      valueListenable: _checked,
                      builder: (_, p, _) => CalculatingText(done: p.$1, total: p.$2),
                    ),
                  )
                : _Row(
                    icon: Icons.sd_storage_outlined,
                    label: 'Size',
                    value: snap.data == null ? 'Unknown (offline)' : formatBytes(snap.data!),
                  ),
          ),
          const SizedBox(height: Space.md),
          const _Row(icon: Icons.phone_android_rounded, label: 'Saved', value: 'On this phone'),
        ]),
      ),
      const SizedBox(height: Space.md),
      Text(
        'Downloads continue in the background, resume if interrupted, and play without internet once finished.',
        style: context.text.bodySmall,
      ),
      const SizedBox(height: Space.sm),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Wi-Fi only'),
        subtitle: const Text('Wait for Wi-Fi to save mobile data'),
        value: _wifiOnly,
        onChanged: (v) => setState(() => _wifiOnly = v),
      ),
      const SizedBox(height: Space.md),
      FilledButton.icon(
        onPressed: pending == 0 ? null : () => Navigator.pop(context, _wifiOnly),
        icon: const Icon(Icons.download_rounded),
        label: FutureBuilder<int?>(
          future: _size,
          builder: (_, snap) => Text(snap.data == null ? 'Download' : 'Download · ${formatBytes(snap.data!)}'),
        ),
      ),
      const SizedBox(height: Space.sm),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(0, 48), foregroundColor: c.inkMuted),
        onPressed: () => Navigator.pop(context),
        child: const Text('Not now'),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.value = '', this.valueWidget});
  final IconData icon;
  final String label, value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: Space.md),
        Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted)),
        const Spacer(),
        valueWidget ?? Text(value, style: context.text.titleMedium),
      ]);
}

/// "Calculating." "Calculating.." "Calculating..." and back, with how many
/// surahs are checked so far: the sheet is clearly working.
class CalculatingText extends StatefulWidget {
  const CalculatingText({super.key, this.done = 0, this.total = 0});
  final int done, total;

  @override
  State<CalculatingText> createState() => _CalculatingTextState();
}

class _CalculatingTextState extends State<CalculatingText> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // 1, 2, 3, 2 dots, then again.
          const steps = [1, 2, 3, 2];
          final n = steps[(_c.value * steps.length).floor() % steps.length];
          final count = widget.total > 0 ? '  ${widget.done}/${widget.total}' : '';
          return Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Calculating'),
              // The dots keep their place, so the text never jumps.
              TextSpan(text: '.' * n),
              TextSpan(text: '.' * (3 - n), style: const TextStyle(color: Colors.transparent)),
              TextSpan(text: count, style: TextStyle(color: context.colors.inkMuted)),
            ]),
            style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          );
        },
      );
}
