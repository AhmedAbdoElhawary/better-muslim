/// the tatweels a justified line's words stretch by, so its gaps stay narrow (ADR 0003)
const kashidaTatweel = 'ـ';

/// a justified line's widest gap, in spaces
const kashidaGap = 1.5;
const maxKashidas = 3;

/// letters that join the letter after them
const _joins = 'بتثجحخسشصضطظعغفقكلمنهيئىٮڡٯ$kashidaTatweel';
const _alefs = 'اأإآٱ';

/// a small waw or yeh stands for a letter of its own
const _small = ['ۥ', 'ۦ'];

bool _letter(int c) =>
    (c >= 0x0621 && c <= 0x063A) ||
    (c >= 0x0640 && c <= 0x064A) ||
    c == 0x066E ||
    c == 0x066F ||
    (c >= 0x0671 && c <= 0x06D3);

/// where a kashida goes in the word: its last joining point, after the letter's marks. never inside
/// لا, the name of Allah or across a small waw or yeh, null when it has nowhere
int? kashidaPoint(String word) {
  final skeleton = String.fromCharCodes(word.codeUnits.where(_letter));
  if (skeleton.contains('لله')) return null;
  for (var i = word.length - 1; i > 0; i--) {
    if (!_letter(word.codeUnitAt(i)) || word[i] == 'ء') continue;
    var j = i - 1;
    while (j >= 0 && !_letter(word.codeUnitAt(j))) {
      j--;
    }
    if (j < 0) return null;
    if (!_joins.contains(word[j])) continue;
    if (word[j] == 'ل' && _alefs.contains(word[i])) continue;
    final marks = word.substring(j + 1, i);
    if (_small.any(marks.contains)) continue;
    return i;
  }
  return null;
}

/// the word with n kashidas at its point, as it is when it has none
String kashida(String word, int n) {
  final at = kashidaPoint(word);
  return at == null || n == 0 ? word : word.replaceRange(at, at, kashidaTatweel * n);
}

/// how many kashidas each word of a justified line takes: one at a time across the words that can
/// take one, longest first, at most 3 a word, until the gaps are at most cap wide. tatweel is one
/// kashida's width. what is still left over goes into the gaps
List<int> shareKashidas({
  required List<double> widths,
  required List<bool> stretchable,
  required double width,
  required double cap,
  required double tatweel,
}) {
  final counts = List.filled(widths.length, 0);
  if (widths.length < 2 || tatweel <= 0) return counts;
  var need = width - widths.fold(0.0, (sum, w) => sum + w) - cap * (widths.length - 1);
  final order = [
    for (var i = 0; i < widths.length; i++)
      if (stretchable[i]) i,
  ]..sort((a, b) => widths[b].compareTo(widths[a]));
  for (var round = 0; round < maxKashidas && need > 0; round++) {
    for (final i in order) {
      if (need <= 0) break;
      counts[i]++;
      need -= tatweel;
    }
  }
  return counts;
}
