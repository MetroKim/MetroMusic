import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bz_brand_icons.dart';

/// Settings scaffold. Persist each preference and enforce entitlements
/// through the backend before exposing production controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 180),
        children: [
          Text('Settings', style: theme.textTheme.displayMedium),
          const SizedBox(height: 24),
          _section(theme, 'Audio Quality', [
            const _SettingRow(title: 'Streaming Quality', value: 'High'),
            const _SettingRow(title: 'Download Quality', value: 'High'),
          ]),
          _section(theme, 'Playback', [
            const _SettingRow(title: 'Gapless Playback', value: 'Available'),
            const _SettingRow(title: 'Crossfade', value: 'Off'),
            const _SettingRow(title: 'Automix', value: 'Unavailable'),
          ]),
          _section(theme, 'Downloads', [
            const _SettingRow(title: 'Download over Wi-Fi only', value: 'On'),
          ]),
          _section(theme, 'Account', [
            ListTile(
              leading: BzBnoteMark(size: 28, color: theme.bzAccent),
              title: const Text('Account and privacy'),
              subtitle: const Text('Manage profile, history and data'),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: BzType.footnote,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.bzText2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.bzSurface1,
            borderRadius: BorderRadius.circular(BzRadius.card),
            border: Border.all(color: theme.bzSeparator),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(title),
        trailing: Text(value),
      );
}
