import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a range from 1:1 to the end of the surah plays every ayah once', () {
    expect(recitationQueue(const AyahKey(1, 1), const AyahKey(1, 7)), [
      for (var ayah = 1; ayah <= 7; ayah++) AyahKey(1, ayah),
    ]);
  });

  test('the bismillah comes first on every surah but 1 and 9', () {
    expect(recitationQueue(const AyahKey(2, 1), const AyahKey(2, 2)), const [
      AyahKey(2, 0),
      AyahKey(2, 1),
      AyahKey(2, 2),
    ]);
    expect(recitationQueue(const AyahKey(9, 1), const AyahKey(9, 1)), const [AyahKey(9, 1)]);
    expect(recitationQueue(const AyahKey(1, 1), const AyahKey(1, 1)), const [AyahKey(1, 1)]);

    /// from the middle of a surah there is no bismillah
    expect(recitationQueue(const AyahKey(2, 5), const AyahKey(2, 5)), const [AyahKey(2, 5)]);
    expect(recitationFile(const AyahKey(2, 0)), const AyahKey(1, 1));
    expect(recitationFile(const AyahKey(2, 5)), const AyahKey(2, 5));
  });

  test('repeat 3 puts each ayah 3 times, the bismillah once', () {
    expect(recitationQueue(const AyahKey(112, 1), const AyahKey(112, 2), repeat: 3), const [
      AyahKey(112, 0),
      AyahKey(112, 1),
      AyahKey(112, 1),
      AyahKey(112, 1),
      AyahKey(112, 2),
      AyahKey(112, 2),
      AyahKey(112, 2),
    ]);
  });

  test('the pause waits between different ayahs only', () {
    final queue = recitationQueue(const AyahKey(1, 1), const AyahKey(1, 2), repeat: 2);
    expect(
      [for (var i = 0; i < queue.length; i++) pausesBefore(queue, i)],
      [false, false, true, false],
    );
  });

  test('the end of the range is the end of the queue', () {
    final queue = recitationQueue(const AyahKey(1, 3), const AyahKey(1, 4));
    expect(queue, const [AyahKey(1, 3), AyahKey(1, 4)]);
    expect(nextAyahIndex(queue, 1), isNull);
  });

  test('sleep at the end of the surah stops after the last ayah only', () {
    final queue = recitationQueue(const AyahKey(1, 6), const AyahKey(1, 7), repeat: 2);
    const end = SleepTimer.endOfSurah();
    expect(
      [for (var i = 0; i < queue.length; i++) sleepsAfter(queue, i, end)],
      [false, false, false, true],
    );
    expect(sleepsAfter(queue, 3, const SleepTimer.off()), isFalse);
    expect(sleepsAfter(queue, 3, const SleepTimer.after(Duration(minutes: 5))), isFalse);
  });

  test('next and previous skip a whole repeat', () {
    final queue = recitationQueue(const AyahKey(1, 1), const AyahKey(1, 3), repeat: 2);
    expect(nextAyahIndex(queue, 0), 2);
    expect(nextAyahIndex(queue, 1), 2);
    expect(previousAyahIndex(queue, 3), 0);
    expect(previousAyahIndex(queue, 4), 2);
    expect(previousAyahIndex(queue, 1), isNull);
  });

  test('following turns off on another page and back on on the playing one', () {
    expect(following(shownPage: 2, playingPage: 2), isTrue);
    expect(following(shownPage: 3, playingPage: 2), isFalse);
    expect(following(shownPage: 2, playingPage: 2), isTrue);
  });

  test('last read follows the playing ayah, the bismillah reads as ayah 1', () {
    expect(readAyah(const AyahKey(2, 5)), const AyahKey(2, 5));
    expect(readAyah(const AyahKey(2, 0)), const AyahKey(2, 1));
  });

  group('±10 s', () {
    /// al-ikhlas: the bismillah then 4 ayahs, each 6 s long
    final queue = recitationQueue(const AyahKey(112, 1), const AyahKey(112, 4));
    Future<Duration> six(int index) async => const Duration(seconds: 6);
    Future<({int index, Duration position})?> seek(int index, int at, int by) =>
        seekAcross(queue, index, Duration(seconds: at), Duration(seconds: by), six);

    test('inside an ayah it moves through the audio', () async {
      expect(await seek(2, 1, 4), (index: 2, position: const Duration(seconds: 5)));
    });

    test('+10 past the end goes into the next ayahs by what is left over', () async {
      expect(await seek(1, 4, 10), (index: 3, position: const Duration(seconds: 2)));
    });

    test('-10 before the start goes back into the previous ayahs the same way', () async {
      expect(await seek(3, 2, -10), (index: 1, position: const Duration(seconds: 4)));
    });

    test("on the queue's first item -10 stops at its start, on the last +10 ends it", () async {
      expect(await seek(0, 3, -10), (index: 0, position: Duration.zero));
      expect(await seek(4, 3, 10), isNull);
    });

    test('each repeat counts as its own play', () async {
      final repeated = recitationQueue(const AyahKey(1, 1), const AyahKey(1, 2), repeat: 2);
      expect(
        await seekAcross(repeated, 0, const Duration(seconds: 4), const Duration(seconds: 10), six),
        (index: 2, position: const Duration(seconds: 2)),
      );
    });
  });

  group('the ayah bar', () {
    test('a drag picks the ayah under the finger, ends included', () {
      const from = AyahKey(2, 10);
      const to = AyahKey(2, 20);
      expect(dragAyah(0, from: from, to: to), 10);
      expect(dragAyah(.5, from: from, to: to), 15);
      expect(dragAyah(1, from: from, to: to), 20);
      expect(dragAyah(-.3, from: from, to: to), 10);
      expect(dragAyah(1.4, from: from, to: to), 20);
    });

    test('it fills by the playing ayah in the range, the bismillah as the first', () {
      const from = AyahKey(112, 1);
      const to = AyahKey(112, 4);
      expect(rangeProgress(const AyahKey(112, 0), from: from, to: to), .25);
      expect(rangeProgress(const AyahKey(112, 2), from: from, to: to), .5);
      expect(rangeProgress(const AyahKey(112, 4), from: from, to: to), 1);
    });

    test('a drag seeks to the first play of that ayah, after the bismillah', () {
      final queue = recitationQueue(const AyahKey(112, 1), const AyahKey(112, 4), repeat: 2);
      expect(queue.indexOf(const AyahKey(112, 1)), 1);
      expect(queue.indexOf(const AyahKey(112, 3)), 5);
    });
  });

  group('surah loop', () {
    test('the repeat button cycles off, 2, 3, 5, 10, surah loop', () {
      expect(reciteRepeats, [1, 2, 3, 5, 10, surahLoop]);
    });

    test('each ayah plays once, the bismillah first as on the first play', () {
      expect(
        recitationQueue(const AyahKey(112, 1), const AyahKey(112, 2), repeat: surahLoop),
        const [AyahKey(112, 0), AyahKey(112, 1), AyahKey(112, 2)],
      );
    });

    test('the range starts again when it ends, unless the sleep timer ends it there', () {
      expect(startsAgain(surahLoop, const SleepTimer.off()), isTrue);
      expect(startsAgain(surahLoop, const SleepTimer.after(Duration(minutes: 5))), isTrue);
      expect(startsAgain(surahLoop, const SleepTimer.endOfSurah()), isFalse);
      expect(startsAgain(3, const SleepTimer.off()), isFalse);
    });
  });
}
