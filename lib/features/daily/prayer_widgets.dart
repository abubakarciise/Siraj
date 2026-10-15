import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

String formatTime(BuildContext context, DateTime t) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(t));

String formatCountdown(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

/// Next-prayer card with live countdown and a five-prayer timeline.
class PrayerCard extends ConsumerWidget {
  const PrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(prayerSettingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final service = ref.read(prayerServiceProvider);

    if (!settings.hasLocation) {
      return _Shell(
        onTap: () => showLocationSheet(context),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Icon(Icons.mosque_outlined, color: c.primary),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prayer times', style: context.text.titleMedium),
              Text('Set your location to see prayer times and Qibla', style: context.text.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkMuted),
        ]),
      );
    }

    final today = service.day(now, settings)!;
    final next = service.next(now);
    final current = today.currentAt(now);
    return _Shell(
      onTap: () => context.push('/prayer'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.place_outlined, size: 16, color: c.inkMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(settings.place ?? 'My location', style: context.text.bodySmall)),
          Text('NEXT PRAYER', style: context.text.labelSmall),
        ]),
        const SizedBox(height: Space.sm),
        if (next != null)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(next.$1.en, style: context.text.headlineSmall),
                Text(next.$1.ar, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatTime(context, next.$2), style: context.text.headlineSmall?.copyWith(color: c.primary)),
              Text('in ${formatCountdown(next.$2.difference(now))}', style: context.text.bodySmall),
            ]),
          ]),
        const SizedBox(height: Space.lg),
        Row(children: [
          for (final s in Salah.values.where((s) => s.isPrayer))
            Expanded(
              child: Column(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s == next?.$1
                        ? c.primary
                        : today.times[s]!.isBefore(now)
                            ? c.inkFaint
                            : c.divider,
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.en,
                    style: context.text.labelSmall?.copyWith(
                        color: s == current || s == next?.$1 ? c.ink : c.inkMuted,
                        fontWeight: s == next?.$1 ? FontWeight.w700 : null)),
                Text(formatTime(context, today.times[s]!), style: context.text.bodySmall?.copyWith(fontSize: 11)),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.lg), border: Border.all(color: c.divider)),
          child: child,
        ),
      ),
    );
  }
}

/// Location picker: one-tap GPS, or choose a city (fully offline).
Future<void> showLocationSheet(BuildContext context) => showAppSheet(
      context,
      title: 'Your location',
      builder: (_) => const _LocationSheet(),
    );

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  bool _busy = false;
  String _query = '';

  Future<void> _gps() async {
    setState(() => _busy = true);
    try {
      await ref.read(prayerSettingsProvider.notifier).locate();
      await ref.read(notificationsProvider).requestPermission();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showToast(context, '$e. You can pick your city instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cities = kCities.where((x) => x.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Used only on your phone to calculate prayer times and the Qibla direction.',
          style: context.text.bodySmall),
      const SizedBox(height: Space.lg),
      FilledButton.icon(
        onPressed: _busy ? null : _gps,
        icon: _busy
            ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
            : const Icon(Icons.my_location_rounded),
        label: Text(_busy ? 'Finding you…' : 'Use my current location'),
      ),
      const SizedBox(height: Space.lg),
      TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Or search a city'),
      ),
      const SizedBox(height: Space.sm),
      for (final city in cities)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.location_city_outlined, color: c.inkMuted),
          title: Text(city.name),
          onTap: () async {
            await ref.read(prayerSettingsProvider.notifier).chooseCity(city);
            await ref.read(notificationsProvider).requestPermission();
            if (context.mounted) Navigator.pop(context);
          },
        ),
    ]);
  }
}
