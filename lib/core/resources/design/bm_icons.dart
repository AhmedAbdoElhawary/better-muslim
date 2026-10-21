// enum names are the svg file names, so they keep the files' snake_case
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// All icons are 24 × 24, stroke 1.25, round caps and joins. Tint with [color].
/// Outline = default. Filled = selected tab and active states only.
enum BmIconName {
  home,
  prayer,
  quran,
  qibla,
  tasbih,
  azkar,
  hijri,
  mosque,
  journey,
  names_99,
  hadith,
  adhan,
  bookmark,
  night,
  sunrise,
  settings,
  listen,
  location,
}

enum BmUiIcon {
  back,
  forward,
  check,
  close,
  search,
  share,
  bell_off,
  sun,
  compass,
  calendar,
  dua,
  palette,
  theme_mode,
  motion,
  haptics,
  sound,
  play,
  pause,
  next,
  stop,
  repeat,
  text_size,
  reset,
  lock,
  tafsir,
  note,
  plus,
  minus,
  more_h,
  language,
  contents,
  translate,
  words,
  copy,
  memorize,
  prev,
  spread,
  timer,
  chevron_down,
}

class BmIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;
  const BmIcon._(this.asset, {this.size = 22, this.color});
  factory BmIcon(BmIconName n, {bool filled = false, double size = 22, Color? color}) => BmIcon._(
    'assets/icons/${filled ? 'filled' : 'outline'}/${n.name}.svg',
    size: size,
    color: color,
  );
  factory BmIcon.ui(BmUiIcon n, {double size = 22, Color? color}) =>
      BmIcon._('assets/icons/ui/${n.name}.svg', size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color!;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

/// Mapping used in the design. Screens show icons at 22 (rows, nav), 20 (list rows, actions), 18 (chevrons), 16 (inline), 14/12 (chips).
const bmPrayerIcon = {
  'fajr': BmIconName.sunrise,
  'sunrise': BmIconName.sunrise,
  'dhuhr': BmUiIcon.sun,
  'asr': BmUiIcon.sun,
  'maghrib': BmIconName.sunrise,
  'isha': BmIconName.night,
};
