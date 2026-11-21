import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/catalog/catalog_screens.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_screen.dart';
import '../features/player/player_controller.dart';
import 'bz_brand_icons.dart';

/// Persistent application shell. The IndexedStack keeps destination state
/// alive while the single global PlayerController owns playback.
class BzShell extends ConsumerStatefulWidget {
  const BzShell({super.key});

  @override
  ConsumerState<BzShell> createState() => _BzShellState();
}

class _BzShellState extends ConsumerState<BzShell> {
  int _index = 0;

  static const _tabs = [
    ('Home', Icons.home_outlined),
    ('Browse', Icons.explore_outlined),
    ('Radio', Icons.radio_outlined),
    ('Library', Icons.library_music_outlined),
    ('Search', Icons.search),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    final destinations = const [
      HomeScreen(),
      BrowseScreen(),
      RadioScreen(),
      LibraryScreen(),
      SearchScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (value) => setState(() => _index = value),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: BzBnoteMark(size: 34, color: Theme.of(context).bzText1),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: Text('Browse'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.radio_outlined),
                    selectedIcon: Icon(Icons.radio),
                    label: Text('Radio'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: Text('Library'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: destinations,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.playbackState != PlaybackState.idle)
            _MiniPlayer(
              playerState: player,
              controller: controller,
              onExpand: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).bzBackground,
                builder: (_) => const FractionallySizedBox(
                  heightFactor: 0.96,
                  child: NowPlayingScreen(),
                ),
              ),
            ),
          if (!wide) ...[
            const SizedBox(height: 10),
            _BzTabBar(
              index: _index,
              onChanged: (value) => setState(() => _index = value),
              tabs: _tabs,
            ),
          ],
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                heightFactor: 1,
                child: TextButton.icon(
                  onPressed: () => setState(() => _index = 0),
                  icon: const Icon(Icons.music_note, size: 16),
                  label: const Text('Breezze'),
                ),
              ),
            ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final PlayerState playerState;
  final PlayerController controller;
  final VoidCallback onExpand;

  const _MiniPlayer({
    required this.playerState,
    required this.controller,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playing = playerState.playbackState == PlaybackState.playing;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExpand,
        borderRadius: BorderRadius.circular(BzRadius.card),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.bzAtmoRegular,
            borderRadius: BorderRadius.circular(BzRadius.card),
            border: Border.all(color: theme.bzSeparator),
          ),
          child: Row(
            children: [
              BzBnoteMark(size: 34, color: theme.bzText1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Now Playing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: playerState.duration == Duration.zero
                            ? 0
                            : (playerState.position.inMilliseconds /
                                    playerState.duration.inMilliseconds)
                                .clamp(0.0, 1.0),
                        minHeight: 2,
                        backgroundColor: theme.bzSeparator,
                        color: theme.bzText1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: playing ? 'Pause' : 'Play',
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: controller.togglePlayPause,
                color: theme.bzText1,
              ),
              IconButton(
                tooltip: 'Next track',
                icon: const Icon(Icons.skip_next),
                onPressed: controller.next,
                color: theme.bzText1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BzTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<(String, IconData)> tabs;

  const _BzTabBar({
    required this.index,
    required this.onChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.bzAtmoRegular,
        borderRadius: BorderRadius.circular(BzRadius.capsule),
        border: Border.all(color: theme.bzSeparator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _BzTab(
                label: tabs[i].$1,
                icon: tabs[i].$2,
                active: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BzTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _BzTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = active ? theme.bzBackground : theme.bzText2;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: BzMotion.fastMs),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: active ? theme.bzText1 : Colors.transparent,
          borderRadius: BorderRadius.circular(BzRadius.capsule),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BzRadius.capsule),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: BzType.subheadline,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
