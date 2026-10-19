import 'package:better_muslim/core/resources/strings_manager.dart';

/// a source the app uses, with the credit its license asks for (FR-033)
class Credit {
  const Credit({required this.source, required this.useKey, this.license, this.link});

  /// as written by its owner, never translated
  final String source;

  /// what the app uses it for, a StringsManager key
  final String useKey;
  final String? license;

  /// https only, the system channel refuses anything else
  final String? link;
}

const _ofl = 'SIL OFL 1.1';

const credits = [
  Credit(
    source: 'GeoNames',
    useKey: StringsManager.usePlaceNames,
    license: 'CC BY 4.0',
    link: 'https://www.geonames.org',
  ),
  Credit(
    source: 'Marcellus',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/specimen/Marcellus',
  ),
  Credit(
    source: 'Schibsted Grotesk',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/specimen/Schibsted+Grotesk',
  ),
  Credit(
    source: 'Reem Kufi',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/specimen/Reem+Kufi',
  ),
  Credit(
    source: 'Noto Sans Arabic',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/noto/specimen/Noto+Sans+Arabic',
  ),
  Credit(
    source: 'Amiri',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/specimen/Amiri',
  ),
  // TODO(ahmed): confirm the source of the azkar and duas text and translation, add its license and https link, a wrong credit breaks the license.
  Credit(source: 'Hisn al-Muslim', useKey: StringsManager.useAzkarDuas),
  // TODO(ahmed): the adhan recordings' source, license and https link once the licensed files are in.
  Credit(source: 'Adhan of Makkah', useKey: StringsManager.useAdhanRecordings),
];
