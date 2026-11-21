import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local, device-scoped search history. Search terms are personal UI state,
/// not catalog data, so they stay on this device and are never synced.
class SearchHistoryStore {
  SearchHistoryStore({Future<File> Function()? fileProvider})
      : _fileProvider = fileProvider ?? _defaultFile;

  static const int maxEntries = 10;
  static const String _fileName = 'breezze_search_history.json';

  final Future<File> Function() _fileProvider;
  Future<void> _mutationQueue = Future<void>.value();

  static Future<File> _defaultFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<String>> load() async {
    // Wait for queued mutations so callers never observe a partially written
    // or stale snapshot while an add/remove/clear operation is in progress.
    await _mutationQueue;
    return _load();
  }

  Future<List<String>> _load() async {
    try {
      final file = await _fileProvider();
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];

      final seen = <String>{};
      final entries = <String>[];
      for (final value in decoded) {
        if (value is! String) continue;
        final query = value.trim();
        if (query.isEmpty || !seen.add(query.toLowerCase())) continue;
        entries.add(query);
        if (entries.length == maxEntries) break;
      }
      return entries;
    } on FormatException {
      return const [];
    } on FileSystemException {
      return const [];
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _mutationQueue.then((_) => operation());
    // Keep the queue alive after a failed write while still returning the
    // original error to the caller.
    _mutationQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<List<String>> add(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return load();

    return _serialize(() async {
      final current = await _load();
      final next = [
        normalized,
        ...current.where(
          (entry) => entry.toLowerCase() != normalized.toLowerCase(),
        ),
      ].take(maxEntries).toList(growable: false);
      await _write(next);
      return next;
    });
  }

  Future<List<String>> remove(String query) => _serialize(() async {
        final current = await _load();
        final next = current
            .where((entry) => entry.toLowerCase() != query.toLowerCase())
            .toList(growable: false);
        await _write(next);
        return next;
      });

  Future<void> clear() => _serialize(() => _write(const []));

  Future<void> _write(List<String> entries) async {
    final file = await _fileProvider();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(entries), flush: true);
  }
}
