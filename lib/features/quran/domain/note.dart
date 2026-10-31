import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:flutter/foundation.dart';

/// one private note per ayah, its text may be empty when it highlights the ayah
@immutable
class Note {
  const Note({
    required this.ayah,
    required this.text,
    required this.updatedAt,
    this.highlight = false,
  });

  final AyahKey ayah;
  final String text;
  final bool highlight;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.ayah == ayah &&
      other.text == text &&
      other.highlight == highlight &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(ayah, text, highlight, updatedAt);
}
