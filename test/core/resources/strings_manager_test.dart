import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  /// read from the source, dart has no reflection to list the consts
  final keys = {
    for (final match in RegExp(
      r"static const String (\w+) = '(\w+)';",
    ).allMatches(File('lib/core/resources/strings_manager.dart').readAsStringSync()))
      match[1]!: match[2]!,
  };
  final arbs = {
    for (final file in Directory('assets/l10n').listSync().whereType<File>())
      file.path: (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        ..removeWhere((key, _) => key.startsWith('@')),
  };

  test('every StringsManager value is its own name', () {
    final wrong = [
      for (final MapEntry(:key, :value) in keys.entries)
        if (key != value) '$key = $value',
    ];
    expect(wrong, isEmpty);
  });

  test('every arb has exactly the StringsManager keys', () {
    for (final MapEntry(key: path, value: arb) in arbs.entries) {
      expect(arb.keys.toSet(), keys.values.toSet(), reason: path);
    }
  });

  test('every arb has the same placeholders as english', () {
    final english = arbs['assets/l10n/app_en.arb']!;
    Set<String> placeholders(Object? text) =>
        RegExp(r'\{(\w+)\}').allMatches('$text').map((match) => match[1]!).toSet();
    for (final MapEntry(key: path, value: arb) in arbs.entries) {
      for (final key in english.keys) {
        expect(placeholders(arb[key]), placeholders(english[key]), reason: '$path $key');
      }
    }
  });
}
