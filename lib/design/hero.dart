import 'package:flutter/material.dart';

import 'tokens.dart';
import 'widgets.dart';

/// Which main screen a header belongs to.
enum HeroArt { home, quran, listen, hadith, daily }

/// A [SliverAppBar] for a main screen: a large, clean title (and subtitle)
/// that folds into a plain bar while scrolling.
class HeroSliverAppBar extends StatelessWidget {
  const HeroSliverAppBar({super.key, required this.title, required this.art, this.actions, this.subtitle});
  final String title;
  final String? subtitle;
  final HeroArt art;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 112,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: Space.gutter, bottom: 14, end: 96),
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TabTitle(title),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.onBar.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
