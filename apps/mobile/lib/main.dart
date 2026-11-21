import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap.dart';
import 'features/player/player_controller.dart';
import 'widgets/bz_shell.dart';

void main() {
  final container = ProviderContainer(
    overrides: [
      playbackResolverProvider.overrideWith(
        (ref) => ref.watch(liveResolverProvider),
      ),
    ],
  );

  attachPlaybackEngine(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BreezzeApp(),
    ),
  );
}

class BreezzeApp extends StatelessWidget {
  const BreezzeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breezze',
      debugShowCheckedModeBanner: false,
      theme: bzLightTheme(),
      darkTheme: bzDarkTheme(),
      home: const BzShell(),
    );
  }
}
