import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final mushafFilesProvider = Provider<MushafFiles>((ref) => MushafFiles());

/// each qcf style is downloaded once and kept only when its sha256 matches. the file is 605 little
/// endian uint32 offsets, then each page's ttf gzipped on its own (tool/quran/build_quran.dart)
class MushafFiles {
  MushafFiles({
    Future<Directory> Function()? root,
    Future<Fetched> Function(Uri uri)? fetch,
    Future<void> Function(String path)? exclude,
    String Function(MushafStyle style)? sha256,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude,
       _sha256 = sha256 ?? ((style) => style.sha256);

  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;
  final String Function(MushafStyle style) _sha256;

  Future<Directory>? _folder;
  final _cancelled = <MushafStyle>{};

  /// flutter can't unload a font, so each page's is loaded once and kept while the app runs
  final _loading = <(MushafStyle, int, int), Future<String>>{};
  final _loaded = <(MushafStyle, int, int), String>{};
  final _colors = <(MushafStyle, int), Future<List<Color>>>{};

  Future<Directory> get folder => _folder ??= () async {
    final folder = Directory('${(await _root()).path}/mushaf');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await _exclude(folder.path);
    }
    return folder;
  }();

  Future<File> _file(MushafStyle style) async => File('${(await folder).path}/${style.file}');

  Future<bool> isReady(MushafStyle style) async =>
      style == MushafStyle.text || (await _file(style)).existsSync();

  /// the qcf styles on the phone with their size
  Future<List<(MushafStyle, int)>> downloaded() async => [
    for (final style in MushafStyle.values.skip(1))
      if (await _file(style) case final file when file.existsSync()) (style, file.lengthSync()),
  ];

  /// progress is 0 to 1, or null when the server sends no size
  Future<void> download(MushafStyle style, {void Function(double? progress)? onProgress}) async {
    _cancelled.remove(style);
    await saveVerified(
      style.address,
      await _file(style),
      sha256Hex: _sha256(style),
      fetch: _fetch,
      cancelled: () => _cancelled.contains(style),
      onProgress: onProgress,
    );
  }

  /// the running download stops at its next chunk and deletes its .part
  void cancel(MushafStyle style) => _cancelled.add(style);

  Future<void> delete(MushafStyle style) async {
    final file = await _file(style);
    if (file.existsSync()) await file.delete();
  }

  /// the page's font family once it's loaded, so a page shown again lays out in its first frame
  String? loaded(MushafStyle style, int page, {int palette = 0}) => _loaded[(style, page, palette)];

  /// loads the page's font as its own family, a V4 one in its palette
  Future<String> family(MushafStyle style, int page, {int palette = 0}) =>
      _loading[(style, page, palette)] ??= () async {
        final family = 'qcf_${style.name}_${page}_$palette';
        final bytes = pageFont(
          style,
          page,
        ).then((font) => ByteData.sublistView(palette == 0 ? font : withPalette(font, palette)));
        await (FontLoader(family)..addFont(bytes)).load();
        return _loaded[(style, page, palette)] = family;
      }();

  /// a colored style's palette, every page of it has the same one
  Future<List<Color>> colors(MushafStyle style, int page, {int palette = 0}) =>
      _colors[(style, palette)] ??= pageFont(
        style,
        page,
      ).then((font) => paletteColors(font, palette));

  /// the page's ttf, unzipped from its place in the style's file
  Future<Uint8List> pageFont(MushafStyle style, int page) async {
    final file = await (await _file(style)).open();
    try {
      await file.setPosition(4 * (page - 1));
      final offsets = ByteData.sublistView(await file.read(8));
      final start = offsets.getUint32(0, Endian.little);
      await file.setPosition(start);
      final bytes = await file.read(offsets.getUint32(4, Endian.little) - start);
      return Uint8List.fromList(gzip.decode(bytes));
    } finally {
      await file.close();
    }
  }
}

/// flutter draws a colr font only in its palette 0, so palette 0 is pointed at the one wanted
Uint8List withPalette(Uint8List font, int palette) {
  final data = ByteData.sublistView(font);
  for (var i = 0; i < data.getUint16(4); i++) {
    if (String.fromCharCodes(font, 12 + 16 * i, 16 + 16 * i) != 'CPAL') continue;
    final cpal = data.getUint32(20 + 16 * i);
    final copy = Uint8List.fromList(font);
    ByteData.sublistView(copy).setUint16(cpal + 12, data.getUint16(cpal + 12 + 2 * palette));
    return copy;
  }
  return font;
}

/// the palette's colors in entry order, cpal keeps each one as b g r a
List<Color> paletteColors(Uint8List font, int palette) {
  final data = ByteData.sublistView(font);
  for (var i = 0; i < data.getUint16(4); i++) {
    if (String.fromCharCodes(font, 12 + 16 * i, 16 + 16 * i) != 'CPAL') continue;
    final cpal = data.getUint32(20 + 16 * i);
    final first = cpal + data.getUint32(cpal + 8) + 4 * data.getUint16(cpal + 12 + 2 * palette);
    return [
      for (var at = first; at < first + 4 * data.getUint16(cpal + 2); at += 4)
        Color(font[at + 3] << 24 | font[at + 2] << 16 | font[at + 1] << 8 | font[at]),
    ];
  }
  return const [];
}
