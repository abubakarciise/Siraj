import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/notifications/notifications.dart';
import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../core/reminders/reminders.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
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
      body: ListView(padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 40), children: [
        _Hero(enabled: s.enabled),

        // ---- Daily reminders ----
        const GroupHeader('Daily reminders'),
        SettingsGroup(children: [
          SettingsSwitch(
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF0F5C4A),
            title: 'Daily reminders',
            subtitle: 'An ayah, hadith, sunnah or dhikr through the day',
            value: s.enabled,
            onChanged: (v) async {
              if (v && !await _ensurePermission(context, ref)) return;
              await n.update(s.copyWith(enabled: v));
              if (v && context.mounted) showToast(context, 'Daily reminders are on');
            },
          ),
          if (s.enabled)
            SettingsSwitch(
              icon: Icons.shuffle_rounded,
              color: const Color(0xFF8A6A2B),
              title: 'Vary the time a little',
              subtitle: 'Each reminder arrives a few minutes earlier or later',
              value: s.vary,
              onChanged: (v) => n.update(s.copyWith(vary: v)),
            ),
        ]),
        AnimatedSize(
          duration: Motion.standard,
          curve: Motion.curve,
          child: !s.enabled
              ? const SizedBox(width: double.infinity)
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const GroupHeader('How often'),
                  _Panel(
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final h in DailyReminderSettings.intervals)
                        ChoiceChip(
                          label: Text(h == 1 ? 'Every hour' : 'Every $h hours'),
                          selected: s.everyHours == h,
                          onSelected: (_) => n.update(s.copyWith(everyHours: h)),
                        ),
                    ]),
                  ),
                  const GroupHeader('Active hours'),
                  Row(children: [
                    Expanded(child: _TimeBox(label: 'From', time: s.from, onTap: () => pickTime(true))),
                    const SizedBox(width: Space.md),
                    Expanded(child: _TimeBox(label: 'Until', time: s.until, onTap: () => pickTime(false))),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, 0),
                    child: Text(
                      '${ReminderService.slots(s.copyWith(vary: false), DateTime(2000), 0, Random(0)).length} reminders a day. '
                      'Nothing is sent outside these hours.',
                      style: context.text.bodySmall,
                    ),
                  ),
                  const GroupHeader('What to send · chosen at random'),
                  _Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
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
                      const SizedBox(height: Space.md),
                      Text(
                        'Reminders follow the day: Surah Al-Kahf and salawat on Friday, a reminder the evening '
                        'before the Monday and Thursday fasts, the White Days, Ramadan and its last ten nights, '
                        'Dhul Hijjah, Arafah and Ashura, and adhkar in the morning, evening and before sleep.',
                        style: context.text.bodySmall?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: Space.md),
                      OutlinedButton.icon(
                        onPressed: () => _preview(context, ref),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Preview a reminder'),
                      ),
                    ]),
                  ),
                ]),
        ),

        // ---- Adhkar ----
        const GroupHeader('Morning & evening adhkar'),
        AdhkarReminderTiles(settings: ref.watch(prayerSettingsProvider)),

        // ---- Prayer and calendar ----
        const GroupHeader('Prayer & calendar'),
        SettingsGroup(children: [
          SettingsRow(
            icon: Icons.access_time_rounded,
            color: const Color(0xFF0F5C4A),
            title: 'Prayer time alerts',
            value: 'Choose which prayers alert you',
            onTap: () => context.push('/prayer'),
          ),
          SettingsRow(
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF8A6A2B),
            title: '${hijri.label} AH',
            value: s.hijriOffset == 0
                ? 'Umm al-Qura calendar · adjust if your local moon sighting differs'
                : 'Adjusted ${s.hijriOffset > 0 ? '+' : ''}${s.hijriOffset} day${s.hijriOffset.abs() == 1 ? '' : 's'}',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'One day earlier',
                color: c.primary,
                onPressed: s.hijriOffset > -2 ? () => n.update(s.copyWith(hijriOffset: s.hijriOffset - 1)) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              IconButton(
                tooltip: 'One day later',
                color: c.primary,
                onPressed: s.hijriOffset < 2 ? () => n.update(s.copyWith(hijriOffset: s.hijriOffset + 1)) : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ]),
          ),
        ]),

        // ---- Sound ----
        const GroupHeader('Sound'),
        const _SoundChoice(),
        const SizedBox(height: Space.md),
        SettingsGroup(children: [
          SettingsRow(
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFF0F5C4A),
            title: 'Send a test notification',
            value: 'See and hear a reminder now',
            onTap: () async {
              if (await _ensurePermission(context, ref)) await notifications.showTest(ReminderKind.daily);
            },
          ),
        ]),
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
    return BrandPanel(
      child: Row(children: [
        Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
            color: c.goldOnBrand, size: 34),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('فَاذْكُرُونِي أَذْكُرْكُمْ',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: kQuranFont, fontSize: 22, height: 1.6, color: c.onBrand)),
            Text('"Remember Me; I will remember you." (2:152)',
                style: context.text.bodyMedium?.copyWith(color: c.onBrand.withValues(alpha: 0.85), height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

/// Free content (chips, notes) in the same ivory card as a group.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.all(Space.lg), radius: Radii.lg, child: child);
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      radius: Radii.lg,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: context.text.labelSmall?.copyWith(color: c.goldText)),
        Text(time.format(context), style: context.text.headlineSmall?.copyWith(color: c.primary)),
      ]),
    );
  }
}

/// The morning and evening adhkar reminder: on/off and the two times.
class AdhkarReminderTiles extends ConsumerWidget {
  const AdhkarReminderTiles({super.key, required this.settings});
  final PrayerSettings settings;

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
    Widget time(TimeOfDay t) => Text(t.format(context), style: context.text.titleMedium?.copyWith(color: c.primary));
    return SettingsGroup(children: [
      SettingsSwitch(
        icon: Icons.alarm_rounded,
        color: const Color(0xFF0F5C4A),
        title: 'Adhkar reminders',
        subtitle: 'To read the morning and the evening adhkar, at the times you set',
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
        SettingsRow(
          icon: Icons.wb_twilight_rounded,
          color: const Color(0xFF8A6A2B),
          title: 'Morning adhkar',
          value: 'Time to read the morning adhkar',
          trailing: Padding(padding: const EdgeInsets.only(right: Space.sm), child: time(s.morning)),
          onTap: () => _pick(context, ref, true),
        ),
        SettingsRow(
          icon: Icons.nights_stay_outlined,
          color: const Color(0xFF0F5C4A),
          title: 'Evening adhkar',
          value: 'Time to read the evening adhkar',
          trailing: Padding(padding: const EdgeInsets.only(right: Space.sm), child: time(s.evening)),
          onTap: () => _pick(context, ref, false),
        ),
      ],
    ]);
  }
}

/// Pixie Dust (a soft chime, the default) or the phone's own sound.
class _SoundChoice extends ConsumerStatefulWidget {
  const _SoundChoice();

  @override
  ConsumerState<_SoundChoice> createState() => _SoundChoiceState();
}

class _SoundChoiceState extends ConsumerState<_SoundChoice> {
  AudioPlayer? _preview;

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _choose(String value) async {
    final n = ref.read(notificationsProvider);
    if (value == 'siraj') {
      final p = _preview ??= AudioPlayer();
      await p.setAsset('assets/sounds/siraj.ogg');
      unawaited(p.play());
    }
    await n.setSound(value);
    setState(() {});
    // Scheduled reminders move to the channel with the new sound.
    await ref.read(prayerServiceProvider).reschedule();
    await ref.read(reminderServiceProvider).reschedule();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = ref.read(notificationsProvider).sound;
    Widget tile(String value, IconData icon, String title, String subtitle) => SettingsRow(
          icon: icon,
          color: value == 'siraj' ? const Color(0xFF8A6A2B) : const Color(0xFF0F5C4A),
          title: title,
          value: subtitle,
          trailing: Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: Icon(current == value ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: current == value ? c.primary : c.inkFaint),
          ),
          onTap: () => _choose(value),
        );
    return SettingsGroup(children: [
      tile('siraj', Icons.music_note_rounded, 'Pixie Dust', 'A soft, short chime · tap to hear it'),
      tile('default', Icons.phone_android_rounded, 'Phone default', "Your phone's notification sound"),
    ]);
  }
}
