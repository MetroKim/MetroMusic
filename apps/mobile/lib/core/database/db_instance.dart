import 'breezze_database.dart';

/// Global lazy singleton for call sites that construct stores directly
/// (RecentStore is instantiated in screens, not only via providers).
/// Provider-based code uses database_providers.dart instead; both hit
/// the same underlying NativeDatabase file.
BreezzeDatabase? _instance;

BreezzeDatabase get breezzeDb => _instance ??= BreezzeDatabase.open();
