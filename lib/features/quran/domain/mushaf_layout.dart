import 'dart:math' as math;
import 'dart:ui';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';

/// where every line and word of a page sits, in the page's own coordinates (research R2, R3)
class MushafLayout {
  const MushafLayout({required this.lines, required this.words, required this.scales});

  /// each line's band, the text area's width and its line's height
  final List<Rect> lines;

  /// each word's rect, the full height of its band so a tap anywhere on the line finds it
  final List<List<Rect>> words;

  /// a line wider than the area is squeezed on its own, 1 for the rest
  final List<double> scales;
}

/// lays the words right to left with the leftover width shared between the gaps, like print.
/// widths are the words' measured widths per line, bands each line's height stacked from the
/// area's top, gap the natural space between two words
MushafLayout layoutMushaf({
  required MushafPage page,
  required List<List<double>> widths,
  required List<double> bands,
  required Rect area,
  required double gap,
}) {
  final lines = <Rect>[];
  final words = <List<Rect>>[];
  final scales = <double>[];
  var top = area.top;
  for (var i = 0; i < page.lines.length; i++) {
    final band = Rect.fromLTWH(area.left, top, area.width, bands[i]);
    top += bands[i];
    lines.add(band);
    final line = widths[i];
    if (line.isEmpty) {
      words.add(const []);
      scales.add(1);
      continue;
    }
    final total = line.fold(0.0, (sum, width) => sum + width);
    final natural = total + gap * (line.length - 1);
    final scale = math.min(1.0, area.width / natural);
    final justify = !page.lines[i].centered && line.length > 1 && scale == 1;
    final space = justify ? (area.width - total) / (line.length - 1) : gap * scale;
    var x = justify ? area.right : area.right - (area.width - natural * scale) / 2;
    final rects = <Rect>[];
    for (final width in line) {
      rects.add(Rect.fromLTRB(x - width * scale, band.top, x, band.bottom));
      x -= width * scale + space;
    }
    words.add(rects);
    scales.add(scale);
  }
  return MushafLayout(lines: lines, words: words, scales: scales);
}

/// the wash behind one ayah (research R4): per line it sits on, one rect from its first to its
/// last word, height tall around the line's middle and wider by side on each end
List<Rect> washRects(
  MushafPage page,
  MushafLayout layout,
  AyahKey key, {
  required double height,
  required double side,
}) {
  final rects = <Rect>[];
  for (var i = 0; i < page.lines.length; i++) {
    Rect? part;
    for (var j = 0; j < page.lines[i].words.length; j++) {
      if (page.lines[i].words[j].key != key) continue;
      final word = layout.words[i][j];
      part = part?.expandToInclude(word) ?? word;
    }
    if (part == null) continue;
    final middle = layout.lines[i].center.dy;
    rects.add(
      Rect.fromLTRB(part.left - side, middle - height / 2, part.right + side, middle + height / 2),
    );
  }
  return rects;
}

/// a mushaf larger than print: the page's words flow into lines as wide as width, in order. a surah
/// name and the basmallah keep their own lines, the last line of a run is centered like print
MushafPage reflowMushaf(
  MushafPage page, {
  required List<List<double>> widths,
  required double width,
  required double gap,
}) {
  final lines = <MushafLine>[];
  var words = <MushafWord>[];
  var used = 0.0;
  void flush({required bool last}) {
    if (words.isNotEmpty) {
      lines.add(MushafLine(type: MushafLineType.ayah, centered: last, words: words));
    }
    words = [];
    used = 0;
  }

  for (var i = 0; i < page.lines.length; i++) {
    final line = page.lines[i];
    if (line.type != MushafLineType.ayah) {
      flush(last: true);
      lines.add(line);
      continue;
    }
    for (var j = 0; j < line.words.length; j++) {
      final next = words.isEmpty ? widths[i][j] : used + gap + widths[i][j];
      if (words.isNotEmpty && next > width) {
        flush(last: false);
        used = widths[i][j];
      } else {
        used = next;
      }
      words.add(line.words[j]);
    }
  }
  flush(last: true);
  return MushafPage(number: page.number, lines: lines);
}

/// how far the page goes up so the ayah stays gap above the sheet, never down
double ayahLift({required double bottom, required double sheetTop, required double gap}) =>
    math.max(0, bottom + gap - sheetTop);

/// pages 3 to 604 split the text area's height into 15 equal bands
List<double> regularBands(double height) => List.filled(mushafLines, height / mushafLines);

const mushafLines = 15;
