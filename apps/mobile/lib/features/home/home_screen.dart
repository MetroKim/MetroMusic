import 'package:flutter/material.dart';
import 'package:breezze_design_system/breezze_design_system.dart';
import '../../widgets/bz_brand_icons.dart';

/// Personalized hub; no fabricated catalog content is shown.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Row(children: [
            BzRibbonLogo(width: 92, color: theme.bzText1),
            const Spacer(),
            IconButton(
              tooltip: 'Profile',
              onPressed: () {},
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ]),
          const SizedBox(height: 28),
          Text('Listen Now', style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Your music, gathered in one place.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.bzSurface1,
              borderRadius: BorderRadius.circular(BzRadius.modal),
              border: Border.all(color: theme.bzSeparator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.headphones_outlined,
                    size: 30, color: theme.bzText2),
                const SizedBox(height: 18),
                Text('Your listening starts here',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Explore music and start playing a track. Your recent '
                  'listening and personal mixes will appear here as your '
                  'library grows.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _HomeSection(
            title: 'Recently Played',
            message: 'Tracks you listen to will appear here.',
          ),
          const SizedBox(height: 20),
          const _HomeSection(
            title: 'Made For You',
            message: 'Personalized mixes will appear when recommendations '
                'are available.',
          ),
          const SizedBox(height: 20),
          const _HomeSection(
            title: 'New Releases',
            message: 'New music from connected catalog sources will appear here.',
          ),
        ],
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  final String title;
  final String message;

  const _HomeSection({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.bzSurface1,
            borderRadius: BorderRadius.circular(BzRadius.card),
            border: Border.all(color: theme.bzSeparator),
          ),
          child: Text(message, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
