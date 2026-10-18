import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/message_format.dart';

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

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
    final plural = _plural.firstMatch(text);
    if (plural == null) return text;
    final count = args[plural[1]]!.replaceAllMapped(
      RegExp('[٠-٩]'),
      (match) => '${match[0]!.codeUnitAt(0) - 0x0660}',
    );
    return MessageFormat(text, locale: _languageCode).format({plural[1]!: int.parse(count)});
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
