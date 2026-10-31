import 'dart:convert';

import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:flutter/services.dart';

/// all and saved aren't in the file, the others are a category's chip
enum DuaChip {
  all(StringsManager.catAll),
  morningEvening(StringsManager.catMorningEvening),
  home(StringsManager.catHome),
  travel(StringsManager.catTravel),
  sleep(StringsManager.catSleep),
  saved(StringsManager.chipSaved);

  const DuaChip(this.labelKey);
  final String labelKey;
}

class Dua {
  const Dua({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
    this.grading,
    this.audio,
    this.quran = false,
  });

  factory Dua.fromJson(Map<String, dynamic> json) => Dua(
    id: json['id'] as String,
    arabic: json['arabic'] as String,
    transliteration: json['transliteration'] as String,
    translation: json['translation'] as String,
    source: bilingualFrom(json['source']),
    grading: json['grading'] == null ? null : bilingualFrom(json['grading']),
    audio: json['audio'] as String?,
    quran: json['quran'] as bool? ?? false,
  );

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final Bilingual source;
  final Bilingual? grading;

  /// an asset path, null = listen does nothing
  final String? audio;

  /// a verse keeps the quran font
  final bool quran;

  /// the 4.14 sample has no grading, so its source only
  String sourceIn(String languageCode) => sourceLine(source, grading, languageCode);
}

class DuaCategory {
  const DuaCategory({required this.id, required this.name, required this.chip, required this.duas});

  factory DuaCategory.fromJson(Map<String, dynamic> json) => DuaCategory(
    id: json['id'] as String,
    name: bilingualFrom(json['name']),
    chip: DuaChip.values.byName(json['chip'] as String),
    duas: [for (final dua in json['duas'] as List) Dua.fromJson(dua as Map<String, dynamic>)],
  );

  final String id;
  final Bilingual name;
  final DuaChip chip;
  final List<Dua> duas;
}

// TODO(ahmed): once hisnmuslim.com allows their audio, the clips go in assets/duas/audio/ and their paths in duas.json, listen shows by itself then.
Future<List<DuaCategory>> loadDuas() async {
  final json = jsonDecode(
    await rootBundle.loadString(
      'assets/duas/duas.json',

      /// the provider keeps it, and a cached load hangs the next widget test
      cache: false,
    ),
  );
  return [
    for (final category in json['categories'] as List)
      DuaCategory.fromJson(category as Map<String, dynamic>),
  ];
}
