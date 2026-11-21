import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'features/player/player_controller.dart';
import 'widgets/breezze_app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        playbackResolverProvider.overrideWith(
          (ref) => ref.watch(liveResolverProvider),
        ),
      ],
      child: const BreezzeAppRoot(),
    ),
  );
}
