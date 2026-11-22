import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/features/azkar/model/set_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Zikr zikr(String id, int count) => Zikr(
    id: id,
    arabic: '',
    transliteration: '',
    translation: '',
    source: (en: '', ar: ''),
    grading: null,
    count: count,
    quran: false,
  );
  final items = [zikr('a', 1), zikr('b', 3), zikr('c', 1)];

  test('opens at the first card not done, or the last when all are', () {
    expect(SetState.openAt(items, {}).index, 0);
    expect(SetState.openAt(items, {'a': 1, 'b': 2}).index, 1);
    expect(SetState.openAt(items, {'a': 1, 'c': 1}).index, 1);
    expect(SetState.openAt(items, {'a': 1, 'b': 3, 'c': 1}).index, 2);
  });

  test('a tap below the count counts, the one at the count is done', () {
    final (counted, what) = const SetState(1, {'a': 1}).tap(items);
    expect((counted.counts['b'], what), (1, SetTap.counted));

    final (done, last) = const SetState(1, {'a': 1, 'b': 2}).tap(items);
    expect((done.counts['b'], last), (3, SetTap.done));
  });

  test('the tap after done moves to the next card without counting', () {
    final (moved, what) = const SetState(0, {'a': 1}).tap(items);
    expect((moved.index, what), (1, SetTap.moved));
    expect(moved.counts, {'a': 1});
  });

  test('a done last card takes the tap and does nothing', () {
    const state = SetState(2, {'a': 1, 'b': 1, 'c': 1});
    final (same, what) = state.tap(items);
    expect((same.index, what), (2, SetTap.none));
    expect(same.counts, state.counts);
  });

  test('the tap that finishes every card is the set\'s, once', () {
    final (done, what) = const SetState(2, {'a': 1, 'b': 3}).tap(items);
    expect(what, SetTap.setDone);
    expect(done.allDone(items), isTrue);

    final (_, after) = done.tap(items);
    expect(after, SetTap.none);
  });

  test('a card finished out of order still ends the set on the last one done', () {
    final (_, what) = const SetState(0, {'b': 3, 'c': 1}).tap(items);
    expect(what, SetTap.setDone);
  });

  test('never counts past the zikr\'s count', () {
    var state = SetState.openAt(items, {});
    for (var i = 0; i < 20; i++) {
      state = state.tap(items).$1;
      for (final zikr in items) {
        expect(state.countOf(zikr), lessThanOrEqualTo(zikr.count));
      }
    }
    expect(state.allDone(items), isTrue);
  });
}
