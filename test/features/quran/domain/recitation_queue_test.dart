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
}
