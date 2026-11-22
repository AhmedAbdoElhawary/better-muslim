import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:better_muslim/features/azkar/model/tasbih_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fresh = TasbihState(0, const [0, 0, 0]);

  test('the targets are 33, 33 and 34', () {
    expect(tasbihDhikr.map((dhikr) => dhikr.target), [33, 33, 34]);
  });

  test('100 taps from reset are one full round (SC-005)', () {
    var state = fresh.reset();
    for (var i = 0; i < 100; i++) {
      state = state.tap();
    }
    expect(state, TasbihState(2, const [33, 33, 34]));
    expect(state.complete, isTrue);
    expect(state.nextOpen, isNull);
  });

  test('a tap on a done dhikr moves to the next open one and counts it', () {
    expect(TasbihState(0, const [33, 0, 0]).tap(), TasbihState(1, const [33, 1, 0]));
    expect(TasbihState(2, const [10, 33, 34]).tap(), TasbihState(0, const [11, 33, 34]));
    expect(TasbihState(0, const [16, 0, 0]).tap(), TasbihState(0, const [17, 0, 0]));
  });

  test('a tap on a complete round starts again at subhanallah 1', () {
    expect(TasbihState(1, const [33, 33, 34]).tap(), TasbihState(0, const [1, 0, 0]));
  });

  test('select keeps the counts', () {
    expect(TasbihState(0, const [20, 5, 0]).select(2), TasbihState(2, const [20, 5, 0]));
  });

  test('advance goes around to the next not done, a complete round stays', () {
    expect(TasbihState(0, const [33, 0, 0]).advance(), TasbihState(1, const [33, 0, 0]));
    expect(TasbihState(2, const [5, 33, 34]).advance(), TasbihState(0, const [5, 33, 34]));
    expect(TasbihState(0, const [33, 33, 0]).advance(), TasbihState(2, const [33, 33, 0]));
    final complete = TasbihState(1, const [33, 33, 34]);
    expect(complete.advance(), complete);
  });

  test('reset is subhanallah with three zeros', () {
    expect(TasbihState(2, const [20, 33, 7]).reset(), fresh);
  });

  test('a count never passes its target', () {
    var state = TasbihState(1, const [0, 0, 0]);
    for (var i = 0; i < 300; i++) {
      state = state.tap();
      for (var d = 0; d < 3; d++) {
        expect(state.counts[d], inInclusiveRange(0, tasbihDhikr[d].target));
      }
    }
  });

  test('the bead in focus on the string', () {
    expect(fresh.position, -1);
    expect(TasbihState(0, const [1, 0, 0]).position, 0);
    expect(TasbihState(1, const [33, 0, 0]).position, 33);
    expect(TasbihState(1, const [33, 1, 0]).position, 34);
    expect(TasbihState(2, const [33, 33, 34]).position, 101);
  });

  test('the counts are fixed', () {
    expect(() => fresh.counts[0] = 1, throwsUnsupportedError);
  });
}
