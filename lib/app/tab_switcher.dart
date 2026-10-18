import 'package:flutter/material.dart';

/// The five tabs, kept alive like an [IndexedStack], but changing with
/// motion: the new tab slides in from the side it lies on (right for a tab
/// further along, left for one before) and fades in, while the old one
/// fades out a little the other way.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher> with SingleTickerProviderStateMixin {
  late final _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  late int _from = widget.index;

  @override
  void didUpdateWidget(TabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _from = old.index;
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.index;
    final dir = to > _from ? 1.0 : -1.0;
    return AnimatedBuilder(
      animation: _move,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_move.value);
        final moving = _move.value < 1 && _from != to;
        return Stack(fit: StackFit.expand, children: [
          // The same wrappers for every tab at all times, so no tab is ever
          // rebuilt (its pages and scroll positions are kept).
          for (var i = 0; i < widget.children.length; i++)
            Offstage(
              offstage: !(i == to || (moving && i == _from)),
              child: _place(
                child: widget.children[i],
                active: i == to,
                dx: i == to ? dir * 0.22 * (1 - t) : (i == _from ? -dir * 0.10 * t : 0),
                opacity: i == to ? t : (i == _from ? (1 - t * 2.5).clamp(0.0, 1.0) : 0),
              ),
            ),
        ]);
      },
    );
  }

  Widget _place({required Widget child, required bool active, required double dx, required double opacity}) =>
      IgnorePointer(
        ignoring: !active,
        child: TickerMode(
          enabled: active,
          child: FractionalTranslation(
            translation: Offset(dx, 0),
            child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
          ),
        ),
      );
}
