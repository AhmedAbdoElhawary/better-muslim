import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';

/// one dhikr and its count, never past its target
class TasbihState {
  const TasbihState(this.dhikr, this.count);

  /// 0 to 2, an index into tasbihDhikr
  final int dhikr;
  final int count;

  int get target => tasbihDhikr[dhikr].target;
  bool get done => count >= target;

  /// the tap after a finished dhikr starts the next one at 1, after allahu akbar subhanallah
  TasbihState tap() =>
      done ? TasbihState((dhikr + 1) % tasbihDhikr.length, 1) : TasbihState(dhikr, count + 1);

  TasbihState select(int dhikr) => TasbihState(dhikr, 0);

  TasbihState reset() => const TasbihState(0, 0);

  @override
  bool operator ==(Object other) =>
      other is TasbihState && other.dhikr == dhikr && other.count == count;

  @override
  int get hashCode => Object.hash(dhikr, count);

  @override
  String toString() => 'TasbihState($dhikr, $count)';
}
