import 'dart:io';

import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fajr plays the recording\'s own fajr, every other prayer its standard adhan', () {
    for (final recording in AdhanRecording.values) {
      expect(recording.fullAsset(Prayer.fajr), endsWith('/${recording.file}_fajr.m4a'));
      expect(recording.clipOf(Prayer.fajr), '${recording.file}_fajr_clip');
      expect(recording.fullAsset(Prayer.maghrib), endsWith('/${recording.file}.m4a'));
      expect(recording.clipOf(Prayer.maghrib), '${recording.file}_clip');
    }
  });

  test('every bundled recording ships its full files and clips', () {
    for (final recording in AdhanRecording.values.where((recording) => recording.isBundled)) {
      for (final prayer in [Prayer.fajr, Prayer.maghrib]) {
        expect(File(recording.fullAsset(prayer)).existsSync(), isTrue);
        final clip = recording.clipOf(prayer);
        expect(File('ios/Runner/Sounds/$clip.caf').existsSync(), isTrue);
        expect(File('android/app/src/main/res/raw/$clip.m4a').existsSync(), isTrue);
      }
    }
  });
}
