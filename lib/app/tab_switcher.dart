import 'package:flutter/material.dart';

/// The five tabs side by side, like WhatsApp: the page follows the finger
/// while swiping and the next tab slides in beside it; letting go settles on
/// the nearer one. Tapping a tab slides there too. Every tab is kept alive,
/// so its pages and scroll positions stay.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({
    super.key,
    required this.index,
    required this.children,
    required this.onChanged,
    this.swipe = true,
  });

  final int index;
  final List<Widget> children;

  /// A swipe settled on another tab.
  final ValueChanged<int> onChanged;

  /// Swiping is on for a tab's main page only (inside a page, a sideways
  /// drag belongs to the page).
  final bool swipe;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher> {
  late final _pages = PageController(initialPage: widget.index);

  /// Set while the pager moves on its own (a tab was tapped), so the pages it
  /// passes are not taken for a swipe.
  bool _driving = false;

  @override
  void didUpdateWidget(TabSwitcher old) {
    super.didUpdateWidget(old);
    final shown = _pages.hasClients ? _pages.page?.round() : null;
    if (widget.index != shown && _pages.hasClients) {
      _driving = true;
      _pages
          .animateToPage(widget.index, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic)
          .whenComplete(() => _driving = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
        controller: _pages,
        // The tabs beside the open one are built ahead, so a swipe never
        // shows an empty page.
        allowImplicitScrolling: true,
        physics: widget.swipe ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          if (!_driving && i != widget.index) widget.onChanged(i);
        },
        children: [for (final child in widget.children) _KeepAlive(child: child)],
      );
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
