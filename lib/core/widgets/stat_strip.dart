import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import 'screen_layout.dart';
import 'stat_card.dart';

/// Reusable metric strip that renders KPIs compactly across all viewports.
/// - Desktop (width > 900): Single row of cards with standardized desktop height & gridGap.
/// - Mobile / Narrow (width <= 900): 2x2 grid with standardized mobile card height.
class StatStrip extends StatelessWidget {
  final List<StatCard> cards;

  const StatStrip({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final isWide = ScreenLayout.isWide(context);

    if (isWide) {
      return SizedBox(
        height: AppSizes.statCardHeightDesktop,
        child: Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: ScreenLayout.gridGap),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      );
    }

    // Mobile / Tablet: 2x2 compact grid
    final firstRow = cards.take(2).toList();
    final secondRow = cards.skip(2).take(2).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (int i = 0; i < firstRow.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: AppSizes.statCardHeightMobile,
                  child: firstRow[i],
                ),
              ),
            ],
          ],
        ),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < secondRow.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: AppSizes.statCardHeightMobile,
                    child: secondRow[i],
                  ),
                ),
              ],
              if (secondRow.length == 1) ...[
                const SizedBox(width: 8),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
