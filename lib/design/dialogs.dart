import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'tokens.dart';

/// App-styled dialog: soft icon badge, title, message, full-width actions.
/// Returns true when the primary action is chosen.
Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  IconData icon = Icons.info_outline_rounded,
  String? confirmLabel,
  String? cancelLabel,
  bool showCancel = true,
  bool destructive = false,
  Widget? content,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: Motion.standard,
    pageBuilder: (ctx, _, _) => _AppDialog(
      title: title,
      message: message,
      icon: icon,
      confirmLabel: confirmLabel ?? context.l10n.ok,
      cancelLabel: showCancel ? cancelLabel ?? context.l10n.cancel : null,
      destructive: destructive,
      content: content,
    ),
    transitionBuilder: (_, a, _, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
      );
    },
  );
  return result ?? false;
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.content,
  });

  final String title;
  final String? message, cancelLabel;
  final IconData icon;
  final String confirmLabel;
  final bool destructive;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = destructive ? c.danger : c.primary;
    final insets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: Motion.quick,
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.xl),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xxl, Space.xxl, Space.xl),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: accent, size: 28),
                    ),
                    const SizedBox(height: Space.lg),
                    Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
                    if (message != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(message!,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(color: c.inkMuted, height: 1.45)),
                    ],
                    if (content != null) ...[const SizedBox(height: Space.lg), content!],
                    const SizedBox(height: Space.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(confirmLabel),
                      ),
                    ),
                    if (cancelLabel != null) ...[
                      const SizedBox(height: Space.sm),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(minimumSize: const Size(0, 48), foregroundColor: c.inkMuted),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(cancelLabel!),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// App-styled bottom sheet that never hides content behind the system
/// navigation bar, scrolls when content is tall, and can pin a footer.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  WidgetBuilder? footer,
  String? title,
  double maxHeightFactor = 0.88,
}) =>
    showModalBottomSheet<T>(
      context: context,
      // Root navigator: sheets opened inside a tab must cover the tab bar,
      // otherwise their lower part (buttons) is hidden behind it.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: mq.size.height * maxHeightFactor),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                  child: Text(title, style: ctx.text.titleLarge),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      Space.gutter, 0, Space.gutter, footer == null ? Space.xl + mq.padding.bottom : Space.md),
                  child: builder(ctx),
                ),
              ),
              if (footer != null)
                DecoratedBox(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: ctx.colors.divider))),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + mq.padding.bottom),
                    child: footer(ctx),
                  ),
                ),
            ]),
          ),
        );
      },
    );
