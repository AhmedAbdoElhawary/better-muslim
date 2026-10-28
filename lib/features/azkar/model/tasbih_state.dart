import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:flutter/foundation.dart';

/// each dhikr's first bead on the string, a marker bead between them (FR-030)
const _start = [0, 34, 68];

/// the shown dhikr and the three counts of the round, a count never past its target
@immutable
class TasbihState {
  TasbihState(this.dhikr, List<int> counts) : counts = List.unmodifiable(counts);

  /// 0 to 2, an index into tasbihDhikr
  final int dhikr;

  /// in tasbihDhikr's order
  final List<int> counts;

  int get count => counts[dhikr];
  int get target => tasbihDhikr[dhikr].target;
  bool get done => doneAt(dhikr);
  bool doneAt(int index) => counts[index] >= tasbihDhikr[index].target;
  bool get complete => [for (var i = 0; i < counts.length; i++) doneAt(i)].every((done) => done);

  /// the first dhikr after the shown one, going around, that isn't done
  int? get nextOpen {
    for (var step = 1; step <= counts.length; step++) {
      final index = (dhikr + step) % counts.length;
      if (!doneAt(index)) return index;
    }
    return null;
  }

  /// a done dhikr moves on at this tap and counts it, a complete round starts again
  TasbihState tap() {
    if (complete) return TasbihState(0, const [1, 0, 0]);
    final index = done ? nextOpen! : dhikr;
    return TasbihState(index, [
      for (var i = 0; i < counts.length; i++) i == index ? counts[i] + 1 : counts[i],
    ]);
  }

  TasbihState advance() => complete ? this : TasbihState(nextOpen!, counts);

  TasbihState select(int dhikr) => TasbihState(dhikr, counts);

  TasbihState reset() => TasbihState(0, const [0, 0, 0]);

  /// the bead in focus, a count of 0 is the place before the dhikr's first bead
  int get position => _start[dhikr] + count - 1;

  @override
  bool operator ==(Object other) =>
      other is TasbihState && other.dhikr == dhikr && listEquals(other.counts, counts);

  @override
  int get hashCode => Object.hash(dhikr, Object.hashAll(counts));

  @override
  String toString() => 'TasbihState($dhikr, $counts)';
}
