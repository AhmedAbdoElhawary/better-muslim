import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped sets follow contracts/content-files.md', () async {
    final content = await loadAzkarContent();
    final ids = <String>{};
    for (final set in AzkarSet.values) {
      final items = content.setOf(set);
      expect(items.minutes, greaterThanOrEqualTo(1), reason: set.name);
      expect(items.items, isNotEmpty, reason: set.name);
      for (final zikr in items.items) {
        expect(ids.add(zikr.id), isTrue, reason: '${zikr.id} twice');
        expect(zikr.count, greaterThanOrEqualTo(1), reason: zikr.id);
        expect(zikr.arabic, isNotEmpty, reason: zikr.id);
        expect(zikr.source.en, isNotEmpty, reason: zikr.id);
        expect(zikr.source.ar, isNotEmpty, reason: zikr.id);
      }
    }
  });

  test('the samples fill the designed counts, each marked for my dataset', () async {
    final content = await loadAzkarContent();
    expect(content.morning.total, 12);
    expect(content.evening.total, 24);

    final json = jsonDecode(File('assets/azkar/azkar.json').readAsStringSync()) as Map;
    for (final set in json.values) {
      for (final item in (set as Map)['items'] as List) {
        expect((item as Map)['note'], contains('TODO(ahmed)'), reason: '${item['id']}');
      }
    }
  });

  test('the source and grading pick their language', () async {
    final zikr = (await loadAzkarContent()).morning.items.first;
    expect(zikr.source.inLanguage('en'), 'Sahih Muslim 2692');
    expect(zikr.source.inLanguage('ar'), 'صحيح مسلم ٢٦٩٢');
    expect(zikr.grading?.inLanguage('en'), 'Sahih');
  });
}
