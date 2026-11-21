import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

QueueEntry entry(String id, {String origin = 'manual'}) => QueueEntry(
      entryId: id,
      trackId: 'track-$id',
      origin: origin,
      sourceContext: 'Test Album',
      insertedAtMs: DateTime.now().millisecondsSinceEpoch,
      trackVersion: 'v1',
    );

void main() {
  group('QueueManager (§53.4)', () {
    test('replaceWith sets current at startIndex', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      expect(q.current!.entryId, 'a');
      expect(q.upNext.map((e) => e.entryId), ['b', 'c']);
    });

    test('playNext inserts after current', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      q.playNext(entry('x'));
      expect(q.upNext.map((e) => e.entryId), ['x', 'b', 'c']);
    });

    test('playLast appends at end', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b')]);
      q.playLast(entry('z'));
      expect(q.upNext.map((e) => e.entryId), ['b', 'z']);
    });

    test('advance walks the queue; null at the end without repeat', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b')]);
      expect(q.advance()!.entryId, 'b');
      expect(q.advance(), isNull);
    });

    test('repeatOne returns the same entry', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b')]);
      q.repeatMode = RepeatMode.repeatOne;
      expect(q.advance()!.entryId, 'a'); // current item repeats immediately
      expect(q.advance()!.entryId, 'a'); // and remains the same
    });

    test('repeatAll wraps to the first entry', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b')]);
      q.repeatMode = RepeatMode.repeatAll;
      q.advance();
      expect(q.advance()!.entryId, 'a');
    });

    test('previous walks back; stays at first without repeat', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b')]);
      q.advance();
      expect(q.previous()!.entryId, 'a');
      expect(q.previous()!.entryId, 'a'); // stays
    });

    test('remove adjusts current index', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      q.remove('a');
      expect(q.current!.entryId, 'b');
    });

    test('reorder keeps stable entry IDs and current', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      q.reorder('c', 1); // a, c, b
      expect(q.upNext.map((e) => e.entryId), ['c', 'b']);
      expect(q.current!.entryId, 'a');
    });

    test('clear keeps current when asked', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      q.clear(keepCurrent: true);
      expect(q.current!.entryId, 'a');
      expect(q.upNext, isEmpty);
    });

 
    test('shuffle advances through every unplayed entry without falling back to sequential mode', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c'), entry('d')]);
      q.toggleShuffle();

      final visited = <String>{q.current!.entryId};
      for (var i = 0; i < 3; i++) {
        final next = q.advance();
        expect(next, isNotNull);
        visited.add(next!.entryId);
      }

      expect(visited, {'a', 'b', 'c', 'd'});
      expect(q.advance(), isNull);
    });

    test('shuffle repeat-all wraps to the first item in the shuffled cycle', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c')]);
      q.toggleShuffle();
      final first = q.current!.entryId;
      q.repeatMode = RepeatMode.repeatAll;

      q.advance();
      q.advance();
      expect(q.advance()!.entryId, first);
    });

    test('shuffle toggle preserves unplayed entries set', () {
      final q = QueueManager();
      q.replaceWith([entry('a'), entry('b'), entry('c'), entry('d')]);
      q.toggleShuffle();
      expect(q.upNext.length, 3);
      expect(q.upNext.map((e) => e.entryId).toSet(),
          {'b', 'c', 'd'});
      q.toggleShuffle();
      expect(q.upNext.map((e) => e.entryId), ['b', 'c', 'd']);
    });
  });
}
