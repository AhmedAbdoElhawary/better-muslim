import 'package:better_muslim/core/resources/strings_manager.dart';

/// a source whose license or terms ask for credit (FR-033)
class Credit {
  const Credit({required this.source, required this.useKey, this.license});

  /// as written by its owner, never translated
  final String source;

  /// what the app uses it for, a StringsManager key
  final String useKey;
  final String? license;
}

const credits = [
  Credit(source: 'GeoNames', useKey: StringsManager.usePlaceNames, license: 'CC BY 4.0'),
  Credit(
    source: 'King Fahd Glorious Quran Printing Complex',
    useKey: StringsManager.useMushafFonts,
  ),
  Credit(source: 'Tanzil', useKey: StringsManager.useTranslationsTafsir),
  Credit(source: 'Quranic Arabic Corpus', useKey: StringsManager.useWordRoots, license: 'GNU GPL'),
];
