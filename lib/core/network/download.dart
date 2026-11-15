import 'dart:async';
import 'dart:io';

import 'package:better_muslim/core/network/download_notice.dart';
import 'package:crypto/crypto.dart';

/// the tafsirs and mushaf styles. a public repo of its own, this one is private and its releases
/// need a token
final contentReleases = Uri.parse(
  'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/',
);

/// a download's length from its header and its body
typedef Fetched = ({int? length, Stream<List<int>> bytes});

/// from is where a paused download goes on, the length is then what is left
typedef Fetch = Future<Fetched> Function(Uri uri, {int from});

/// paused from the notification keeps its .part for the resume
enum DownloadFailure { offline, failed, cancelled, paused }

class DownloadException implements Exception {
  const DownloadException(this.failure);

  final DownloadFailure failure;

  @override
  String toString() => 'DownloadException($failure)';
}

/// https only and no headers beyond the defaults and the range (FR-034). a server that ignores
/// the range throws, the download then starts again from the beginning
Future<Fetched> fetchUri(Uri uri, {int from = 0}) async {
  final client = HttpClient()
    ..userAgent = null
    ..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(uri);
    if (from > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-');
    final response = await request.close();
    final expected = from > 0 ? HttpStatus.partialContent : HttpStatus.ok;
    if (response.statusCode != expected) {
      client.close(force: true);
      throw HttpException('${response.statusCode}');
    }
    final length = response.contentLength;
    return (length: length < 0 ? null : length, bytes: response);
  } finally {
    /// not forced, the open response still finishes
    client.close();
  }
}

/// what is in a .part from a paused download, so the next fetch asks only for the rest
int partLength(File part) => part.existsSync() ? part.lengthSync() : 0;

/// nothing coming in for this long is a lost connection, the phone doesn't always say so
const downloadStall = Duration(seconds: 15);

/// a lost connection, not a bad file or a full disk
bool isOffline(Object error) =>
    error is SocketException || error is HttpException || error is TimeoutException;

bool _offline(Object error) =>
    error is DownloadException && error.failure == DownloadFailure.offline;

/// a lost connection after the first bytes waits for it to come back and runs the job again, the
/// .part goes on from there. offline before any byte, or with no notice, still throws
Future<void> untilOnline(
  Future<void> Function() job, {
  DownloadNotice? notice,
  bool Function()? cancelled,
  bool Function(Object error) offline = _offline,
}) async {
  while (true) {
    try {
      return await job();
    } on Object catch (error) {
      if (!offline(error) || !(notice?.started ?? false)) rethrow;
    }
    await notice!.waitOnline(cancelled: cancelled);
  }
}

/// written to a .part and renamed only when its sha256 matches, so a half or wrong file never
/// stays. progress is 0 to 1, or null when the server sends no size. a .part left by a pause or a
/// lost connection is kept and goes on
Future<void> saveVerified(
  Uri uri,
  File file, {
  required String sha256Hex,
  Fetch fetch = fetchUri,
  bool Function()? cancelled,
  void Function(double? progress)? onProgress,
  DownloadNotice? notice,
}) async {
  if (uri.scheme != 'https') throw const DownloadException(DownloadFailure.failed);
  final part = File('${file.path}.part');
  notice?.part = part.path;
  var from = partLength(part);
  Fetched fetched;
  try {
    try {
      fetched = await fetch(uri, from: from);
    } on HttpException {
      if (from == 0) rethrow;
      part.deleteSync();
      from = 0;
      fetched = await fetch(uri);
    }
  } on SocketException {
    throw const DownloadException(DownloadFailure.offline);
  } on IOException {
    throw const DownloadException(DownloadFailure.failed);
  }
  final digest = _Digest();
  final hash = sha256.startChunkedConversion(digest);
  if (from > 0) await part.openRead().forEach(hash.add);
  final sink = part.openWrite(mode: from > 0 ? FileMode.append : FileMode.write);
  final total = fetched.length == null ? null : from + fetched.length!;
  var written = from;
  try {
    await for (final chunk in fetched.bytes.timeout(downloadStall)) {
      if (cancelled?.call() ?? false) throw const DownloadException(DownloadFailure.cancelled);
      notice?.progress(written, total);
      hash.add(chunk);
      sink.add(chunk);
      written += chunk.length;
      onProgress?.call(total == null ? null : written / total);
    }
    hash.close();
    await sink.close();
  } on Object catch (error) {
    await sink.close().catchError((_) {});
    final paused = error is DownloadException && error.failure == DownloadFailure.paused;
    if (!paused && !isOffline(error) && part.existsSync()) part.deleteSync();
    if (error is DownloadException) rethrow;
    throw DownloadException(isOffline(error) ? DownloadFailure.offline : DownloadFailure.failed);
  }
  if ('${digest.value}' != sha256Hex) {
    part.deleteSync();
    throw const DownloadException(DownloadFailure.failed);
  }
  part.renameSync(file.path);
}

/// sha256's chunked conversion hands its one digest to a sink
class _Digest implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
