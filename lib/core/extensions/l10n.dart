import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nExtension on BuildContext {
  String tr(String key, [Map<String, String> args = const {}]) =>
      AppLocalizations.of(this).tr(key, args);
}
