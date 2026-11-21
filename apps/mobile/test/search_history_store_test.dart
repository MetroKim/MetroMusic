import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:breezze/app/search_history_store.dart';

void main() {
  late Directory directory;
  late SearchHistoryStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('breezze-search-');
    store = SearchHistoryStore(
      fileProvider: () async => File('${directory.path}/history.json'),
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('stores newest query first and de-duplicates case-insensitively',
      () async {
    await store.add('Adele');
    await store.add('Coldplay');
    await store.add('adele');

    expect(await store.load(), ['adele', 'Coldplay']);
  });

  test('caps history at ten entries', () async {
    for (var i = 0; i < 12; i++) {
      await store.add('query $i');
    }

    final history = await store.load();
    expect(history, hasLength(10));
    expect(history.first, 'query 11');
    expect(history.last, 'query 2');
  });

  test('removes one query and clears all queries', () async {
    await store.add('Adele');
    await store.add('Coldplay');

    expect(await store.remove('ADELE'), ['Coldplay']);
    await store.clear();
    expect(await store.load(), isEmpty);
  });

  test('serializes concurrent adds without losing updates', () async {
    await Future.wait([
      for (var i = 0; i < 20; i++) store.add('query $i'),
    ]);

    final history = await store.load();
    expect(history, hasLength(10));
    expect(history.first, 'query 19');
    expect(history.last, 'query 10');
  });

  test('trims whitespace and preserves Unicode search terms', () async {
    await store.add('  Beyoncé  ');
    await store.add('   ');

    expect(await store.load(), ['Beyoncé']);
  });

  test('ignores malformed history data', () async {
    final file = File('${directory.path}/history.json');
    await file.writeAsString('{not-json');

    expect(await store.load(), isEmpty);
  });
}
