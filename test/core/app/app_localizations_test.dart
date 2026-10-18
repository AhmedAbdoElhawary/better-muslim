import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, String> arb(String language) => {
    for (final MapEntry(:key, :value) in (jsonDecode(
      File('assets/l10n/app_$language.arb').readAsStringSync(),
    ) as Map<String, dynamic>).entries)
      if (!key.startsWith('@')) key: value as String,
  };
  final arabic = AppLocalizations(arb('ar'), 'ar');
  final english = AppLocalizations(arb('en'));
  String eastern(int count) => '$count'.replaceAllMapped(
    RegExp('[0-9]'),
    (match) => String.fromCharCode(0x0660 + int.parse(match[0]!)),
  );

  test('tr fills the placeholders by name, whatever their order', () {
    const strings = AppLocalizations({'untilPrayerAt': 'حتى {prayer} الساعة {time}'});

    expect(
      strings.tr('untilPrayerAt', {'time': '١٧:٥٦', 'prayer': 'المغرب'}),
      'حتى المغرب الساعة ١٧:٥٦',
    );
  });

  test('arabic counts pick the cldr form, from western or eastern digits (FR-029)', () {
    String total(String count) => arabic.tr('qadaTotal', {'count': count});

    expect(total('1'), 'صلاة واحدة للقضاء');
    expect(total('٢'), 'صلاتان للقضاء');
    for (final count in [3, 10, 103]) {
      expect(total(eastern(count)), '${eastern(count)} صلوات للقضاء');
    }

    /// cldr zero and many have no branch of their own, so they take other
    for (final count in [0, 11, 99]) {
      expect(total('$count'), '$count صلاة للقضاء');
    }
    expect(arabic.tr('missedToMakeUp', {'count': '٢'}), 'صلاتان فائتتان هذا الشهر للقضاء');
  });

  test('every plural string formats 0 to 12 in both languages', () {
    for (final strings in [arabic, english]) {
      for (final key in ['qadaTotal', 'missedToMakeUp']) {
        for (var count = 0; count <= 12; count++) {
          expect(strings.tr(key, {'count': '$count'}), isNot(contains('{')));
          expect(strings.tr(key, {'count': eastern(count)}), isNot(contains('{')));
        }
      }
    }
  });

  test('english strings without plural syntax come back as they are', () {
    expect(english.tr('qadaTotal', {'count': '1'}), '1 to make up');
    expect(english.tr('missedToMakeUp', {'count': '3'}), '3 missed this month to make up');
  });

  /// a ' starts a quoted part in icu syntax
  test('no plural string has a quote', () {
    for (final language in ['en', 'ar']) {
      final quoted = arb(language).entries
          .where((entry) => entry.value.contains(', plural,') && entry.value.contains("'"));
      expect(quoted, isEmpty, reason: language);
    }
  });

  test('above the app the language follows the phone\'s order, like MaterialApp', () {
    expect(
      AppLocalizations.localeFor(const [Locale('ar', 'SA'), Locale('en')]),
      const Locale('ar'),
    );
    expect(AppLocalizations.localeFor(const [Locale('fr'), Locale('ar')]), const Locale('ar'));
    expect(AppLocalizations.localeFor(const [Locale('fr')]), const Locale('en'));
  });
}
