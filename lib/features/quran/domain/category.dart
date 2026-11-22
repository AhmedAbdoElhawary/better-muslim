import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/foundation.dart';

/// a named, colored group of bookmarks in the order I made them
@immutable
class Category {
  const Category({required this.id, required this.color, this.name});

  final int id;

  /// null on the default shows "Bookmarks"
  final String? name;
  final CategoryColor color;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name && other.color == color;

  @override
  int get hashCode => Object.hash(id, name, color);
}
