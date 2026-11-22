import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/network/download_notice.dart';
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
    Fetch? fetch,
    Future<void> Function(String path)? exclude,
    String Function(MushafStyle style)? sha256,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude,
       _sha256 = sha256 ?? ((style) => style.sha256);

  final Future<Directory> Function() _root;
  final Fetch _fetch;
  final Future<void> Function(String path) _exclude;
  final String Function(MushafStyle style) _sha256;

  Future<Directory>? _folder;
  final _cancelled = <MushafStyle>{};

  /// flutter can't unload a font, so each page's is loaded once and kept while the app runs
  final _loading = <(MushafStyle, int, int), Future<String>>{};
  final _loaded = <(MushafStyle, int, int), String>{};
  final _colors = <(MushafStyle, int), Future<List<Color>>>{};
  final _inks = <(MushafStyle, int), Future<Map<int, Rect>>>{};

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
  Future<void> download(
    MushafStyle style, {
    void Function(double? progress)? onProgress,
    DownloadNotice? notice,
  }) async {
    _cancelled.remove(style);
    bool cancelled() => _cancelled.contains(style);
    final file = await _file(style);
    await untilOnline(
      () => saveVerified(
        style.address,
        file,
        sha256Hex: _sha256(style),
        fetch: _fetch,
        cancelled: cancelled,
        onProgress: onProgress,
        notice: notice,
      ),
      notice: notice,
      cancelled: cancelled,
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
        final task = TimelineTask()..start('quran page font $page');
        final family = 'qcf_${style.name}_${page}_$palette';
        final bytes = pageFont(
          style,
          page,
        ).then((font) => ByteData.sublistView(palette == 0 ? font : withPalette(font, palette)));
        await (FontLoader(family)..addFont(bytes)).load();
        task.finish();
        return _loaded[(style, page, palette)] = family;
      }();

  /// a colored style's palette, every page of it has the same one
  Future<List<Color>> colors(MushafStyle style, int page, {int palette = 0}) =>
      _colors[(style, palette)] ??= pageFont(
        style,
        page,
      ).then((font) => paletteColors(font, palette));

  /// the page's glyphs' ink, a bookmarked number centers on its marker's
  Future<Map<int, Rect>> inks(MushafStyle style, int page) =>
      _inks[(style, page)] ??= pageFont(style, page).then(glyphInks);

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

/// each character's ink box in ems from its origin on the baseline, y down, with its colr layers.
/// the qcf markers sit anywhere in their glyph's box, each at its own height
Map<int, Rect> glyphInks(Uint8List font) {
  final data = ByteData.sublistView(font);
  final tables = <String, int>{
    for (var i = 0; i < data.getUint16(4); i++)
      String.fromCharCodes(font, 12 + 16 * i, 16 + 16 * i): data.getUint32(20 + 16 * i),
  };
  final (head, loca, glyf, cmap) = (tables['head'], tables['loca'], tables['glyf'], tables['cmap']);
  if (head == null || loca == null || glyf == null || cmap == null) return const {};
  final em = data.getUint16(head + 18).toDouble();
  final long = data.getInt16(head + 50) == 1;
  Rect? box(int glyph) {
    final (start, end) = long
        ? (data.getUint32(loca + 4 * glyph), data.getUint32(loca + 4 * glyph + 4))
        : (2 * data.getUint16(loca + 2 * glyph), 2 * data.getUint16(loca + 2 * glyph + 2));
    if (start == end) return null;
    final at = glyf + start;
    return Rect.fromLTRB(
      data.getInt16(at + 2) / em,
      -data.getInt16(at + 8) / em,
      data.getInt16(at + 6) / em,
      -data.getInt16(at + 4) / em,
    );
  }

  final layers = <int, List<int>>{};
  if (tables['COLR'] case final colr?) {
    final (bases, records) = (colr + data.getUint32(colr + 4), colr + data.getUint32(colr + 8));
    for (var i = 0; i < data.getUint16(colr + 2); i++) {
      final first = data.getUint16(bases + 6 * i + 2);
      layers[data.getUint16(bases + 6 * i)] = [
        for (var k = first; k < first + data.getUint16(bases + 6 * i + 4); k++)
          data.getUint16(records + 4 * k),
      ];
    }
  }
  final inks = <int, Rect>{};
  void add(int code, int glyph) {
    final boxes = [
      box(glyph),
      for (final layer in layers[glyph] ?? const <int>[]) box(layer),
    ].nonNulls;
    if (glyph != 0 && boxes.isNotEmpty) inks[code] = boxes.reduce((a, b) => a.expandToInclude(b));
  }

  for (var i = 0; i < data.getUint16(cmap + 2); i++) {
    final at = cmap + data.getUint32(cmap + 8 + 8 * i);
    switch (data.getUint16(at)) {
      case 4:
        final segments = data.getUint16(at + 6) ~/ 2;
        final (ends, starts) = (at + 14, at + 16 + 2 * segments);
        final (deltas, offsets) = (starts + 2 * segments, starts + 4 * segments);
        for (var k = 0; k < segments; k++) {
          final delta = data.getInt16(deltas + 2 * k);
          final offset = data.getUint16(offsets + 2 * k);
          final first = data.getUint16(starts + 2 * k);
          for (var code = first; code <= data.getUint16(ends + 2 * k) && code != 0xFFFF; code++) {
            var glyph = code;
            if (offset != 0) {
              glyph = data.getUint16(offsets + 2 * k + offset + 2 * (code - first));
              if (glyph == 0) continue;
            }
            add(code, (glyph + delta) & 0xFFFF);
          }
        }
      case 12:
        for (var k = 0; k < data.getUint32(at + 12); k++) {
          final group = at + 16 + 12 * k;
          final first = data.getUint32(group);
          for (var code = first; code <= data.getUint32(group + 4); code++) {
            add(code, data.getUint32(group + 8) + code - first);
          }
        }
    }
  }
  return inks;
}
