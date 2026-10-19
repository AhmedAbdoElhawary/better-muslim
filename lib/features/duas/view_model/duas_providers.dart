import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_search.dart';
import 'package:better_muslim/features/duas/model/duas_view.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final duasContentProvider = FutureProvider<List<DuaCategory>>((ref) => loadDuas());

/// back to all each time duas opens
final duaChipProvider = NotifierProvider.autoDispose<SelectedChip, DuaChip>(SelectedChip.new);

class SelectedChip extends Notifier<DuaChip> {
  @override
  DuaChip build() => DuaChip.all;

  void select(DuaChip chip) => state = chip;
}

final duaQueryProvider = NotifierProvider.autoDispose<DuaQuery, String>(DuaQuery.new);

class DuaQuery extends Notifier<String> {
  @override
  String build() => '';

  void change(String query) => state = query;
}

final duasViewProvider = Provider.autoDispose<DuasView>(
  (ref) =>
      duasViewFor(ref.watch(duaChipProvider), ref.watch(duasContentProvider).value ?? const []),
);

final duaResultsProvider = Provider.autoDispose<List<(Dua, DuaCategory)>>(
  (ref) =>
      searchDuas(ref.watch(duaQueryProvider), ref.watch(duasContentProvider).value ?? const []),
);

/// dua id to when it was saved, newest first
final savedAtProvider = StreamProvider<Map<String, DateTime>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.savedDuas)..orderBy([(row) => OrderingTerm.desc(row.savedAt)]);
  return query.watch().map((rows) => {for (final row in rows) row.dua: row.savedAt});
});

/// an id no longer in the content is skipped
final savedDuasProvider = Provider<List<(Dua, DuaCategory)>>((ref) {
  final saved = ref.watch(savedAtProvider).value ?? const {};
  final categories = ref.watch(duasContentProvider).value ?? const [];
  final byId = <String, (Dua, DuaCategory)>{};
  for (final category in categories) {
    for (final dua in category.duas) {
      byId.putIfAbsent(dua.id, () => (dua, category));
    }
  }
  return [for (final id in saved.keys) ?byId[id]];
});

final isSavedProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(savedAtProvider.select((saved) => saved.value?.containsKey(id) ?? false)),
);
