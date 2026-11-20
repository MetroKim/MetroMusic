import 'package:flutter/material.dart';

import 'widgets/breezze_app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // JSON → SQLite one-shot migration happens inside the shell's
  // container (see breezze_shell.dart) — it needs the Riverpod
  // container the app actually runs with.
  runApp(const BreezzeAppRoot());
}
