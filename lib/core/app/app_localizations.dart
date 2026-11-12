import 'dart:convert';
import 'dart:ui';

import 'package:better_muslim/core/settings/settings.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:intl/message_format.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

/// reads the arb files in assets/l10n/ at runtime, so a text takes a const StringsManager key
class AppLocalizations {
  const AppLocalizations(this._strings, [this._languageCode = 'en']);
  final Map<String, String> _strings;
  final String _languageCode;

  static final _plural = RegExp(r'\{(\w+), plural,');

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// what MaterialApp picks from the phone's languages, for code that runs above it
  static Locale localeFor(List<Locale> preferred) {
    for (final locale in preferred) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == locale.languageCode) return supported;
      }
    }
    return supportedLocales.first;
  }

  /// the language picked in More, or the phone's
  static Locale localeOf(Language? language) => switch (language) {
    Language.english => const Locale('en'),
    Language.arabic => const Locale('ar'),
    Language.phone || null => localeFor(PlatformDispatcher.instance.locales),
  };

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static final _preloaded = <String, AppLocalizations>{};

  /// both, while the store opens. a strings file in hand lets Localizations build the first frame
  /// at once instead of holding it for an asset read
  static Future<void> preload() async {
    for (final strings in await Future.wait(supportedLocales.map(load))) {
      _preloaded[strings._languageCode] = strings;
    }
  }

  /// also without a context, notifications are built in the background
  static Future<AppLocalizations> load(Locale locale) async {
    final arb = await rootBundle.loadString(
      'assets/l10n/app_${locale.languageCode}.arb',

      /// Localizations keeps the result already, and a cached load hangs the next widget test
      cache: false,
    );
    final json = jsonDecode(arb) as Map<String, dynamic>;

    /// @ keys are the arb's notes about placeholders, not strings
    return AppLocalizations({
      for (final MapEntry(:key, :value) in json.entries)
        if (!key.startsWith('@')) key: value as String,
    }, locale.languageCode);
  }

  String tr(String key, Map<String, String> args) {
    assert(
      _strings.containsKey(key),
      'no string for "$key", a text that is not a key needs translate: false',
    );
    var text = _strings[key] ?? key;
    for (final arg in args.entries) {
      text = text.replaceAll('{${arg.key}}', arg.value);
    }

    /// arabic has its own form for 1, 2, 3 to 10 and 11 or more, the count comes already formatted
    final plurals = _plural.allMatches(text).map((match) => match[1]!).toSet();
    if (plurals.isEmpty) return text;
    return MessageFormat(text, locale: _languageCode).format({
      for (final name in plurals)
        name: int.parse(
          args[name]!.replaceAllMapped(
            RegExp('[٠-٩]'),
            (match) => '${match[0]!.codeUnitAt(0) - 0x0660}',
          ),
        ),
    });
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      switch (AppLocalizations._preloaded.remove(locale.languageCode)) {
        final strings? => SynchronousFuture(strings),
        null => AppLocalizations.load(locale),
      };

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
