import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:flutter_test/flutter_test.dart';

/// an mp3 as everyayah sends it: an ID3 tag, then the frames
final _mp3 = [0x49, 0x44, 0x33, ...List.filled(61, 7)];

void main() {
  late Directory root;
  late List<Uri> asked;
  late List<String> excluded;

  setUp(() {
    root = Directory.systemTemp.createTempSync('recitations');
    asked = [];
    excluded = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  RecitationFiles files(Future<Fetched> Function(Uri uri) fetch) => RecitationFiles(
    root: () async => root,
    fetch: (uri, {from = 0}) {
      asked.add(uri);
      return fetch(uri);
    },
    exclude: (path) async => excluded.add(path),
  );

  Future<Fetched> serve(List<int> body, {int? length}) async =>
      (length: length ?? body.length, bytes: Stream.value(body));

  File stored(String name) => File('${root.path}/recitations/alafasy/$name');

  List<String> left() =>
      Directory('${root.path}/recitations/alafasy')
          .listSync()
          .map((file) => file.uri.pathSegments.last)
          .toList();

  Future<RecitationFailure> failure(Future<Object?> future) async {
    try {
      await future;
    } on RecitationException catch (error) {
      return error.failure;
    }
    fail('no error');
  }

  test('the address is everyayah over https with the padded name and nothing else', () {
    final address = RecitationFiles.address(Reciter.alafasy, const AyahKey(1, 5));
    expect(address.toString(), 'https://everyayah.com/data/Alafasy_128kbps/001005.mp3');
    expect(address.hasQuery, isFalse);
  });

  test("a reciter's files live in its own folder, alafasy's where they always were", () async {
    final recitations = files((_) => serve(_mp3));
    final file = await recitations.file(Reciter.alafasy, const AyahKey(2, 255));
    expect(file.path, '${root.path}/recitations/alafasy/002255.mp3');
    expect(asked.single.toString(), 'https://everyayah.com/data/Alafasy_128kbps/002255.mp3');
  });

  test('a complete file with ID3 or a frame sync is kept and not fetched again', () async {
    final recitations = files((_) => serve(_mp3));
    final file = await recitations.file(Reciter.alafasy, const AyahKey(1, 5));
    expect(file.path, stored('001005.mp3').path);
    expect(file.readAsBytesSync(), _mp3);
    await recitations.file(Reciter.alafasy, const AyahKey(1, 5));
    expect(asked, hasLength(1));

    final synced = files((_) => serve([0xFF, 0xFB, 0x90, 0x00]));
    expect((await synced.file(Reciter.alafasy, const AyahKey(1, 6))).existsSync(), isTrue);
  });

  test('a short body leaves no file and reports the failure', () async {
    final recitations = files((_) => serve(_mp3, length: _mp3.length + 10));
    expect(
      await failure(recitations.file(Reciter.alafasy, const AyahKey(1, 5))),
      RecitationFailure.failed,
    );
    expect(left(), isEmpty);
  });

  test('no size header with an mp3 start is kept', () async {
    final recitations = files((_) async => (length: null, bytes: Stream.value(_mp3)));
    expect((await recitations.file(Reciter.alafasy, const AyahKey(1, 5))).readAsBytesSync(), _mp3);
  });

  test('wrong first bytes leave no file', () async {
    final recitations = files((_) => serve('<html>not found</html>'.codeUnits));
    expect(
      await failure(recitations.file(Reciter.alafasy, const AyahKey(1, 5))),
      RecitationFailure.failed,
    );
    expect(left(), isEmpty);
  });

  test('a full disk leaves no file', () async {
    final recitations = files(
      (_) async => (
        length: 100,
        bytes: Stream<List<int>>.fromFutures([
          Future.value(_mp3),
          Future.error(const FileSystemException('No space left on device')),
        ]),
      ),
    );
    expect(
      await failure(recitations.file(Reciter.alafasy, const AyahKey(1, 5))),
      RecitationFailure.failed,
    );
    expect(left(), isEmpty);
  });

  test('offline with no file reports offline', () async {
    final recitations = files((_) => throw const SocketException('offline'));
    expect(
      await failure(recitations.file(Reciter.alafasy, const AyahKey(1, 5))),
      RecitationFailure.offline,
    );
    expect(stored('001005.mp3').existsSync(), isFalse);
  });

  test('the rest of the surah downloads one at a time, in order', () async {
    var open = 0;
    var most = 0;
    final recitations = files((_) async {
      most = open + 1 > most ? open + 1 : most;
      open++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      open--;
      return serve(_mp3);
    });
    final keys = [for (var ayah = 2; ayah <= 7; ayah++) AyahKey(1, ayah)];
    await recitations.file(Reciter.alafasy, const AyahKey(1, 1));
    recitations.ahead(Reciter.alafasy, keys);
    while (!await recitations.isSurahReady(Reciter.alafasy, [const AyahKey(1, 1), ...keys])) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(most, 1);
    expect(asked.map((uri) => uri.pathSegments.last), [
      for (var ayah = 1; ayah <= 7; ayah++) '00100$ayah.mp3',
    ]);
  });

  test('the folder is excluded from backup when it is made', () async {
    final recitations = files((_) => serve(_mp3));
    await recitations.file(Reciter.alafasy, const AyahKey(1, 1));
    await recitations.file(Reciter.alafasy, const AyahKey(1, 2));
    expect(excluded, ['${root.path}/recitations/alafasy']);
  });

  test('the request carries no headers beyond the defaults', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final headers = Completer<HttpHeaders>();
    server.listen((request) {
      headers.complete(request.headers);
      request.response
        ..contentLength = _mp3.length
        ..add(_mp3)
        ..close();
    });
    final fetched = await fetchUri(Uri.parse('http://127.0.0.1:${server.port}/001005.mp3'));
    expect(await fetched.bytes.expand((chunk) => chunk).toList(), _mp3);
    final sent = <String>[];
    (await headers.future).forEach((name, _) => sent.add(name));
    expect(sent..sort(), ['accept-encoding', 'host']);
    await server.close();
  });

  group('a downloaded surah', () {
    /// al-ikhlas has 4 ayahs, its bismillah is al-fatiha's first
    final ikhlas = surahFiles(112, 4);

    test(
      'fetches every ayah and the bismillah, with progress, and lists it with its size',
      () async {
        final recitations = files((_) => serve(_mp3));
        final progress = <double>[];
        await recitations.downloadSurah(Reciter.husary, ikhlas, onProgress: progress.add);

        expect(asked.map((uri) => uri.toString()), [
          'https://everyayah.com/data/Husary_128kbps/001001.mp3',
          for (var ayah = 1; ayah <= 4; ayah++)
            'https://everyayah.com/data/Husary_128kbps/11200$ayah.mp3',
        ]);
        expect(progress.last, 1);
        expect(await recitations.isSurahReady(Reciter.husary, ikhlas), isTrue);
        expect(await recitations.downloaded(Reciter.husary, (surah) => surah == 112 ? 4 : 7), [
          (surah: 112, bytes: 4 * _mp3.length),
        ]);
        expect(await recitations.downloaded(Reciter.alafasy, (_) => 4), isEmpty);
        expect(excluded, ['${root.path}/recitations/husary']);
      },
    );

    test('a half surah is not listed, and offline keeps what is done and goes on later', () async {
      var online = true;
      final recitations = files((uri) {
        if (!online) throw const SocketException('offline');
        if (uri.pathSegments.last == '112002.mp3') online = false;
        return serve(_mp3);
      });
      expect(
        await failure(recitations.downloadSurah(Reciter.alafasy, ikhlas)),
        RecitationFailure.offline,
      );
      expect(await recitations.downloaded(Reciter.alafasy, (_) => 4), isEmpty);

      online = true;
      asked.clear();
      await recitations.downloadSurah(Reciter.alafasy, ikhlas);
      expect(asked.map((uri) => uri.pathSegments.last), ['112003.mp3', '112004.mp3']);
      expect(await recitations.downloaded(Reciter.alafasy, (_) => 4), [
        (surah: 112, bytes: 4 * _mp3.length),
      ]);
    });

    test("delete takes the surah's files and leaves the bismillah to al-fatiha", () async {
      final recitations = files((_) => serve(_mp3));
      await recitations.downloadSurah(Reciter.alafasy, ikhlas);
      await recitations.file(Reciter.alafasy, const AyahKey(113, 1));
      await recitations.deleteSurah(Reciter.alafasy, 112);

      expect(left()..sort(), ['001001.mp3', '113001.mp3']);
      expect(await recitations.isSurahReady(Reciter.alafasy, ikhlas), isFalse);
    });

    test(
      'deleting al-fatiha keeps its first ayah while another surah reads it as bismillah',
      () async {
        final recitations = files((_) => serve(_mp3));
        await recitations.downloadSurah(Reciter.alafasy, ikhlas);
        await recitations.downloadSurah(Reciter.alafasy, [
          for (var ayah = 1; ayah <= 7; ayah++) AyahKey(1, ayah),
        ]);
        await recitations.deleteSurah(Reciter.alafasy, 1);

        expect(await recitations.downloaded(Reciter.alafasy, (_) => 4), [
          (surah: 112, bytes: 4 * _mp3.length),
        ]);
      },
    );
  });

  test("on everyayah the bismillah is al-fatiha's first file", () async {
    final recitations = files((_) => serve(_mp3));
    final audio = await recitations.audio(Reciter.alafasy, const AyahKey(112, 0));
    expect(audio, (path: stored('001001.mp3').path, start: null, end: null));
  });

  group('an mp3quran reciter', () {
    const reciter = Reciter.nufais;
    const ikhlas = 112;
    final timings = jsonEncode([
      for (var ayah = 1; ayah <= 4; ayah++)
        {'ayah': ayah, 'start_time': ayah * 1000, 'end_time': ayah * 1000 + 900, 'page': 'x'},
    ]);
    const surahUri = 'https://cdn.mp3quran.net/audio/ahmad-nufais/r1/112.mp3';
    const timingsUri = 'https://www.mp3quran.net/api/v3/ayat_timing?surah=112&read=259';

    Future<Fetched> mp3quran(Uri uri) =>
        uri.host == 'www.mp3quran.net' ? serve(utf8.encode(timings)) : serve(_mp3);

    File kept(String name) => File('${root.path}/recitations/nufais/$name');

    test('the surah file and its timings are on mp3quran over https', () {
      expect(RecitationFiles.surahAddress(reciter, ikhlas).toString(), surahUri);
      expect(RecitationFiles.timingsAddress(reciter, ikhlas).toString(), timingsUri);
    });

    test('a surah not downloaded streams, each ayah its part of the file', () async {
      final recitations = files(mp3quran);
      expect(await recitations.audio(reciter, const AyahKey(ikhlas, 2)), (
        path: surahUri,
        start: const Duration(seconds: 2),
        end: const Duration(milliseconds: 2900),
      ));
      expect(await recitations.audio(reciter, const AyahKey(ikhlas, 0)), (
        path: surahUri,
        start: Duration.zero,
        end: const Duration(seconds: 1),
      ));
      recitations.ahead(reciter, const [AyahKey(ikhlas, 3), AyahKey(ikhlas, 4)]);
      await Future<void>.delayed(Duration.zero);

      /// the timings once, kept, and no audio fetched
      expect(asked.map((uri) => '$uri'), [timingsUri]);
      expect(kept('112.json').existsSync(), isTrue);
      expect(kept('112.mp3').existsSync(), isFalse);
    });

    test('kept timings play with no network', () async {
      await files(mp3quran).audio(reciter, const AyahKey(ikhlas, 1));
      asked.clear();
      final offline = files((_) => throw const SocketException('offline'));
      expect(
        (await offline.audio(reciter, const AyahKey(ikhlas, 4))).end,
        const Duration(seconds: 4, milliseconds: 900),
      );
      expect(asked, isEmpty);
    });

    test('timings out of order or not json leave nothing and are asked again', () async {
      for (final body in [
        '<html>not found</html>',
        jsonEncode([
          {'ayah': 2, 'start_time': 0, 'end_time': 900},
        ]),
        jsonEncode([
          {'ayah': 1, 'start_time': 900, 'end_time': 100},
        ]),
      ]) {
        final recitations = files((_) => serve(utf8.encode(body)));
        expect(
          await failure(recitations.audio(reciter, const AyahKey(ikhlas, 1))),
          RecitationFailure.failed,
        );
        expect(kept('112.json').existsSync(), isFalse);
        asked.clear();
        await failure(recitations.audio(reciter, const AyahKey(ikhlas, 1)));
        expect(asked, hasLength(1));
      }
    });

    test('offline with no timings reports offline', () async {
      final recitations = files((_) => throw const SocketException('offline'));
      expect(
        await failure(recitations.audio(reciter, const AyahKey(ikhlas, 1))),
        RecitationFailure.offline,
      );
    });

    test('a download keeps the file and the timings, then plays from the phone', () async {
      final recitations = files(mp3quran);
      final progress = <double>[];
      await recitations.downloadSurah(reciter, surahFiles(ikhlas, 4), onProgress: progress.add);

      expect(asked.map((uri) => '$uri'), [timingsUri, surahUri]);
      expect(progress.last, 1);
      expect(await recitations.isSurahReady(reciter, surahFiles(ikhlas, 4)), isTrue);
      expect(await recitations.downloaded(reciter, (_) => 4), [
        (surah: ikhlas, bytes: _mp3.length),
      ]);
      expect(
        (await recitations.audio(reciter, const AyahKey(ikhlas, 1))).path,
        kept('112.mp3').path,
      );

      await recitations.deleteSurah(reciter, ikhlas);
      expect(kept('112.mp3').existsSync(), isFalse);
      expect(kept('112.json').existsSync(), isFalse);
      expect(await recitations.isSurahReady(reciter, surahFiles(ikhlas, 4)), isFalse);
    });

    test('timings that miss an ayah fail the download before the file', () async {
      final recitations = files(mp3quran);
      expect(
        await failure(recitations.downloadSurah(reciter, surahFiles(ikhlas, 5))),
        RecitationFailure.failed,
      );
      expect(asked.map((uri) => '$uri'), [timingsUri]);
    });

    test('a surah the check found wrong is missing and asks nothing', () async {
      final wrong = Reciter.values.firstWhere((reciter) => reciter.missing.isNotEmpty);
      final surah = wrong.missing.first;
      final recitations = files(mp3quran);
      expect(await failure(recitations.audio(wrong, AyahKey(surah, 1))), RecitationFailure.missing);
      expect(
        await failure(recitations.downloadSurah(wrong, surahFiles(surah, 1))),
        RecitationFailure.missing,
      );
      expect(asked, isEmpty);
    });
  });
}
