import 'package:better_muslim/core/resources/strings_manager.dart';

/// the dua after the adhan. content, not ui text, so it is not in the arb files
// TODO(ahmed): check the dua text, transliteration and translation against Bukhari 614.
abstract final class DuaAfterAdhan {
  static const titleKey = StringsManager.afterTheAdhan;
  static const sourceEn = 'Sahih al-Bukhari 614';
  static const sourceAr = 'صحيح البخاري ٦١٤';
  static const arabic =
      'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ '
      'وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ';
  static const transliteration =
      'Allāhumma rabba hādhihi-d-da‘wati-t-tāmmah, wa-ṣ-ṣalāti-l-qā’imah, āti Muḥammadan '
      'al-wasīlata wa-l-faḍīlah, wa-b‘ath-hu maqāman maḥmūdan alladhī wa‘adtah.';
  static const translation =
      'O Allah, Lord of this perfect call and of the prayer about to be established, grant '
      'Muhammad the means of nearness and the excellence, and raise him to the praised station '
      'You promised him.';

  /// the adhan screen's card shows only the start (4.03)
  static const firstLine = 'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ';
  static const firstTranslation = 'O Allah, Lord of this perfect call…';
}
