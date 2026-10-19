import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view_model/dua_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/azkar.dart';

void main() {
  Dua dua(String id, {String? audio}) => Dua(
    id: id,
    arabic: '',
    transliteration: '',
    translation: '',
    source: (en: '', ar: ''),
    audio: audio,
  );
  final first = dua('d1', audio: 'assets/duas/audio/d1.m4a');
  final second = dua('d2', audio: 'assets/duas/audio/d2.m4a');

  late FakeClipPlayer clips;
  late ProviderContainer container;
  setUp(() {
    clips = FakeClipPlayer();
    container = ProviderContainer(overrides: [clipPlayerProvider.overrideWithValue(clips)]);
    container.listen(duaPlayerProvider, (_, _) {});
    addTearDown(container.dispose);
  });
  DuaPlayer player() => container.read(duaPlayerProvider.notifier);

  test('plays a clip, the same dua again stops it', () async {
    await player().toggle(first);
    expect(container.read(duaPlayerProvider), 'd1');
    expect(clips.played, ['assets/duas/audio/d1.m4a']);

    await player().toggle(first);
    expect(container.read(duaPlayerProvider), isNull);
    expect(clips.stops, 1);
  });

  test('a second dua stops the first and plays its own', () async {
    await player().toggle(first);
    await player().toggle(second);

    expect(container.read(duaPlayerProvider), 'd2');
    expect(clips.stops, 1);
    expect(clips.played, ['assets/duas/audio/d1.m4a', 'assets/duas/audio/d2.m4a']);
  });

  test('stop with nothing playing is fine, the end of a clip clears it', () async {
    await player().stop();
    expect(clips.stops, 0);

    await player().toggle(first);
    clips.end();
    await pumpEventQueue();
    expect(container.read(duaPlayerProvider), isNull);
  });

  test('a dua without a clip never reaches the player', () async {
    await player().toggle(dua('d3'));

    expect(container.read(duaPlayerProvider), isNull);
    expect(clips.played, isEmpty);
  });
}
