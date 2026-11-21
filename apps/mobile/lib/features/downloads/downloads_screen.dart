import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bz_brand_icons.dart';

/// Downloads section. The current UI is a scaffold; connect it to
/// DownloadManager job state before showing actual user download records.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Text('Downloads', style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Music saved for offline listening.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.bzSurface1,
              borderRadius: BorderRadius.circular(BzRadius.card),
              border: Border.all(color: theme.bzSeparator),
            ),
            child: Column(
              children: [
                BzBnoteMark(size: 42, color: theme.bzText2),
                const SizedBox(height: 16),
                Text('No downloads yet',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'When offline downloads are enabled for a track, '
                  'it will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
