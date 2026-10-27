import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// sheet is the ayah the sheet is open on. chosen are the ayahs picked for sharing, choosing
/// while there are any (FR-015)
typedef SelectionState = ({AyahKey? sheet, Set<AyahKey> chosen, bool choosing});

final selectionProvider = NotifierProvider.autoDispose<Selection, SelectionState>(Selection.new);

class Selection extends Notifier<SelectionState> {
  static const SelectionState _none = (sheet: null, chosen: {}, choosing: false);

  @override
  SelectionState build() => _none;

  void select(AyahKey key) => state = (sheet: key, chosen: const {}, choosing: false);

  void startChoosing(AyahKey key) => state = (sheet: null, chosen: {key}, choosing: true);

  /// unchecking the last one ends choosing
  void toggle(AyahKey key) {
    final chosen = {...state.chosen};
    if (!chosen.remove(key)) chosen.add(key);
    state = chosen.isEmpty ? _none : (sheet: null, chosen: chosen, choosing: true);
  }

  void clear() => state = _none;
}
