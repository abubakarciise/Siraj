import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notifications.dart';
import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../core/reminders/reminders.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Daily reminders (frequency, hours, content), adhkar reminders and prayer alerts.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<bool> _ensurePermission(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(notificationsProvider).requestPermission();
    if (!ok && context.mounted) {
      await showAppDialog(
        context,
        icon: Icons.notifications_off_outlined,
        title: 'Notifications are off',
        message: 'Allow notifications for Siraj in your phone settings to receive reminders.',
        cancelLabel: null,
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(dailyRemindersProvider);
    final n = ref.read(dailyRemindersProvider.notifier);
    final hijri = ref.watch(hijriTodayProvider);
    final notifications = ref.read(notificationsProvider);

    Future<void> pickTime(bool start) async {
      final t = await showTimePicker(context: context, initialTime: start ? s.from : s.until);
      if (t != null) await n.update(start ? s.copyWith(from: t) : s.copyWith(until: t));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(padding: const EdgeInsets.only(bottom: Space.xxxl), children: [
        _Hero(enabled: s.enabled),
        SwitchListTile(
          title: const Text('Daily reminders'),
          subtitle: const Text('An ayah, hadith, sunnah or dhikr through the day'),
          value: s.enabled,
          onChanged: (v) async {
            if (v && !await _ensurePermission(context, ref)) return;
            await n.update(s.copyWith(enabled: v));
            if (v && context.mounted) showToast(context, 'Daily reminders are on');
          },
        ),
        AnimatedSize(
          duration: Motion.standard,
          curve: Motion.curve,
          child: !s.enabled
              ? const SizedBox(width: double.infinity)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('How often'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final h in DailyReminderSettings.intervals)
                        ChoiceChip(
                          label: Text(h == 1 ? 'Every hour' : 'Every $h hours'),
                          selected: s.everyHours == h,
                          onSelected: (_) => n.update(s.copyWith(everyHours: h)),
                        ),
                    ]),
                  ),
                  SwitchListTile(
                    title: const Text('Vary the time a little'),
                    subtitle: const Text('Each reminder arrives a few minutes earlier or later'),
                    value: s.vary,
                    onChanged: (v) => n.update(s.copyWith(vary: v)),
                  ),
                  const _Label('Active hours'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Row(children: [
                      Expanded(child: _TimeBox(label: 'From', time: s.from, onTap: () => pickTime(true))),
                      const SizedBox(width: Space.md),
                      Expanded(child: _TimeBox(label: 'Until', time: s.until, onTap: () => pickTime(false))),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
                    child: Text(
                      '${ReminderService.slots(s.copyWith(vary: false), DateTime(2000), 0, Random(0)).length} reminders a day. '
                      'Nothing is sent outside these hours.',
                      style: context.text.bodySmall,
                    ),
                  ),
                  const _Label('What to send (chosen at random)'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final t in ReminderContent.values)
                        FilterChip(
                          label: Text(t.label),
                          selected: s.content.contains(t),
                          onSelected: (on) {
                            final next = {...s.content};
                            on ? next.add(t) : next.remove(t);
                            if (next.isNotEmpty) n.update(s.copyWith(content: next));
                          },
                        ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
                    child: Text(
                      'Reminders follow the day: Surah Al-Kahf and salawat on Friday, a reminder the evening '
                      'before the Monday and Thursday fasts, the White Days, Ramadan and its last ten nights, '
                      'Dhul Hijjah, Arafah and Ashura, and adhkar in the morning, evening and before sleep.',
                      style: context.text.bodySmall,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: OutlinedButton.icon(
                      onPressed: () => _preview(context, ref),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview a reminder'),
                    ),
                  ),
                ]),
        ),
        const _Label('Morning & evening adhkar'),
        AdhkarReminderTiles(settings: ref.watch(prayerSettingsProvider)),
        const _Label('Hijri date'),
        ListTile(
          leading: Icon(Icons.calendar_month_outlined, color: c.primary),
          title: Text('${hijri.label} AH'),
          subtitle: Text(s.hijriOffset == 0
              ? 'Umm al-Qura calendar · adjust if your local moon sighting differs'
              : 'Adjusted ${s.hijriOffset > 0 ? '+' : ''}${s.hijriOffset} day${s.hijriOffset.abs() == 1 ? '' : 's'}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'One day earlier',
              onPressed: s.hijriOffset > -2 ? () => n.update(s.copyWith(hijriOffset: s.hijriOffset - 1)) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            IconButton(
              tooltip: 'One day later',
              onPressed: s.hijriOffset < 2 ? () => n.update(s.copyWith(hijriOffset: s.hijriOffset + 1)) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ]),
        ),
        ListTile(
          leading: Icon(Icons.access_time_rounded, color: c.primary),
          title: const Text('Prayer time alerts'),
          subtitle: const Text('Choose which prayers alert you'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/prayer'),
        ),
        ListTile(
          leading: Icon(Icons.notifications_active_outlined, color: c.primary),
          title: const Text('Send a test notification'),
          subtitle: const Text("Reminders use your phone's notification sound"),
          onTap: () async {
            if (await _ensurePermission(context, ref)) await notifications.showTest(ReminderKind.daily);
          },
        ),
      ]),
    );
  }

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    ref.invalidate(reminderNowProvider);
    final r = await ref.read(reminderNowProvider.future);
    if (!context.mounted) return;
    await showAppSheet(
      context,
      title: r.label ?? 'Reminder',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(r.title, style: ctx.text.titleMedium),
        const SizedBox(height: Space.sm),
        Text(r.body, style: ctx.text.bodyLarge?.copyWith(height: 1.5)),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(notificationsProvider).showTest(ReminderKind.daily);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Send a test notification'),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.sm),
      child: Container(
        decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(Radii.xl)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(child: GirihPattern(color: c.onBrand, cell: 48, opacity: 0.07)),
          Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Row(children: [
              Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: c.gold, size: 34),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Text(
                  '"Remember Me; I will remember you." (2:152)',
                  style: context.text.titleMedium?.copyWith(color: c.onBrand, height: 1.4),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.sm),
        child: Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
      );
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: context.text.bodySmall),
            Text(time.format(context), style: context.text.titleLarge?.copyWith(color: c.primary)),
          ]),
        ),
      ),
    );
  }
}

/// The morning and evening adhkar reminder: on/off and the two times.
class AdhkarReminderTiles extends ConsumerWidget {
  const AdhkarReminderTiles({super.key, required this.settings, this.padding});
  final PrayerSettings settings;
  final EdgeInsetsGeometry? padding;

  Future<void> _pick(BuildContext context, WidgetRef ref, bool morning) async {
    final t = await showTimePicker(context: context, initialTime: morning ? settings.morning : settings.evening);
    if (t == null) return;
    await ref
        .read(prayerSettingsProvider.notifier)
        .update(morning ? settings.copyWith(morning: t) : settings.copyWith(evening: t));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = settings;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SwitchListTile(
        contentPadding: padding,
        title: const Text('Morning & evening adhkar'),
        subtitle: const Text('A reminder to read the morning adhkar and the evening adhkar, at the times you set'),
        value: s.adhkarReminders,
        onChanged: (v) async {
          if (v) {
            final ok = await ref.read(notificationsProvider).requestPermission();
            if (!ok && context.mounted) {
              await showAppDialog(
                context,
                icon: Icons.notifications_off_outlined,
                title: 'Notifications are off',
                message: 'Allow notifications for Siraj in your phone settings to receive reminders.',
                cancelLabel: null,
              );
            }
          }
          await ref.read(prayerSettingsProvider.notifier).update(s.copyWith(adhkarReminders: v));
        },
      ),
      if (s.adhkarReminders) ...[
        ListTile(
          contentPadding: padding,
          leading: Icon(Icons.wb_twilight_rounded, color: c.primary),
          title: const Text('Morning adhkar reminder'),
          subtitle: const Text('Time to read the morning adhkar'),
          trailing: Text(s.morning.format(context), style: context.text.titleMedium?.copyWith(color: c.primary)),
          onTap: () => _pick(context, ref, true),
        ),
        ListTile(
          contentPadding: padding,
          leading: Icon(Icons.nights_stay_outlined, color: c.primary),
          title: const Text('Evening adhkar reminder'),
          subtitle: const Text('Time to read the evening adhkar'),
          trailing: Text(s.evening.format(context), style: context.text.titleMedium?.copyWith(color: c.primary)),
          onTap: () => _pick(context, ref, false),
        ),
      ],
    ]);
  }
}
