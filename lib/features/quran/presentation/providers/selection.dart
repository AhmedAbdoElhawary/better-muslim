import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the ayah the sheet is open on, null when none
final selectionProvider = NotifierProvider.autoDispose<Selection, AyahKey?>(Selection.new);

class Selection extends Notifier<AyahKey?> {
  @override
  AyahKey? build() => null;

  void select(AyahKey key) => state = key;

  void clear() => state = null;
}
