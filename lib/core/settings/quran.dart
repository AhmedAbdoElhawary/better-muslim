import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

/// here and not in the quran feature, the settings table in core stores them
enum PageColor {
  followSky,
  white,
  paper,
  cream,
  sepia,
  green,
  night,
  navy;

  bool get dark => this == PageColor.night || this == PageColor.navy;

  /// a StringsManager key
  String get label => switch (this) {
    /// it follows the app's mode, which may follow the phone and not the sky
    PageColor.followSky => StringsManager.matchApp,
    PageColor.white => StringsManager.white,
    PageColor.paper => StringsManager.paper,
    PageColor.cream => StringsManager.cream,
    PageColor.sepia => StringsManager.sepia,
    PageColor.green => StringsManager.green,
    PageColor.night => StringsManager.night,
    PageColor.navy => StringsManager.navy,
  };

  /// follow sky takes the app's mode now, which may itself follow the sky or the phone
  PageColor resolve({required bool dark}) => switch (this) {
    PageColor.followSky => dark ? PageColor.night : PageColor.paper,
    _ => this,
  };
}

enum QuranLayout { mushaf, translation }

/// Display's mushaf size, 10% steps around the printed page
const mushafSizeSteps = (min: -2, max: 5);

double mushafScale(int step) => 1 + step / 10;

/// the tajweed key grows half as fast as the page, its names have no room for more
double tajweedKeyScale(int step) => 1 + step / 20;

enum PageTurn { book, slide }

/// how the mushaf page draws its words. text ships in the app, each qcf style is one downloaded
/// file of its 604 page fonts (specs/016-mushaf-styles)
enum MushafStyle {
  text(
    StringsManager.mushafStyleText,
    StringsManager.mushafStyleTextBody,
    file: '',
    sha256: '',
    bytes: 0,
    ink: 0,
  ),
  qcfV2(
    StringsManager.mushafStyleQcfV2,
    StringsManager.mushafStyleQcfV2Body,
    file: 'qcf_v2.bin',
    sha256: 'afc23e9de91349a1b274bb7e497c573021d88aaff1832514464d2813b65a57f6',
    bytes: 134615846,
    ink: .38,
  ),
  qcfV4(
    StringsManager.mushafStyleQcfV4,
    StringsManager.mushafStyleQcfV4Body,
    file: 'qcf_v4.bin',
    sha256: 'c375f7353bf5857f83fc475a8f1fcdc035eb85e70214b95aece44dd5341259db',
    bytes: 68495168,
    ink: .37,
  ),
  qcfV1(
    StringsManager.mushafStyleQcfV1,
    StringsManager.mushafStyleQcfV1Body,
    file: 'qcf_v1.bin',
    sha256: 'ad3f1a37b13197de338a4dd90d88a809874e08d9d8e118b5f27f7de1414667cb',
    bytes: 54262514,
    ink: .28,
  );

  const MushafStyle(
    this.label,
    this.body, {
    required this.file,
    required this.sha256,
    required this.bytes,
    required this.ink,
  });

  /// StringsManager keys
  final String label;
  final String body;

  final String file;
  final String sha256;

  /// the file's size, shown before it's on the phone
  final int bytes;

  /// like QuranFont.ink, measured over the glyphs' outlines on every 7th page. text takes its font's
  final double ink;

  /// a release once uploaded is never changed, a new build of the files goes in a new one
  Uri get address => contentReleases.resolve('mushaf-v1/$file');

  /// V4 colors its words from its font, in a light, a dark and a sepia palette
  bool get colored => this == qcfV4;

  /// the font's palette for a resolved page color, 0 for a style with one
  int palette(PageColor color) => !colored
      ? 0
      : color.dark
      ? 1
      : color == PageColor.sepia
      ? 2
      : 0;
}

/// the meaning under each ayah, all in the app. sahih international and al-muyassar are in the
/// surah files, the rest one file each from tanzil
enum Translation {
  sahih(StringsManager.sahihInternational, arabic: false),
  pickthall(StringsManager.pickthall, arabic: false, file: 'en.pickthall'),
  yusufAli(StringsManager.yusufAli, arabic: false, file: 'en.yusufali'),
  hilali(StringsManager.hilaliKhan, arabic: false, file: 'en.hilali'),
  muyassar(StringsManager.alMuyassar, arabic: true),
  jalalayn(StringsManager.alJalalayn, arabic: true, file: 'ar.jalalayn');

  const Translation(this.label, {required this.arabic, this.file = ''});

  /// a StringsManager key
  final String label;
  final bool arabic;
  final String file;

  /// null until picked, the app language's own (FR-020)
  static Translation of(Translation? picked, {required bool arabic}) =>
      picked ?? (arabic ? muyassar : sahih);
}

/// a bookmark category's, primary is the theme's own and the rest are fixed
enum CategoryColor { primary, green, teal, blue, violet, rose, amber, slate }

/// the mushaf and share font, picked in Display (FR-011, FR-026)
enum QuranFont {
  amiri(StringsManager.fontAmiri, FontEnum.quran, ink: .4),
  kfgqpc(StringsManager.fontKfgqpc, FontEnum.kfgqpc, ink: .31),
  scheherazade(StringsManager.fontScheherazade, FontEnum.scheherazade, ink: .36);

  const QuranFont(this.label, this.font, {required this.ink});

  final String label;
  final FontEnum font;

  /// the middle of a line's ink above its baseline in ems, measured over the page text. the text
  /// box's middle is up to 4 pt off it, so the washes center on this
  final double ink;

  String get family => font.arabic;

  /// the text as this font draws it. the text writes open tanween as U+0657, U+065E and U+0656,
  /// only KFGQPC reads them so, the others have them at U+08F0 to U+08F2
  String drawn(String text) => this == kfgqpc
      ? text
      : text
            .replaceAll('\u0657', '\u08F0')
            .replaceAll('\u065E', '\u08F1')
            .replaceAll('\u0656', '\u08F2');
}

/// a voice for the recitation, an everyayah folder or an mp3quran one. label, short and initials
/// are StringsManager keys
enum Reciter {
  alafasy(
    'Alafasy_128kbps',
    StringsManager.reciterAlafasy,
    StringsManager.reciterAlafasyShort,
    StringsManager.reciterAlafasyInitials,
  ),
  husary(
    'Husary_128kbps',
    StringsManager.reciterHusary,
    StringsManager.reciterHusaryShort,
    StringsManager.reciterHusaryInitials,
  ),
  abdulBasit(
    'Abdul_Basit_Murattal_192kbps',
    StringsManager.reciterAbdulBasit,
    StringsManager.reciterAbdulBasitShort,
    StringsManager.reciterAbdulBasitInitials,
  ),
  minshawi(
    'Minshawy_Murattal_128kbps',
    StringsManager.reciterMinshawi,
    StringsManager.reciterMinshawiShort,
    StringsManager.reciterMinshawiInitials,
  ),
  maher(
    'MaherAlMuaiqly128kbps',
    StringsManager.reciterMaher,
    StringsManager.reciterMaherShort,
    StringsManager.reciterMaherInitials,
  ),
  abdulBasitMujawwad(
    'Abdul_Basit_Mujawwad_128kbps',
    StringsManager.reciterAbdulBasitMujawwad,
    StringsManager.reciterAbdulBasitMujawwadShort,
    StringsManager.reciterAbdulBasitMujawwadInitials,
  ),
  basfar(
    'Abdullah_Basfar_64kbps',
    StringsManager.reciterBasfar,
    StringsManager.reciterBasfarShort,
    StringsManager.reciterBasfarInitials,
  ),
  sudais(
    'Abdurrahmaan_As-Sudais_64kbps',
    StringsManager.reciterSudais,
    StringsManager.reciterSudaisShort,
    StringsManager.reciterSudaisInitials,
  ),
  shatri(
    'Abu_Bakr_Ash-Shaatree_128kbps',
    StringsManager.reciterShatri,
    StringsManager.reciterShatriShort,
    StringsManager.reciterShatriInitials,
  ),
  ajamy(
    'ahmed_ibn_ali_al_ajamy_128kbps',
    StringsManager.reciterAjamy,
    StringsManager.reciterAjamyShort,
    StringsManager.reciterAjamyInitials,
  ),
  ghamdi(
    'Ghamadi_40kbps',
    StringsManager.reciterGhamdi,
    StringsManager.reciterGhamdiShort,
    StringsManager.reciterGhamdiInitials,
  ),
  haniRifai(
    'Hani_Rifai_64kbps',
    StringsManager.reciterHaniRifai,
    StringsManager.reciterHaniRifaiShort,
    StringsManager.reciterHaniRifaiInitials,
  ),
  husaryMujawwad(
    'Husary_128kbps_Mujawwad',
    StringsManager.reciterHusaryMujawwad,
    StringsManager.reciterHusaryMujawwadShort,
    StringsManager.reciterHusaryMujawwadInitials,
  ),
  husaryMuallim(
    'Husary_Muallim_128kbps',
    StringsManager.reciterHusaryMuallim,
    StringsManager.reciterHusaryMuallimShort,
    StringsManager.reciterHusaryMuallimInitials,
  ),
  hudhaify(
    'Hudhaify_128kbps',
    StringsManager.reciterHudhaify,
    StringsManager.reciterHudhaifyShort,
    StringsManager.reciterHudhaifyInitials,
  ),
  akhdar(
    'Ibrahim_Akhdar_32kbps',
    StringsManager.reciterAkhdar,
    StringsManager.reciterAkhdarShort,
    StringsManager.reciterAkhdarInitials,
  ),
  minshawiMujawwad(
    'Minshawy_Mujawwad_64kbps',
    StringsManager.reciterMinshawiMujawwad,
    StringsManager.reciterMinshawiMujawwadShort,
    StringsManager.reciterMinshawiMujawwadInitials,
  ),
  tablawi(
    'Mohammad_al_Tablaway_128kbps',
    StringsManager.reciterTablawi,
    StringsManager.reciterTablawiShort,
    StringsManager.reciterTablawiInitials,
  ),
  ayyub(
    'Muhammad_Ayyoub_128kbps',
    StringsManager.reciterAyyub,
    StringsManager.reciterAyyubShort,
    StringsManager.reciterAyyubInitials,
  ),
  jibreel(
    'Muhammad_Jibreel_128kbps',
    StringsManager.reciterJibreel,
    StringsManager.reciterJibreelShort,
    StringsManager.reciterJibreelInitials,
  ),
  shuraim(
    'Saood_ash-Shuraym_128kbps',
    StringsManager.reciterShuraim,
    StringsManager.reciterShuraimShort,
    StringsManager.reciterShuraimInitials,
  ),
  parhizgar(
    'Parhizgar_48kbps',
    StringsManager.reciterParhizgar,
    StringsManager.reciterParhizgarShort,
    StringsManager.reciterParhizgarInitials,
  ),
  bukhatir(
    'Salaah_AbdulRahman_Bukhatir_128kbps',
    StringsManager.reciterBukhatir,
    StringsManager.reciterBukhatirShort,
    StringsManager.reciterBukhatirInitials,
  ),
  qasim(
    'Muhsin_Al_Qasim_192kbps',
    StringsManager.reciterQasim,
    StringsManager.reciterQasimShort,
    StringsManager.reciterQasimInitials,
  ),
  juhani(
    'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
    StringsManager.reciterJuhani,
    StringsManager.reciterJuhaniShort,
    StringsManager.reciterJuhaniInitials,
  ),
  budair(
    'Salah_Al_Budair_128kbps',
    StringsManager.reciterBudair,
    StringsManager.reciterBudairShort,
    StringsManager.reciterBudairInitials,
  ),
  matrood(
    'Abdullah_Matroud_128kbps',
    StringsManager.reciterMatrood,
    StringsManager.reciterMatroodShort,
    StringsManager.reciterMatroodInitials,
  ),
  nuaina(
    'Ahmed_Neana_128kbps',
    StringsManager.reciterNuaina,
    StringsManager.reciterNuainaShort,
    StringsManager.reciterNuainaInitials,
  ),
  abdulKareem(
    'Muhammad_AbdulKareem_128kbps',
    StringsManager.reciterAbdulKareem,
    StringsManager.reciterAbdulKareemShort,
    StringsManager.reciterAbdulKareemInitials,
  ),
  tunaiji(
    'khalefa_al_tunaiji_64kbps',
    StringsManager.reciterTunaiji,
    StringsManager.reciterTunaijiShort,
    StringsManager.reciterTunaijiInitials,
  ),
  banna(
    'mahmoud_ali_al_banna_32kbps',
    StringsManager.reciterBanna,
    StringsManager.reciterBannaShort,
    StringsManager.reciterBannaInitials,
  ),
  mansoori(
    'Karim_Mansoori_40kbps',
    StringsManager.reciterMansoori,
    StringsManager.reciterMansooriShort,
    StringsManager.reciterMansooriInitials,
  ),
  qahtani(
    'Khaalid_Abdullaah_al-Qahtaanee_192kbps',
    StringsManager.reciterQahtani,
    StringsManager.reciterQahtaniShort,
    StringsManager.reciterQahtaniInitials,
  ),
  dosari(
    'Yasser_Ad-Dussary_128kbps',
    StringsManager.reciterDosari,
    StringsManager.reciterDosariShort,
    StringsManager.reciterDosariInitials,
  ),
  qatami(
    'Nasser_Alqatami_128kbps',
    StringsManager.reciterQatami,
    StringsManager.reciterQatamiShort,
    StringsManager.reciterQatamiInitials,
  ),
  suesy(
    'Ali_Hajjaj_AlSuesy_128kbps',
    StringsManager.reciterSuesy,
    StringsManager.reciterSuesyShort,
    StringsManager.reciterSuesyInitials,
  ),
  sahlYassin(
    'Sahl_Yassin_128kbps',
    StringsManager.reciterSahlYassin,
    StringsManager.reciterSahlYassinShort,
    StringsManager.reciterSahlYassinInitials,
  ),
  alili(
    'aziz_alili_128kbps',
    StringsManager.reciterAlili,
    StringsManager.reciterAliliShort,
    StringsManager.reciterAliliInitials,
  ),
  salamah(
    'Yaser_Salamah_128kbps',
    StringsManager.reciterSalamah,
    StringsManager.reciterSalamahShort,
    StringsManager.reciterSalamahInitials,
  ),
  alaqimy(
    'Akram_AlAlaqimy_128kbps',
    StringsManager.reciterAlaqimy,
    StringsManager.reciterAlaqimyShort,
    StringsManager.reciterAlaqimyInitials,
  ),
  aliJaber(
    'Ali_Jaber_64kbps',
    StringsManager.reciterAliJaber,
    StringsManager.reciterAliJaberShort,
    StringsManager.reciterAliJaberInitials,
  ),
  faresAbbad(
    'Fares_Abbad_64kbps',
    StringsManager.reciterFaresAbbad,
    StringsManager.reciterFaresAbbadShort,
    StringsManager.reciterFaresAbbadInitials,
  ),
  aymanSuwayd(
    'Ayman_Sowaid_64kbps',
    StringsManager.reciterAymanSuwayd,
    StringsManager.reciterAymanSuwaydShort,
    StringsManager.reciterAymanSuwaydInitials,
  ),
  nufais(
    'ahmad-nufais/r1',
    StringsManager.reciterNufais,
    StringsManager.reciterNufaisShort,
    StringsManager.reciterNufaisInitials,
    read: 259,
    missing: {1, 2, 17, 20, 53, 68, 70, 71, 73, 92},
  ),
  hassanSaleh(
    'hassan-saleh/r1',
    StringsManager.reciterHassanSaleh,
    StringsManager.reciterHassanSalehShort,
    StringsManager.reciterHassanSalehInitials,
    read: 299,
    missing: {23, 24, 25, 42, 43, 44, 45, 46, 47, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66},
  ),
  dukhain(
    'haitham-dukhain/r1',
    StringsManager.reciterDukhain,
    StringsManager.reciterDukhainShort,
    StringsManager.reciterDukhainInitials,
    read: 273,
    missing: {40, 41, 65, 71, 72, 73, 76},
  );

  const Reciter(
    this.folder,
    this.label,
    this.short,
    this.initials, {
    this.read,
    this.missing = const {},
  });

  final String folder;
  final String label;
  final String short;
  final String initials;

  /// mp3quran's read, one file per surah cut into ayahs by its timings (ADR 0005). null on everyayah
  final int? read;

  /// surahs whose file or timings don't match, from tool/quran/check_surah_reciters.py
  final Set<int> missing;
}
