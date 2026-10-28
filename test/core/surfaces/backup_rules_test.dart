import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// surfaces.json sits in filesDir, so these rules are what keep it out of every android backup
/// (SC-006). the ios exclusion is set by the plugin on each write, checked on the simulator
void main() {
  test('the app turns backup off', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('every domain is excluded from the cloud backup and the device transfer', () {
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp('<$section>(.*?)</$section>', dotAll: true).firstMatch(rules)?[1];
      expect(body, isNotNull, reason: section);
      for (final domain in ['root', 'file', 'database', 'sharedpref', 'external']) {
        expect(body, contains('<exclude domain="$domain" />'), reason: '$section $domain');
      }
      expect(body, isNot(contains('<include')), reason: section);
    }
  });
}
