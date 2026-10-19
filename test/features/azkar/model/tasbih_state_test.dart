import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:better_muslim/features/azkar/model/tasbih_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the targets are 33, 33 and 34', () {
    expect(tasbihDhikr.map((dhikr) => dhikr.target), [33, 33, 34]);
  });

  test('a tap below the target counts one', () {
    expect(const TasbihState(0, 16).tap(), const TasbihState(0, 17));
    expect(const TasbihState(0, 16).tap().done, isFalse);
  });

  test('the tap that reaches the target is done', () {
    expect(const TasbihState(0, 32).tap(), const TasbihState(0, 33));
    expect(const TasbihState(0, 32).tap().done, isTrue);
  });

  test('the tap after done starts the next dhikr at 1', () {
    expect(const TasbihState(0, 33).tap(), const TasbihState(1, 1));
    expect(const TasbihState(1, 33).tap(), const TasbihState(2, 1));
  });

  test('after allahu akbar subhanallah at 1', () {
    expect(const TasbihState(2, 34).tap(), const TasbihState(0, 1));
    expect(const TasbihState(2, 33).tap(), const TasbihState(2, 34));
  });

  test('a chip starts its dhikr from 0, reset goes to subhanallah 0', () {
    expect(const TasbihState(0, 20).select(2), const TasbihState(2, 0));
    expect(const TasbihState(2, 20).reset(), const TasbihState(0, 0));
  });

  test('20 taps from 0 give 20, and the count never passes the target', () {
    var state = const TasbihState(0, 0);
    for (var i = 0; i < 20; i++) {
      state = state.tap();
    }
    expect(state, const TasbihState(0, 20));

    state = const TasbihState(1, 0);
    for (var i = 0; i < 200; i++) {
      state = state.tap();
      expect(state.count, inInclusiveRange(1, state.target));
    }
  });
}
