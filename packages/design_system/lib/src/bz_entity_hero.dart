import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'bz_hero_chrome.dart';
import 'bz_theme.dart';
import 'bz_ambient_backdrop.dart';
import 'tokens.dart';

/// BzEntityHero — the album/playlist/artist page header.
///
/// "Content is the colour": the cover blooms behind the chrome via
/// [BzAmbientBackdrop], a 168px cover anchors the layout, the meta
/// chip and Play/Shuffle glass buttons sit directly on the artwork.
/// Below it, the caller places the fill list panel.
class BzEntityHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final String? metaLabel;
  final IconData? metaIcon;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;
  final Widget? below;

  const BzEntityHero({
    super.key,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    this.metaLabel,
    this.metaIcon,
    this.onPlayAll,
    this.onShuffle,
    this.below,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BzAmbientBackdrop(
      artworkUrl: artworkUrl,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover — 168px, token radius, bordered like glass.
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(BzRadius.artwork),
                      border: Border.all(color: theme.bzSeparator),
                      color: theme.bzFillBase,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: artworkUrl != null
                        ? Image.network(
                            artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.album_outlined,
                                  size: 56, color: theme.bzText2),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.album_outlined,
                                size: 56, color: theme.bzText2),
                          ),
                  ),
                  const SizedBox(width: 20),
                  // Title block
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: BzType.title1,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: theme.bzText1,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: BzType.subheadline,
                                color: theme.bzText2,
                              ),
                            ),
                          ],
                          if (metaLabel != null) ...[
                            const SizedBox(height: 12),
                            BzHeroChip(
                              label: metaLabel!,
                              icon: metaIcon,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action row — directly on the artwork-driven backdrop.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  BzGlassButton(
                    label: 'Play all',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onPlayAll,
                  ),
                  const SizedBox(width: 10),
                  BzGlassButton(
                    label: 'Shuffle',
                    icon: Icons.shuffle_rounded,
                    variant: BzGlassButtonVariant.glass,
                    onPressed: onShuffle,
                  ),
                ],
              ),
            ),
            // Caller content (track list panel, etc.)
            if (below != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: below,
                ),
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
