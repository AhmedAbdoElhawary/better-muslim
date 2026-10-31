import 'dart:io';

import 'package:crypto/crypto.dart';

/// a download's length from its header and its body
typedef Fetched = ({int? length, Stream<List<int>> bytes});

enum DownloadFailure { offline, failed, cancelled }

class DownloadException implements Exception {
  const DownloadException(this.failure);

  final DownloadFailure failure;

  @override
  String toString() => 'DownloadException($failure)';
}

/// https only and no headers beyond the defaults (FR-034)
Future<Fetched> fetchUri(Uri uri) async {
  final client = HttpClient()..userAgent = null;
  try {
    final response = await (await client.getUrl(uri)).close();
    if (response.statusCode != HttpStatus.ok) throw HttpException('${response.statusCode}');
    final length = response.contentLength;
    return (length: length < 0 ? null : length, bytes: response);
  } finally {
    /// not forced, the open response still finishes
    client.close();
  }
}

/// written to a .part and renamed only when its sha256 matches, so a half or wrong file never
/// stays. progress is 0 to 1, or null when the server sends no size
Future<void> saveVerified(
  Uri uri,
  File file, {
  required String sha256Hex,
  Future<Fetched> Function(Uri uri) fetch = fetchUri,
  bool Function()? cancelled,
  void Function(double? progress)? onProgress,
}) async {
  if (uri.scheme != 'https') throw const DownloadException(DownloadFailure.failed);
  final part = File('${file.path}.part');
  final Fetched fetched;
  try {
    fetched = await fetch(uri);
  } on SocketException {
    throw const DownloadException(DownloadFailure.offline);
  } on IOException {
    throw const DownloadException(DownloadFailure.failed);
  }
  final digest = _Digest();
  final hash = sha256.startChunkedConversion(digest);
  final sink = part.openWrite();
  var written = 0;
  try {
    await for (final chunk in fetched.bytes) {
      if (cancelled?.call() ?? false) throw const DownloadException(DownloadFailure.cancelled);
      hash.add(chunk);
      sink.add(chunk);
      written += chunk.length;
      final length = fetched.length;
      onProgress?.call(length == null ? null : written / length);
    }
    hash.close();
    await sink.close();
  } on Object catch (error) {
    await sink.close().catchError((_) {});
    if (part.existsSync()) part.deleteSync();
    if (error is DownloadException) rethrow;
    throw DownloadException(
      error is SocketException ? DownloadFailure.offline : DownloadFailure.failed,
    );
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
