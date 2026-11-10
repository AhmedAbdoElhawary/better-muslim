import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/foundation.dart';

/// an ayah from the ayah sheet, or a whole page from the top bar when ayah is null
@immutable
class Bookmark {
  const Bookmark({
    required this.id,
    required this.page,
    required this.category,
    required this.color,
    required this.createdAt,
    this.ayah,
    this.name,
  });

  final int id;
  final AyahKey? ayah;

  /// the ayah's page for an ayah bookmark
  final int page;

  /// null shows the reference
  final String? name;
  final int category;

  /// its category's
  final CategoryColor color;
  final DateTime createdAt;

  /// its page in the print shown, the database keeps the 1421H one
  Bookmark shownIn(QuranAssets assets) => _onPage(switch (ayah) {
    final ayah? => assets.pageOf(ayah),
    null => assets.shownPage(page),
  });

  /// back on the 1421H page it's kept on
  Bookmark storedIn(QuranAssets assets) => _onPage(switch (ayah) {
    final ayah? => assets.stored.pageOf(ayah),
    null => assets.storedPage(page),
  });

  Bookmark _onPage(int page) => Bookmark(
    id: id,
    page: page,
    category: category,
    color: color,
    createdAt: createdAt,
    ayah: ayah,
    name: name,
  );

  @override
  bool operator ==(Object other) =>
      other is Bookmark &&
      other.id == id &&
      other.ayah == ayah &&
      other.page == page &&
      other.name == name &&
      other.category == category &&
      other.color == color &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, ayah, page, name, category, color, createdAt);
}
