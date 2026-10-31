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
  Credit(
    source: 'Amiri Quran',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://fonts.google.com/specimen/Amiri+Quran',
  ),
  Credit(
    source: 'Scheherazade New',
    useKey: StringsManager.useFonts,
    license: _ofl,
    link: 'https://software.sil.org/scheherazade',
  ),

  /// its license lets it be used and shipped for free, never sold or modified
  Credit(
    source: 'KFGQPC HAFS Uthmanic Script, King Fahd Glorious Quran Printing Complex',
    useKey: StringsManager.useFonts,
    license: 'KFGQPC EULA',
    link: 'https://fonts.qurancomplex.gov.sa',
  ),

  /// qul's own faq: licenses differ by resource, these two come from the complex's print
  Credit(
    source:
        'Quranic Universal Library (QUL) · Tarteel, from King Fahd Glorious Quran Printing Complex',
    useKey: StringsManager.useMushafText,
    link: 'https://qul.tarteel.ai',
  ),
  Credit(
    source: 'Tanzil · Sahih International',
    useKey: StringsManager.useTranslation,
    link: 'https://tanzil.net',
  ),
  Credit(
    source: 'Tanzil · Tafsir al-Muyassar',
    useKey: StringsManager.useTafsir,
    link: 'https://tanzil.net',
  ),
  Credit(
    source:
        "Quran.com · Tafsir Ibn Kathir · Tafsir as-Sa'di · Tafsir al-Tabari · Tafsir al-Qurtubi",
    useKey: StringsManager.useTafsir,
    link: 'https://quran.com',
  ),
  Credit(
    source: 'EveryAyah · Mishary Rashid Alafasy',
    useKey: StringsManager.useRecitation,
    link: 'https://everyayah.com',
  ),
  Credit(
    source: 'EveryAyah · Mahmoud Khalil Al-Husary',
    useKey: StringsManager.useRecitation,
    link: 'https://everyayah.com',
  ),
  Credit(
    source: 'EveryAyah · Abdul Basit Abdul Samad',
    useKey: StringsManager.useRecitation,
    link: 'https://everyayah.com',
  ),
  Credit(
    source: 'EveryAyah · Mohamed Siddiq Al-Minshawi',
    useKey: StringsManager.useRecitation,
    link: 'https://everyayah.com',
  ),
  Credit(
    source: 'EveryAyah · Maher Al-Muaiqly',
    useKey: StringsManager.useRecitation,
    link: 'https://everyayah.com',
  ),
  Credit(
    source: "Hisn al-Muslim · Sa'id al-Qahtani",
    useKey: StringsManager.useAzkarDuas,
    link: 'https://www.hisnmuslim.com',
  ),
  Credit(
    source: 'ejaz215 · Wikimedia Commons · Madinah',
    useKey: StringsManager.useAdhanRecordings,
    license: 'CC BY 3.0',
    link: 'https://commons.wikimedia.org/wiki/File:33937_ejaz215_call-to-prayer-from-the-prophet-s-mo.ogg',
  ),
  Credit(
    source: 'Besim Azemi · Islamic Center Malmö · Fajr',
    useKey: StringsManager.useAdhanRecordings,
    license: 'CC BY 3.0',
    link: 'https://commons.wikimedia.org/wiki/File:Eid_al-Fitr_Fajr_azan_at_Malm%C3%B6_Mosque_-_19_August_2012.webm',
  ),
];
