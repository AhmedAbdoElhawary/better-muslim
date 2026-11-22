import 'dart:convert';

import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:flutter/services.dart';

/// a text the content gives in both languages
typedef Bilingual = ({String en, String ar});

extension BilingualIn on Bilingual {
  String inLanguage(String languageCode) => languageCode == 'ar' ? ar : en;
}

/// "Sahih Muslim 2692 · Sahih", a hadith always shows its source and its grading when it has one
String sourceLine(Bilingual source, Bilingual? grading, String languageCode) {
  final line = source.inLanguage(languageCode);
  return grading == null ? line : '$line · ${grading.inLanguage(languageCode)}';
}

Bilingual bilingualFrom(Object? json) {
  final map = json! as Map<String, dynamic>;
  return (en: map['en'] as String, ar: map['ar'] as String);
}

class Zikr {
  const Zikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
    required this.grading,
    required this.count,
    required this.quran,
  });

  factory Zikr.fromJson(Map<String, dynamic> json) => Zikr(
    id: json['id'] as String,
    arabic: json['arabic'] as String,
    transliteration: json['transliteration'] as String,
    translation: json['translation'] as String,
    source: bilingualFrom(json['source']),
    grading: json['grading'] == null ? null : bilingualFrom(json['grading']),
    count: json['count'] as int,
    quran: json['quran'] as bool? ?? false,
  );

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final Bilingual source;
  final Bilingual? grading;

  /// times said
  final int count;
  final bool quran;
}

class AzkarSetContent {
  const AzkarSetContent({required this.minutes, required this.items});

  factory AzkarSetContent.fromJson(Map<String, dynamic> json) => AzkarSetContent(
    minutes: json['minutes'] as int,
    items: [for (final item in json['items'] as List) Zikr.fromJson(item as Map<String, dynamic>)],
  );

  /// about how long the set takes, for the nudge
  final int minutes;
  final List<Zikr> items;

  int get total => items.length;

  /// items whose count reached their number, an id no longer in the content never counts
  int doneIn(Map<String, int> counts) =>
      items.where((zikr) => (counts[zikr.id] ?? 0) >= zikr.count).length;
}

class AzkarContent {
  const AzkarContent({required this.morning, required this.evening});

  final AzkarSetContent morning;
  final AzkarSetContent evening;

  AzkarSetContent setOf(AzkarSet set) => switch (set) {
    AzkarSet.morning => morning,
    AzkarSet.evening => evening,
  };
}

/// no riverpod, the background top-up reads it too
Future<AzkarContent> loadAzkarContent() async {
  final json = jsonDecode(
    await rootBundle.loadString(
      'assets/azkar/azkar.json',

      /// the provider keeps it, and a cached load hangs the next widget test
      cache: false,
    ),
  );
  return AzkarContent(
    morning: AzkarSetContent.fromJson(json['morning'] as Map<String, dynamic>),
    evening: AzkarSetContent.fromJson(json['evening'] as Map<String, dynamic>),
  );
}
