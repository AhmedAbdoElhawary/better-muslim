import 'dart:async';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/azkar/model/tasbih_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasbihControllerProvider = NotifierProvider<TasbihController, TasbihState?>(
  TasbihController.new,
);

/// null until the store answers. a tap changes the state in the same frame and writes it after,
/// a round trip through the store's stream would lag behind fast taps (R6)
class TasbihController extends Notifier<TasbihState?> {
  @override
  TasbihState? build() {
    ref.read(settingsProvider.future).then((row) {
      state ??= TasbihState(row.tasbihDhikr, [
        row.subhanallahCount,
        row.alhamdulillahCount,
        row.allahuAkbarCount,
      ]);
    });
    return null;
  }

  void tap() => _set(state?.tap());

  void advance() => _set(state?.advance());

  void select(int dhikr) => _set(state?.select(dhikr));

  /// the state before, for undo
  TasbihState? reset() {
    final before = state;
    _set(before?.reset());
    return before;
  }

  void restore(TasbihState before) => _set(before);

  void _set(TasbihState? next) {
    if (next == null) return;
    state = next;
    unawaited(
      ref
          .read(databaseProvider)
          .updateSettings(
            SettingsCompanion(
              tasbihDhikr: Value(next.dhikr),
              subhanallahCount: Value(next.counts[0]),
              alhamdulillahCount: Value(next.counts[1]),
              allahuAkbarCount: Value(next.counts[2]),
            ),
          ),
    );
  }
}
