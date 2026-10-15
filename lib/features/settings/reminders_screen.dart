import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notifications.dart';
import '../../core/notifications/sounds.dart';
import '../../core/providers.dart';
import '../../core/reminders/reminders.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Daily reminders (frequency, hours, content) and the sound of every reminder.
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
      appBar: AppBar(title: const Text('Reminders & sounds')),
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
                      'Reminders follow the day: Surah Al-Kahf and salawat on Friday, fasting on Sunday and '
                      'Wednesday evenings, the White Days, Ramadan and its last ten nights, Dhul Hijjah, Arafah '
                      'and Ashura, and adhkar in the morning, evening and before sleep.',
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
        const _Label('Sounds'),
        for (final kind in ReminderKind.values)
          ListTile(
            leading: Icon(
              switch (kind) {
                ReminderKind.prayer => Icons.mosque_outlined,
                ReminderKind.adhkar => Icons.wb_twilight_rounded,
                ReminderKind.daily => Icons.auto_awesome_outlined,
              },
              color: c.primary,
            ),
            title: Text(kind.title),
            subtitle: Text(notifications.soundFor(kind).label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showSoundPicker(context, ref, kind),
          ),
        ListTile(
          leading: Icon(Icons.access_time_rounded, color: c.primary),
          title: const Text('Prayer & adhkar times'),
          subtitle: const Text('Choose which prayers alert you, and the adhkar times'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/prayer'),
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

/// Sound choice for one kind of reminder: built-in sounds with preview, the
/// phone's default, silent, or any sound on the phone (Android).
Future<void> showSoundPicker(BuildContext context, WidgetRef ref, ReminderKind kind) => showAppSheet(
      context,
      title: '${kind.title} sound',
      builder: (_) => _SoundPicker(kind: kind),
    );

class _SoundPicker extends ConsumerStatefulWidget {
  const _SoundPicker({required this.kind});
  final ReminderKind kind;

  @override
  ConsumerState<_SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends ConsumerState<_SoundPicker> {
  late NotificationSound _current = ref.read(notificationsProvider).soundFor(widget.kind);
  NotificationSound? _device;
  late final _sounds = ref.read(soundServiceProvider);

  @override
  void initState() {
    super.initState();
    if (_current.kind == SoundKind.device) _device = _current;
  }

  @override
  void dispose() {
    _sounds.stop();
    super.dispose();
  }

  Future<void> _choose(NotificationSound s) async {
    setState(() => _current = s);
    try {
      await _sounds.preview(s);
    } catch (_) {}
    await ref.read(notificationsProvider).setSound(widget.kind, s);
    // Pending reminders move to the channel with the new sound.
    switch (widget.kind) {
      case ReminderKind.prayer || ReminderKind.adhkar:
        await ref.read(prayerServiceProvider).reschedule();
      case ReminderKind.daily:
        await ref.read(reminderServiceProvider).reschedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tile(NotificationSound s, String title, String? subtitle, IconData icon) {
      final selected = _current == s;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: selected ? c.primary : c.inkMuted),
        title: Text(title, style: context.text.titleMedium?.copyWith(color: selected ? c.primary : null)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected ? Icon(Icons.check_circle_rounded, color: c.primary) : null,
        onTap: () => _choose(s),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final b in kBuiltinSounds)
        tile(NotificationSound.builtin(b.id), b.name, b.description, Icons.music_note_rounded),
      tile(NotificationSound.systemDefault, 'Phone default', 'Your phone\'s notification sound', Icons.phone_android_rounded),
      if (_device != null) tile(_device!, _device!.label, 'From your phone', Icons.library_music_outlined),
      tile(NotificationSound.silent, 'Silent', 'Vibrate only', Icons.notifications_off_outlined),
      if (SoundService.canPickDeviceSound)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.add_circle_outline_rounded, color: c.primary),
          title: Text('Choose from phone…', style: context.text.titleMedium?.copyWith(color: c.primary)),
          subtitle: const Text('Any ringtone or notification sound on this phone'),
          onTap: () async {
            final s = await _sounds.pickDeviceSound(
              title: '${widget.kind.title} sound',
              current: _current.kind == SoundKind.device ? _current.value : null,
            );
            if (s == null) return;
            setState(() => _device = s);
            await _choose(s);
          },
        ),
      const SizedBox(height: Space.md),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            if (!await ref.read(notificationsProvider).requestPermission()) return;
            await ref.read(notificationsProvider).showTest(widget.kind);
          },
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Send a test notification'),
        ),
      ),
    ]);
  }
}
