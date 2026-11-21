import 'package:flutter/material.dart';

import 'bz_theme.dart';
import 'tokens.dart';

/// BzSegmentedControl — fill-scale segmented tabs (Songs / Videos).
/// Active segment inverts; the whole control is one quiet fill pill.
class BzSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const BzSegmentedControl({
    super.key,
    required this.segments,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.bzFillBase,
        borderRadius: BorderRadius.circular(BzRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: BzMotion.fastMs),
                  curve: BzMotion.standardCurve,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: i == activeIndex
                        ? theme.bzText1
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(BzRadius.button - 1),
                  ),
                  child: Text(
                    segments[i],
                    style: TextStyle(
                      fontSize: BzType.footnote,
                      fontWeight: FontWeight.w600,
                      color:
                          i == activeIndex ? theme.bzBackground : theme.bzText2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
