import 'package:better_muslim/features/quran/domain/kashida.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('where a kashida goes', () {
    test('at the last joining point, after the letter and its marks', () {
      /// بَقَرَةٞ: the ra doesn't join, so it goes between the qaf's fatha and the ra
      expect(kashida('بَقَرَةٞ', 1), 'بَقَـرَةٞ');
      expect(kashida('ٱلۡكِتَٰبُ', 2), 'ٱلۡكِتَٰــبُ');
      expect(kashida('يُؤۡمِنُونَ', 1), 'يُؤۡمِنُـونَ');
    });

    test('never inside لا or the name of Allah', () {
      expect(kashidaPoint('ٱللَّهِ'), isNull);
      expect(kashidaPoint('لِلَّهِ'), isNull);
      expect(kashidaPoint('وَٱللَّهُ'), isNull);

      /// لَا alone has nowhere, in a longer word the point moves before it
      expect(kashidaPoint('لَا'), isNull);
      expect(kashida('فَلَا', 1), 'فَـلَا');
    });

    test('never across a small waw or yeh', () {
      /// لَهُۥ: the small waw after the heh is a letter, the kashida goes between lam and heh
      expect(kashida('لَهُۥ', 1), 'لَـهُۥ');
      expect(kashida('بِهِۦ', 1), 'بِـهِۦ');
    });

    test('a word with no joining letter stays as it is', () {
      expect(kashidaPoint('وَرَدَ'), isNull);
      expect(kashida('وَرَدَ', 3), 'وَرَدَ');
      expect(kashida('بَقَرَةٞ', 0), 'بَقَرَةٞ');
    });
  });

  group('how a line shares them', () {
    test('one at a time, longest first, until the gaps fit', () {
      /// 3 words of 100, 60 and 80 on 300: 60 over at gaps of 10 is 2 kashidas of 20
      final counts = shareKashidas(
        widths: [100, 60, 80],
        stretchable: [true, true, true],
        width: 300,
        cap: 10,
        tatweel: 20,
      );
      expect(counts, [1, 0, 1]);
    });

    test('at most 3 a word, words that can take none are skipped, the gaps take the rest', () {
      final counts = shareKashidas(
        widths: [100, 50],
        stretchable: [false, true],
        width: 400,
        cap: 10,
        tatweel: 20,
      );
      expect(counts, [0, maxKashidas]);
    });

    test('a line already narrow enough takes none', () {
      expect(
        shareKashidas(
          widths: [140, 140],
          stretchable: [true, true],
          width: 300,
          cap: 30,
          tatweel: 20,
        ),
        [0, 0],
      );
      expect(shareKashidas(widths: [100], stretchable: [true], width: 300, cap: 10, tatweel: 20), [
        0,
      ], reason: 'one word is centered, never stretched');
    });
  });
}
