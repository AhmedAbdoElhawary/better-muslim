import 'dart:io';

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_clips.dart';
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
    sha256: audio == null ? null : '0' * 64,
  );
  final first = dua('d1', audio: '1.mp3');
  final second = dua('d2', audio: '2.mp3');

  late FakeClipPlayer clips;
  late ProviderContainer container;
  late Directory root;
  setUp(() {
    clips = FakeClipPlayer();
    root = Directory.systemTemp.createTempSync('recitations');
    for (final name in ['1.mp3', '2.mp3']) {
      File('${root.path}/duas/$name').createSync(recursive: true);
    }
    container = ProviderContainer(
      overrides: [
        clipPlayerProvider.overrideWithValue(clips),
        recitationFilesProvider.overrideWithValue(
          RecitationFiles(
            root: () async => root,
            fetch: (_) async => throw const SocketException('offline'),
            exclude: (_) async {},
          ),
        ),
        duaClipsProvider.overrideWithValue(
          DuaClips(
            root: () async => root,
            fetch: (_) async => throw const SocketException('offline'),
            exclude: (_) async {},
          ),
        ),
      ],
    );
    container.listen(duaPlayerProvider, (_, _) {});
    addTearDown(container.dispose);
  });
  DuaPlayer player() => container.read(duaPlayerProvider.notifier);

  test('plays a clip, the same dua again stops it', () async {
    await player().toggle(first);
    expect(container.read(duaPlayerProvider), 'd1');
    expect(clips.played, ['${root.path}/duas/1.mp3']);

    await player().toggle(first);
    expect(container.read(duaPlayerProvider), isNull);
    expect(clips.stops, 1);
  });

  test('a second dua stops the first and plays its own', () async {
    await player().toggle(first);
    await player().toggle(second);

    expect(container.read(duaPlayerProvider), 'd2');
    expect(clips.stops, 1);
    expect(clips.played, ['${root.path}/duas/1.mp3', '${root.path}/duas/2.mp3']);
  });

  test('stop with nothing playing is fine, the end of a clip clears it', () async {
    await player().stop();
    expect(clips.stops, 0);

    await player().toggle(first);
    clips.end();
    await pumpEventQueue();
    expect(container.read(duaPlayerProvider), isNull);
  });

  test('offline with its clip not on the phone it fails and plays nothing', () async {
    expect(await player().toggle(dua('d3', audio: '3.mp3')), isFalse);
    expect(container.read(duaPlayerProvider), isNull);
    expect(clips.played, isEmpty);
  });

  test('a dua without a clip never reaches the player', () async {
    await player().toggle(dua('d3'));

    expect(container.read(duaPlayerProvider), isNull);
    expect(clips.played, isEmpty);
  });

  group('a quranic dua', () {
    const verses = Dua(
      id: 'q10-85-86',
      arabic: '',
      transliteration: '',
      translation: '',
      source: (en: '', ar: ''),
      quran: true,
      ayahs: [AyahKey(10, 85), AyahKey(10, 86)],
    );

    test('recites its ayahs one after the other from the phone', () async {
      for (final name in ['010085.mp3', '010086.mp3']) {
        File('${root.path}/recitations/alafasy/$name').createSync(recursive: true);
      }
      expect(await player().toggle(verses), isTrue);
      expect(clips.played, ['${root.path}/recitations/alafasy/010085.mp3']);

      clips.end();
      await pumpEventQueue();
      expect(clips.played.last, '${root.path}/recitations/alafasy/010086.mp3');
      expect(container.read(duaPlayerProvider), 'q10-85-86');

      clips.end();
      await pumpEventQueue();
      expect(container.read(duaPlayerProvider), isNull);
    });

    test('offline with an ayah not on the phone it fails and plays nothing', () async {
      expect(await player().toggle(verses), isFalse);
      expect(container.read(duaPlayerProvider), isNull);
      expect(clips.played, isEmpty);
    });
  });
}
