import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// Which main screen a header belongs to.
enum HeroArt { home, quran, listen, hadith, daily }

/// A [SliverAppBar] for a main screen: a large title on the page itself, with
/// its Arabic name in gold beside it, folding into a plain bar while
/// scrolling.
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
      expandedHeight: 96,
      actions: [...?actions, const SizedBox(width: Space.xs)],
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1.32,
        titlePadding: const EdgeInsetsDirectional.only(start: Space.gutter, bottom: 12, end: 112),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w700)),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: Space.sm),
              Text(subtitle!,
                  maxLines: 1,
                  style: TextStyle(fontFamily: kNaskhFont, fontSize: 15, color: c.goldText, height: 1.2)),
            ],
          ],
        ),
      ),
    );
  }
}
