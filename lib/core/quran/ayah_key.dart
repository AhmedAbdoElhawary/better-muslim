import 'package:flutter/foundation.dart';

/// one ayah, "2:255", ordered the way the mushaf reads
@immutable
class AyahKey implements Comparable<AyahKey> {
  const AyahKey(this.surah, this.ayah);

  /// "2:255" from a route's query, null when it isn't one
  static AyahKey? tryParse(String? text) {
    final parts = text?.split(':');
    if (parts == null || parts.length != 2) return null;
    final (surah, ayah) = (int.tryParse(parts[0]), int.tryParse(parts[1]));
    return surah == null || ayah == null ? null : AyahKey(surah, ayah);
  }

  final int surah;
  final int ayah;

  /// "Al-Fatiha 1:5"
  String reference(String surahName) => '$surahName $surah:$ayah';

  @override
  int compareTo(AyahKey other) => surah != other.surah ? surah - other.surah : ayah - other.ayah;

  @override
  bool operator ==(Object other) => other is AyahKey && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}
