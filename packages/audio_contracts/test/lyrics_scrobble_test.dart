import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

const sample = '''
[00:01.00]First line
[00:03.50]Second <00:03.60>word <00:03.80>sync
[00:06.00]Third line
''';

void main() {
  group('LrcParser (§10.1)', () {
    test('parses lines sorted with end = next start', () {
      final lyrics = LrcParser.parse('t1', sample);
      expect(lyrics.lines.length, 3);
      expect(lyrics.lines[0].start, const Duration(seconds: 1));
      expect(lyrics.lines[1].start, const Duration(milliseconds: 3500));
      expect(lyrics.lines[2].start, const Duration(seconds: 6));
      expect(lyrics.lines[0].end, const Duration(milliseconds: 3500));
      expect(lyrics.lines[1].end, const Duration(seconds: 6));
    });

    test('parses word-level sync', () {
      final lyrics = LrcParser.parse('t1', sample);
      final second = lyrics.lines[1];
      expect(second.words.length, 2);
      expect(second.words[0].text, 'word');
      expect(second.words[0].start, const Duration(milliseconds: 3600));
      expect(second.words[1].text, 'sync');
      expect(second.words[1].start, const Duration(milliseconds: 3800));
    });

    test('active line binary search', () {
      final lyrics = LrcParser.parse('t1', sample);
      expect(lyrics.activeLineIndex(const Duration(seconds: 1)), 0);
      expect(lyrics.activeLineIndex(const Duration(milliseconds: 3600)), 1);
      expect(lyrics.activeLineIndex(const Duration(seconds: 7)), 2);
      expect(lyrics.activeLineIndex(const Duration(milliseconds: 500)), -1);
    });

    test('active word within line', () {
      final lyrics = LrcParser.parse('t1', sample);
      final idx = lyrics.activeLineIndex(const Duration(milliseconds: 3700));
      expect(lyrics.activeWordIndex(idx, const Duration(milliseconds: 3700)), 0);
    });

    test('ignores metadata and plain text', () {
      final lyrics = LrcParser.parse(
          't1', '[ar:Artist]\n[ti:Title]\nplain junk\n[00:01.00]Real');
      expect(lyrics.lines.length, 1);
      expect(lyrics.lines[0].text, 'Real');
    });
  });

  group('ScrobbleBus (§30)', () {
    test('enforces the 30-second rule', () {
      final submitted = <String>[];
      final bus = ScrobbleBus();
      bus.register(_RecordingScrobbler(submitted));

      final start = DateTime.utc(2026, 11, 17);
      bus.onPlay('t1', start);
      for (var i = 1; i <= 29; i++) {
        bus.onTick('t1', start.add(Duration(seconds: i)));
      }
      expect(submitted, isEmpty); // 29 s: below threshold

      bus.onTick('t1', start.add(const Duration(seconds: 30)));
      expect(submitted, ['t1']); // 30 s: fires
    });

    test('does not double submit', () {
      final submitted = <String>[];
      final bus = ScrobbleBus();
      bus.register(_RecordingScrobbler(submitted));

      final start = DateTime.utc(2026, 11, 17);
      bus.onPlay('t1', start);
      // ScrobbleBus intentionally caps each tick at two seconds so a long
      // scheduler pause cannot count as thirty seconds of listening.
      for (var tick = 1; tick <= 15; tick++) {
        bus.onTick('t1', start.add(Duration(seconds: tick * 2)));
      }
      bus.onTick('t1', start.add(const Duration(seconds: 32)));
      expect(submitted.length, 1);
    });
  });
}

class _RecordingScrobbler implements Scrobbler {
  final List<String> sink;
  _RecordingScrobbler(this.sink);

  @override
  String get id => 'recorder';

  @override
  Future<void> submit({required String trackId, required DateTime playedAtUtc}) async {
    sink.add(trackId);
  }
}
