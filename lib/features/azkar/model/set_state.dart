import 'package:better_muslim/core/azkar/azkar_content.dart';

/// what a tap on a card did, the page picks the haptic and the move from it
enum SetTap { counted, done, moved, setDone, none }

/// the open card and the count of each zikr by id, never past the zikr's count
class SetState {
  const SetState(this.index, this.counts);

  /// the first card not done, or the last when all are
  factory SetState.openAt(List<Zikr> items, Map<String, int> counts) {
    final first = items.indexWhere((zikr) => (counts[zikr.id] ?? 0) < zikr.count);
    return SetState(first == -1 ? items.length - 1 : first, counts);
  }

  final int index;
  final Map<String, int> counts;

  int countOf(Zikr zikr) => counts[zikr.id] ?? 0;

  bool allDone(List<Zikr> items) => items.every((zikr) => countOf(zikr) >= zikr.count);

  /// the tap after a done card moves on, the same as tasbih
  (SetState, SetTap) tap(List<Zikr> items) {
    final zikr = items[index];
    final count = countOf(zikr);
    if (count < zikr.count) {
      final next = SetState(index, {...counts, zikr.id: count + 1});
      if (count + 1 < zikr.count) return (next, SetTap.counted);
      return (next, next.allDone(items) ? SetTap.setDone : SetTap.done);
    }
    if (index < items.length - 1) return (moveTo(index + 1), SetTap.moved);
    return (this, SetTap.none);
  }

  SetState moveTo(int index) => SetState(index, counts);
}
