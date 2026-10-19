import 'dart:async';

import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/features/azkar/model/set_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final setControllerProvider = NotifierProvider.autoDispose
    .family<SetController, SetState?, AzkarSet>(SetController.new);

/// one open set page. it keeps the window it opened in, so asr coming while the morning set is
/// open doesn't move its counts. a tap changes the state at once and writes after (R6)
class SetController extends Notifier<SetState?> {
  SetController(this.set);
  final AzkarSet set;

  late DateTime _day;
  List<Zikr> _items = const [];

  List<Zikr> get items => _items;

  @override
  SetState? build() {
    _day = ref.read(azkarWindowDayProvider(set));
    _load();
    return null;
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final content = await ref.read(azkarContentProvider.future);
    final counts = await db.zikrCounts(set, _day);
    if (!ref.mounted) return;
    _items = content.setOf(set).items;
    state = SetState.openAt(_items, counts);
    unawaited(
      db.updateSettings(switch (set) {
        AzkarSet.morning => SettingsCompanion(morningOpenedOn: Value(_day)),
        AzkarSet.evening => SettingsCompanion(eveningOpenedOn: Value(_day)),
      }),
    );
  }

  SetTap tap() {
    final before = state;
    if (before == null) return SetTap.none;
    final (next, what) = before.tap(_items);
    state = next;
    if (what case SetTap.counted || SetTap.done || SetTap.setDone) {
      final zikr = _items[next.index];
      unawaited(ref.read(databaseProvider).setZikrCount(set, _day, zikr.id, next.countOf(zikr)));
    }
    return what;
  }

  /// a swipe, it never counts
  void moveTo(int index) {
    final before = state;
    if (before != null && before.index != index) state = before.moveTo(index);
  }
}
