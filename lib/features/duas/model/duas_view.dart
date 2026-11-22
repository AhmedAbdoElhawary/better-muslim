import 'package:better_muslim/features/duas/model/dua.dart';

typedef DuasView = ({Dua? card, DuaCategory? cardCategory, List<DuaCategory> rows});

/// FR-019: the chip's first dua on the card, its categories as rows. the card's own category
/// keeps its row when it has more than that dua, so none is out of reach
DuasView duasViewFor(DuaChip chip, List<DuaCategory> categories) {
  final shown = chip == DuaChip.all
      ? categories
      : categories.where((category) => category.chip == chip).toList();
  if (shown.isEmpty) return (card: null, cardCategory: null, rows: const []);
  final first = shown.first;
  return (
    card: first.duas.first,
    cardCategory: first,
    rows: [if (first.duas.length > 1) first, ...shown.skip(1)],
  );
}
