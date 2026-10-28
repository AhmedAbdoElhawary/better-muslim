import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/foundation.dart';

/// an ayah from the ayah sheet, or a whole page from the top bar when ayah is null
@immutable
class Bookmark {
  const Bookmark({
    required this.id,
    required this.page,
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
  final RibbonColor color;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Bookmark &&
      other.id == id &&
      other.ayah == ayah &&
      other.page == page &&
      other.name == name &&
      other.color == color &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, ayah, page, name, color, createdAt);
}
