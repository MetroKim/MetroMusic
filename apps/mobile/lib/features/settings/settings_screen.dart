import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_session.dart';
import '../../widgets/bz_brand_icons.dart';

/// Settings — audio quality, playback, downloads, account (§19).
/// Breezze is fully free: no membership or upgrade UI anywhere.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authSessionProvider);
    final email = auth is AuthSignedIn ? auth.email : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 220),
        children: [
          Text('Settings', style: theme.textTheme.displayMedium),
          const SizedBox(height: 16),
          _section(theme, 'Account', [
            ListTile(
              leading: BzBnoteMark(size: 28, color: theme.bzText1),
              title: Text(email ?? 'Not signed in'),
              subtitle: Text('Breezze — free for everyone',
                  style: theme.textTheme.bodySmall),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                ref.read(authSessionProvider.notifier).signOut();
              },
            ),
          ]),
          _section(theme, 'Audio Quality', [
            _qualityPicker(theme, 'Streaming Quality'),
            _qualityPicker(theme, 'Download Quality'),
          ]),
          _section(theme, 'Playback', [
            _switchTile(theme, 'Gapless Playback', true),
            _switchTile(theme, 'AutoMix', false),
            _switchTile(theme, 'Sound Check', false),
          ]),
          _section(theme, 'Downloads', [
            _switchTile(theme, 'Download over Wi-Fi only', true),
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
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: BzType.footnote,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.bzText2)),
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

  Widget _qualityPicker(ThemeData theme, String title) {
    return ListTile(
      title: Text(title),
      trailing: const Text('High'),
      onTap: () {},
    );
  }

  Widget _switchTile(ThemeData theme, String title, bool initial) {
    return _SwitchRow(title: title, initial: initial);
  }
}

class _SwitchRow extends StatefulWidget {
  final String title;
  final bool initial;

  const _SwitchRow({required this.title, required this.initial});

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      title: Text(widget.title),
      dense: true,
    );
  }
}
