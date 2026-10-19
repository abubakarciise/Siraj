import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import 'prayer_widgets.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  int _offset = 0; // days from today

  Future<void> _toggleNotify(PrayerSettings s, Salah salah) async {
    final notify = {...s.notify};
    final on = !notify.contains(salah);
    on ? notify.add(salah) : notify.remove(salah);
    if (on) {
      await ref.read(notificationsProvider).requestPermission();
      await ref.read(notificationsProvider).ensureExactAlarms();
    }
    HapticFeedback.selectionClick();
    await ref.read(prayerSettingsProvider.notifier).update(s.copyWith(notify: notify));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(prayerSettingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final service = ref.read(prayerServiceProvider);
    final date = DateTime(now.year, now.month, now.day).add(Duration(days: _offset));
    final day = service.day(date, s);
    final focus = _offset == 0 ? service.focus(now) : null;
    final next = focus == null ? null : (focus.salah, focus.time);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer times'),
        actions: [
          IconButton(
            tooltip: 'Calculation settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _settingsSheet(context),
          ),
        ],
      ),
      body: !s.hasLocation
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xxxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mosque_outlined, size: 56, color: c.primary),
                  const SizedBox(height: Space.lg),
                  Text('Set your location', style: context.text.titleLarge),
                  const SizedBox(height: Space.sm),
                  Text('Prayer times are calculated on your phone. No internet needed.',
                      textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                  const SizedBox(height: Space.xl),
                  FilledButton(onPressed: () => showLocationSheet(context), child: const Text('Choose location')),
                ]),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxxl),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: Row(children: [
                    Icon(Icons.place_rounded, color: c.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(s.place ?? 'Makkah', style: context.text.titleMedium),
                  ]),
                ),
                if (next != null) ...[
                  const SizedBox(height: Space.md),
                  Container(
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c.brandGradient), borderRadius: BorderRadius.circular(Radii.xl)),
                    child: Stack(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${focus!.started ? 'NOW' : 'NEXT'} · ${next.$1.ar}', style: context.text.labelSmall?.copyWith(color: c.onBrand.withValues(alpha: 0.8))),
                        const SizedBox(height: 4),
                        Text(next.$1.en, style: context.text.displaySmall?.copyWith(color: c.onBrand)),
                        Text(
                            focus.started
                                ? '${formatTime(context, next.$2)} · began ${formatCountdown(now.difference(next.$2))} ago'
                                : '${formatTime(context, next.$2)} · in ${formatCountdown(next.$2.difference(now))}',
                            style: context.text.titleMedium?.copyWith(color: c.onBrand)),
                      ]),
                    ]),
                  ),
                ],
                const SizedBox(height: Space.lg),
                Row(children: [
                  IconButton(onPressed: () => setState(() => _offset--), icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(
                    child: Text(
                      _offset == 0
                          ? 'Today'
                          : _offset == 1
                              ? 'Tomorrow'
                              : MaterialLocalizations.of(context).formatMediumDate(date),
                      textAlign: TextAlign.center,
                      style: context.text.titleMedium,
                    ),
                  ),
                  IconButton(onPressed: () => setState(() => _offset++), icon: const Icon(Icons.chevron_right_rounded)),
                ]),
                const SizedBox(height: Space.sm),
                for (final salah in Salah.values)
                  _PrayerRow(
                    salah: salah,
                    time: day!.times[salah]!,
                    isNext: salah == next?.$1,
                    passed: _offset == 0 && day.times[salah]!.isBefore(now),
                    notify: s.notify.contains(salah),
                    onBell: salah.isPrayer ? () => _toggleNotify(s, salah) : null,
                  ),
                const SizedBox(height: Space.lg),
                Text(
                  '${kMethodNames[s.method] ?? s.method.name} · Asr: ${s.hanafi ? 'Hanafi' : 'Standard (Shafi, Maliki, Hanbali)'}',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
            ),
    );
  }

  void _settingsSheet(BuildContext context) {
    showAppSheet(
      context,
      title: 'Calculation',
      builder: (ctx) => Consumer(builder: (context, ref, _) {
        final s = ref.watch(prayerSettingsProvider);
        final n = ref.read(prayerSettingsProvider.notifier);
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Asr time', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Standard')),
              ButtonSegment(value: true, label: Text('Hanafi')),
            ],
            selected: {s.hanafi},
            onSelectionChanged: (v) => n.update(s.copyWith(hanafi: v.first)),
          ),
        ]);
      }),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.salah,
    required this.time,
    required this.isNext,
    required this.passed,
    required this.notify,
    this.onBell,
  });

  final Salah salah;
  final DateTime time;
  final bool isNext, passed, notify;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: Motion.standard,
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      decoration: BoxDecoration(
        color: isNext ? c.primarySoft : c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: isNext ? Border.all(color: c.primary.withValues(alpha: 0.4)) : cardBorder(c),
        boxShadow: cardShadow(c),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(salah.en,
                style: context.text.titleMedium?.copyWith(color: passed ? c.inkMuted : (isNext ? c.primary : null))),
            Text(salah.ar, style: context.text.bodySmall),
          ]),
        ),
        Text(formatTime(context, time),
            style: context.text.titleLarge?.copyWith(color: passed ? c.inkMuted : (isNext ? c.primary : c.ink))),
        const SizedBox(width: Space.sm),
        onBell == null
            ? const SizedBox(width: 48)
            : IconButton(
                tooltip: notify ? 'Reminder on' : 'Reminder off',
                onPressed: onBell,
                icon: Icon(notify ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                    color: notify ? c.primary : c.inkFaint),
              ),
      ]),
    );
  }
}
