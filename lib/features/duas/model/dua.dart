import 'dart:convert';

import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/services.dart';

/// saved isn't in the file, a category on all shows only under all
enum DuaChip {
  all(StringsManager.catAll),
  morningEvening(StringsManager.catMorningEvening),
  home(StringsManager.catHome),
  prayer(StringsManager.catPrayer),
  travel(StringsManager.catTravel),
  sleep(StringsManager.catSleep),
  food(StringsManager.catFood),
  distress(StringsManager.catDistress),
  illness(StringsManager.catIllness),
  weather(StringsManager.catWeather),
  quranic(StringsManager.catQuranic),
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
    this.sha256,
    this.quran = false,
    this.ayahs = const [],
  });

  factory Dua.fromJson(Map<String, dynamic> json) => Dua(
    id: json['id'] as String,
    arabic: json['arabic'] as String,
    transliteration: json['transliteration'] as String,
    translation: json['translation'] as String,
    source: bilingualFrom(json['source']),
    grading: json['grading'] == null ? null : bilingualFrom(json['grading']),
    audio: json['audio'] as String?,
    sha256: json['sha256'] as String?,
    quran: json['quran'] as bool? ?? false,
  );

  /// "2:127" or "10:85-86", the whole ayahs so the quran is never cut, with sahih international
  static Future<Dua> verses(String id, String reference, QuranAssets quran) async {
    final [surah, first, ...rest] = reference.split(RegExp('[:-]')).map(int.parse).toList();
    final keys = [
      for (var ayah = first; ayah <= (rest.firstOrNull ?? first); ayah++) AyahKey(surah, ayah),
    ];
    final text = await quran.surahText(surah);
    final name = quran.surah(surah);
    return Dua(
      id: id,
      arabic: [for (final key in keys) await quran.ayahText(key)].join(' '),
      transliteration: '',
      translation: [for (final key in keys) text.translation[key.ayah - 1]].join(' '),
      source: (
        en: '${name.en} $reference',
        ar: formatDigitsIn('${name.ar} $reference', language: 'ar', digits: Digits.eastern),
      ),
      quran: true,
      ayahs: keys,
    );
  }

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final Bilingual source;
  final Bilingual? grading;

  /// hisnmuslim.com's file name, null = listen does nothing
  final String? audio;
  final String? sha256;

  /// a verse keeps the quran font
  final bool quran;

  /// a quranic dua's ayahs, listen recites them
  final List<AyahKey> ayahs;

  bool get listenable => audio != null || ayahs.isNotEmpty;

  /// the 4.14 sample has no grading, so its source only
  String sourceIn(String languageCode) => sourceLine(source, grading, languageCode);
}

class DuaCategory {
  const DuaCategory({required this.id, required this.name, required this.chip, required this.duas});

  static Future<DuaCategory> fromJson(Map<String, dynamic> json, QuranAssets quran) async =>
      DuaCategory(
        id: json['id'] as String,
        name: bilingualFrom(json['name']),
        chip: DuaChip.values.byName(json['chip'] as String),
        duas: [
          for (final dua in (json['duas'] as List).cast<Map<String, dynamic>>())
            if (dua['ayahs'] case final String reference)
              await Dua.verses(dua['id'] as String, reference, quran)
            else
              Dua.fromJson(dua),
        ],
      );

  final String id;
  final Bilingual name;
  final DuaChip chip;
  final List<Dua> duas;
}

Future<List<DuaCategory>> loadDuas(QuranAssets quran) async {
  /// loadString sends files over 50 kb to an isolate, and an isolate never ends in a widget test
  final json = jsonDecode(
    utf8.decode((await rootBundle.load('assets/duas/duas.json')).buffer.asUint8List()),
  );
  return [
    for (final category in json['categories'] as List)
      await DuaCategory.fromJson(category as Map<String, dynamic>, quran),
  ];
}
