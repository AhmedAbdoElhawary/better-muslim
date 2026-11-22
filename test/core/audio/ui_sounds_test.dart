import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sounds.dart';

void main() {
  late FakeSoundOutput output;

  setUp(() {
    output = FakeSoundOutput();
    BmSounds.output = output;
    BmSounds.enabled = true;
    BmSounds.busy = false;
  });

  tearDown(() {
    BmSounds.enabled = false;
    BmSounds.busy = false;
  });

  test('each sound plays its own file once', () async {
    await BmSounds.toggle();
    await BmSounds.bead();
    await BmSounds.complete();
    await BmSounds.aligned();
    await BmSounds.prayed();
    expect(output.played, [
      'assets/audio/ui_toggle.m4a',
      'assets/audio/ui_bead.m4a',
      'assets/audio/ui_complete.m4a',
      'assets/audio/ui_aligned.m4a',
      'assets/audio/ui_prayed.m4a',
    ]);
  });

  test('nothing plays with ui sounds off', () async {
    BmSounds.enabled = false;
    await BmSounds.bead();
    expect(output.played, isEmpty);
  });

  test('nothing plays over the adhan or a clip', () async {
    BmSounds.busy = true;
    await BmSounds.complete();
    expect(output.played, isEmpty);
  });

  test('nothing plays with the phone on silent or vibrate', () async {
    output.allowed = false;
    await BmSounds.aligned();
    expect(output.played, isEmpty);
  });
}
