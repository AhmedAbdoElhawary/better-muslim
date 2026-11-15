// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, AppSettings> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeNameMeta = const VerificationMeta('placeName');
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
    'place_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeNameArMeta = const VerificationMeta('placeNameAr');
  @override
  late final GeneratedColumn<String> placeNameAr = GeneratedColumn<String>(
    'place_name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionNameMeta = const VerificationMeta('regionName');
  @override
  late final GeneratedColumn<String> regionName = GeneratedColumn<String>(
    'region_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionNameArMeta = const VerificationMeta('regionNameAr');
  @override
  late final GeneratedColumn<String> regionNameAr = GeneratedColumn<String>(
    'region_name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta('countryCode');
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta('timeZone');
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocationMode?, String> locationMode =
      GeneratedColumn<String>(
        'location_mode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocationMode?>($SettingsTable.$converterlocationModen);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerMethod?, String> method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PrayerMethod?>($SettingsTable.$convertermethodn);
  @override
  late final GeneratedColumnWithTypeConverter<AsrMethod?, String> asrMethod =
      GeneratedColumn<String>(
        'asr_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<AsrMethod?>($SettingsTable.$converterasrMethodn);
  static const VerificationMeta _hijriAdjustMeta = const VerificationMeta('hijriAdjust');
  @override
  late final GeneratedColumn<int> hijriAdjust = GeneratedColumn<int>(
    'hijri_adjust',
    aliasedName,
    false,
    check: () => ComparableExpr(hijriAdjust).isBetweenValues(-2, 2),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Digits, String> digits = GeneratedColumn<String>(
    'digits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('eastern'),
  ).withConverter<Digits>($SettingsTable.$converterdigits);
  @override
  late final GeneratedColumnWithTypeConverter<BmThemeId, String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('moonlight'),
  ).withConverter<BmThemeId>($SettingsTable.$convertertheme);
  @override
  late final GeneratedColumnWithTypeConverter<BmThemeMode, String> themeMode =
      GeneratedColumn<String>(
        'theme_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('followPhone'),
      ).withConverter<BmThemeMode>($SettingsTable.$converterthemeMode);
  static const VerificationMeta _reduceMotionMeta = const VerificationMeta('reduceMotion');
  @override
  late final GeneratedColumn<bool> reduceMotion = GeneratedColumn<bool>(
    'reduce_motion',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("reduce_motion" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hapticsMeta = const VerificationMeta('haptics');
  @override
  late final GeneratedColumn<bool> haptics = GeneratedColumn<bool>(
    'haptics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("haptics" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _uiSoundsMeta = const VerificationMeta('uiSounds');
  @override
  late final GeneratedColumn<bool> uiSounds = GeneratedColumn<bool>(
    'ui_sounds',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("ui_sounds" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> firstUse = GeneratedColumn<String>(
    'first_use',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($SettingsTable.$converterfirstUsen);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerSound, String> fajrSound =
      GeneratedColumn<String>(
        'fajr_sound',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('adhan'),
      ).withConverter<PrayerSound>($SettingsTable.$converterfajrSound);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerSound, String> dhuhrSound =
      GeneratedColumn<String>(
        'dhuhr_sound',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('tone'),
      ).withConverter<PrayerSound>($SettingsTable.$converterdhuhrSound);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerSound, String> asrSound =
      GeneratedColumn<String>(
        'asr_sound',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('tone'),
      ).withConverter<PrayerSound>($SettingsTable.$converterasrSound);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerSound, String> maghribSound =
      GeneratedColumn<String>(
        'maghrib_sound',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('adhan'),
      ).withConverter<PrayerSound>($SettingsTable.$convertermaghribSound);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerSound, String> ishaSound =
      GeneratedColumn<String>(
        'isha_sound',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('tone'),
      ).withConverter<PrayerSound>($SettingsTable.$converterishaSound);
  @override
  late final GeneratedColumnWithTypeConverter<AdhanRecording, String> fajrRecording =
      GeneratedColumn<String>(
        'fajr_recording',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('alafasy'),
      ).withConverter<AdhanRecording>($SettingsTable.$converterfajrRecording);
  @override
  late final GeneratedColumnWithTypeConverter<AdhanRecording, String> dhuhrRecording =
      GeneratedColumn<String>(
        'dhuhr_recording',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('alafasy'),
      ).withConverter<AdhanRecording>($SettingsTable.$converterdhuhrRecording);
  @override
  late final GeneratedColumnWithTypeConverter<AdhanRecording, String> asrRecording =
      GeneratedColumn<String>(
        'asr_recording',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('alafasy'),
      ).withConverter<AdhanRecording>($SettingsTable.$converterasrRecording);
  @override
  late final GeneratedColumnWithTypeConverter<AdhanRecording, String> maghribRecording =
      GeneratedColumn<String>(
        'maghrib_recording',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('alafasy'),
      ).withConverter<AdhanRecording>($SettingsTable.$convertermaghribRecording);
  @override
  late final GeneratedColumnWithTypeConverter<AdhanRecording, String> ishaRecording =
      GeneratedColumn<String>(
        'isha_recording',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('alafasy'),
      ).withConverter<AdhanRecording>($SettingsTable.$converterishaRecording);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerTone, String> fajrTone =
      GeneratedColumn<String>(
        'fajr_tone',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('phone'),
      ).withConverter<PrayerTone>($SettingsTable.$converterfajrTone);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerTone, String> dhuhrTone =
      GeneratedColumn<String>(
        'dhuhr_tone',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('phone'),
      ).withConverter<PrayerTone>($SettingsTable.$converterdhuhrTone);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerTone, String> asrTone = GeneratedColumn<String>(
    'asr_tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('phone'),
  ).withConverter<PrayerTone>($SettingsTable.$converterasrTone);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerTone, String> maghribTone =
      GeneratedColumn<String>(
        'maghrib_tone',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('phone'),
      ).withConverter<PrayerTone>($SettingsTable.$convertermaghribTone);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerTone, String> ishaTone =
      GeneratedColumn<String>(
        'isha_tone',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('phone'),
      ).withConverter<PrayerTone>($SettingsTable.$converterishaTone);
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    false,
    check: () => reminderMinutes.isIn(const [0, 5, 10, 15, 20, 25, 30]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _notificationsAskedMeta = const VerificationMeta(
    'notificationsAsked',
  );
  @override
  late final GeneratedColumn<bool> notificationsAsked = GeneratedColumn<bool>(
    'notifications_asked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_asked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tasbihDhikrMeta = const VerificationMeta('tasbihDhikr');
  @override
  late final GeneratedColumn<int> tasbihDhikr = GeneratedColumn<int>(
    'tasbih_dhikr',
    aliasedName,
    false,
    check: () => ComparableExpr(tasbihDhikr).isBetweenValues(0, 2),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subhanallahCountMeta = const VerificationMeta('subhanallahCount');
  @override
  late final GeneratedColumn<int> subhanallahCount = GeneratedColumn<int>(
    'subhanallah_count',
    aliasedName,
    false,
    check: () => ComparableExpr(subhanallahCount).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alhamdulillahCountMeta = const VerificationMeta(
    'alhamdulillahCount',
  );
  @override
  late final GeneratedColumn<int> alhamdulillahCount = GeneratedColumn<int>(
    'alhamdulillah_count',
    aliasedName,
    false,
    check: () => ComparableExpr(alhamdulillahCount).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allahuAkbarCountMeta = const VerificationMeta('allahuAkbarCount');
  @override
  late final GeneratedColumn<int> allahuAkbarCount = GeneratedColumn<int>(
    'allahu_akbar_count',
    aliasedName,
    false,
    check: () => ComparableExpr(allahuAkbarCount).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> morningOpenedOn =
      GeneratedColumn<String>(
        'morning_opened_on',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SettingsTable.$convertermorningOpenedOnn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> eveningOpenedOn =
      GeneratedColumn<String>(
        'evening_opened_on',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SettingsTable.$convertereveningOpenedOnn);
  static const VerificationMeta _azkarNudgesMeta = const VerificationMeta('azkarNudges');
  @override
  late final GeneratedColumn<bool> azkarNudges = GeneratedColumn<bool>(
    'azkar_nudges',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("azkar_nudges" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _azkarVoiceMeta = const VerificationMeta('azkarVoice');
  @override
  late final GeneratedColumn<bool> azkarVoice = GeneratedColumn<bool>(
    'azkar_voice',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("azkar_voice" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _prayerCountdownMeta = const VerificationMeta('prayerCountdown');
  @override
  late final GeneratedColumn<bool> prayerCountdown = GeneratedColumn<bool>(
    'prayer_countdown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("prayer_countdown" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarMode, String> calendarMode =
      GeneratedColumn<String>(
        'calendar_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('hijri'),
      ).withConverter<CalendarMode>($SettingsTable.$convertercalendarMode);
  static const VerificationMeta _topGlowMeta = const VerificationMeta('topGlow');
  @override
  late final GeneratedColumn<bool> topGlow = GeneratedColumn<bool>(
    'top_glow',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("top_glow" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Language, String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('phone'),
  ).withConverter<Language>($SettingsTable.$converterlanguage);
  @override
  late final GeneratedColumnWithTypeConverter<TextSize, String> textSize = GeneratedColumn<String>(
    'text_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('standard'),
  ).withConverter<TextSize>($SettingsTable.$convertertextSize);
  static const VerificationMeta _onboardedMeta = const VerificationMeta('onboarded');
  @override
  late final GeneratedColumn<bool> onboarded = GeneratedColumn<bool>(
    'onboarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("onboarded" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _crashReportsMeta = const VerificationMeta('crashReports');
  @override
  late final GeneratedColumn<bool> crashReports = GeneratedColumn<bool>(
    'crash_reports',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("crash_reports" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastReadSurahMeta = const VerificationMeta('lastReadSurah');
  @override
  late final GeneratedColumn<int> lastReadSurah = GeneratedColumn<int>(
    'last_read_surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastReadAyahMeta = const VerificationMeta('lastReadAyah');
  @override
  late final GeneratedColumn<int> lastReadAyah = GeneratedColumn<int>(
    'last_read_ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastReadPageMeta = const VerificationMeta('lastReadPage');
  @override
  late final GeneratedColumn<int> lastReadPage = GeneratedColumn<int>(
    'last_read_page',
    aliasedName,
    false,
    check: () => ComparableExpr(lastReadPage).isBetweenValues(1, 604),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta('lastReadAt');
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageColor, String> pageColor =
      GeneratedColumn<String>(
        'page_color',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('followSky'),
      ).withConverter<PageColor>($SettingsTable.$converterpageColor);
  @override
  late final GeneratedColumnWithTypeConverter<QuranLayout, String> quranLayout =
      GeneratedColumn<String>(
        'quran_layout',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('mushaf'),
      ).withConverter<QuranLayout>($SettingsTable.$converterquranLayout);
  @override
  late final GeneratedColumnWithTypeConverter<PageTurn, String> pageTurn = GeneratedColumn<String>(
    'page_turn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('book'),
  ).withConverter<PageTurn>($SettingsTable.$converterpageTurn);
  static const VerificationMeta _keepScreenOnMeta = const VerificationMeta('keepScreenOn');
  @override
  late final GeneratedColumn<bool> keepScreenOn = GeneratedColumn<bool>(
    'keep_screen_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("keep_screen_on" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<QuranFont, String> quranFont =
      GeneratedColumn<String>(
        'quran_font',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('kfgqpc'),
      ).withConverter<QuranFont>($SettingsTable.$converterquranFont);
  @override
  late final GeneratedColumnWithTypeConverter<MushafStyle, String> mushafStyle =
      GeneratedColumn<String>(
        'mushaf_style',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('text'),
      ).withConverter<MushafStyle>($SettingsTable.$convertermushafStyle);
  @override
  late final GeneratedColumnWithTypeConverter<Translation?, String> translation =
      GeneratedColumn<String>(
        'translation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Translation?>($SettingsTable.$convertertranslationn);
  static const VerificationMeta _adhanFlipStopsMeta = const VerificationMeta('adhanFlipStops');
  @override
  late final GeneratedColumn<bool> adhanFlipStops = GeneratedColumn<bool>(
    'adhan_flip_stops',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("adhan_flip_stops" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _adhanButtonsStopMeta = const VerificationMeta('adhanButtonsStop');
  @override
  late final GeneratedColumn<bool> adhanButtonsStop = GeneratedColumn<bool>(
    'adhan_buttons_stop',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("adhan_buttons_stop" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _prayerSilentMeta = const VerificationMeta('prayerSilent');
  @override
  late final GeneratedColumn<bool> prayerSilent = GeneratedColumn<bool>(
    'prayer_silent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("prayer_silent" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _prayerSilentMinutesMeta = const VerificationMeta(
    'prayerSilentMinutes',
  );
  @override
  late final GeneratedColumn<int> prayerSilentMinutes = GeneratedColumn<int>(
    'prayer_silent_minutes',
    aliasedName,
    false,
    check: () => prayerSilentMinutes.isIn(const [10, 15, 20, 30, 45, 60]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _mushafSizeMeta = const VerificationMeta('mushafSize');
  @override
  late final GeneratedColumn<int> mushafSize = GeneratedColumn<int>(
    'mushaf_size',
    aliasedName,
    false,
    check: () => ComparableExpr(mushafSize).isBetweenValues(-2, 5),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quranArabicSizeMeta = const VerificationMeta('quranArabicSize');
  @override
  late final GeneratedColumn<int> quranArabicSize = GeneratedColumn<int>(
    'quran_arabic_size',
    aliasedName,
    false,
    check: () => ComparableExpr(quranArabicSize).isBetweenValues(-2, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quranTranslationSizeMeta = const VerificationMeta(
    'quranTranslationSize',
  );
  @override
  late final GeneratedColumn<int> quranTranslationSize = GeneratedColumn<int>(
    'quran_translation_size',
    aliasedName,
    false,
    check: () => ComparableExpr(quranTranslationSize).isBetweenValues(-2, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reciteSpeedMeta = const VerificationMeta('reciteSpeed');
  @override
  late final GeneratedColumn<double> reciteSpeed = GeneratedColumn<double>(
    'recite_speed',
    aliasedName,
    false,
    check: () => reciteSpeed.isIn(const [0.75, 1.0, 1.25, 1.5]),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _reciteRepeatMeta = const VerificationMeta('reciteRepeat');
  @override
  late final GeneratedColumn<int> reciteRepeat = GeneratedColumn<int>(
    'recite_repeat',
    aliasedName,
    false,
    check: () => reciteRepeat.isIn(const [1, 2, 3, 5, 10, 0]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Reciter, String> reciter = GeneratedColumn<String>(
    'reciter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('alafasy'),
  ).withConverter<Reciter>($SettingsTable.$converterreciter);
  @override
  late final GeneratedColumnWithTypeConverter<AzkarFont, String> azkarFont =
      GeneratedColumn<String>(
        'azkar_font',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('amiri'),
      ).withConverter<AzkarFont>($SettingsTable.$converterazkarFont);
  static const VerificationMeta _recitePauseMeta = const VerificationMeta('recitePause');
  @override
  late final GeneratedColumn<int> recitePause = GeneratedColumn<int>(
    'recite_pause',
    aliasedName,
    false,
    check: () => recitePause.isIn(const [0, 1, 2, 3, 5]),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    latitude,
    longitude,
    placeName,
    placeNameAr,
    regionName,
    regionNameAr,
    countryCode,
    timeZone,
    locationMode,
    method,
    asrMethod,
    hijriAdjust,
    digits,
    theme,
    themeMode,
    reduceMotion,
    haptics,
    uiSounds,
    firstUse,
    fajrSound,
    dhuhrSound,
    asrSound,
    maghribSound,
    ishaSound,
    fajrRecording,
    dhuhrRecording,
    asrRecording,
    maghribRecording,
    ishaRecording,
    fajrTone,
    dhuhrTone,
    asrTone,
    maghribTone,
    ishaTone,
    reminderMinutes,
    notificationsAsked,
    tasbihDhikr,
    subhanallahCount,
    alhamdulillahCount,
    allahuAkbarCount,
    morningOpenedOn,
    eveningOpenedOn,
    azkarNudges,
    azkarVoice,
    prayerCountdown,
    calendarMode,
    topGlow,
    language,
    textSize,
    onboarded,
    crashReports,
    lastReadSurah,
    lastReadAyah,
    lastReadPage,
    lastReadAt,
    pageColor,
    quranLayout,
    pageTurn,
    keepScreenOn,
    quranFont,
    mushafStyle,
    translation,
    adhanFlipStops,
    adhanButtonsStop,
    prayerSilent,
    prayerSilentMinutes,
    mushafSize,
    quranArabicSize,
    quranTranslationSize,
    reciteSpeed,
    reciteRepeat,
    reciter,
    azkarFont,
    recitePause,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettings> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('place_name')) {
      context.handle(
        _placeNameMeta,
        placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta),
      );
    }
    if (data.containsKey('place_name_ar')) {
      context.handle(
        _placeNameArMeta,
        placeNameAr.isAcceptableOrUnknown(data['place_name_ar']!, _placeNameArMeta),
      );
    }
    if (data.containsKey('region_name')) {
      context.handle(
        _regionNameMeta,
        regionName.isAcceptableOrUnknown(data['region_name']!, _regionNameMeta),
      );
    }
    if (data.containsKey('region_name_ar')) {
      context.handle(
        _regionNameArMeta,
        regionNameAr.isAcceptableOrUnknown(data['region_name_ar']!, _regionNameArMeta),
      );
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(data['country_code']!, _countryCodeMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('hijri_adjust')) {
      context.handle(
        _hijriAdjustMeta,
        hijriAdjust.isAcceptableOrUnknown(data['hijri_adjust']!, _hijriAdjustMeta),
      );
    }
    if (data.containsKey('reduce_motion')) {
      context.handle(
        _reduceMotionMeta,
        reduceMotion.isAcceptableOrUnknown(data['reduce_motion']!, _reduceMotionMeta),
      );
    }
    if (data.containsKey('haptics')) {
      context.handle(_hapticsMeta, haptics.isAcceptableOrUnknown(data['haptics']!, _hapticsMeta));
    }
    if (data.containsKey('ui_sounds')) {
      context.handle(
        _uiSoundsMeta,
        uiSounds.isAcceptableOrUnknown(data['ui_sounds']!, _uiSoundsMeta),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta),
      );
    }
    if (data.containsKey('notifications_asked')) {
      context.handle(
        _notificationsAskedMeta,
        notificationsAsked.isAcceptableOrUnknown(
          data['notifications_asked']!,
          _notificationsAskedMeta,
        ),
      );
    }
    if (data.containsKey('tasbih_dhikr')) {
      context.handle(
        _tasbihDhikrMeta,
        tasbihDhikr.isAcceptableOrUnknown(data['tasbih_dhikr']!, _tasbihDhikrMeta),
      );
    }
    if (data.containsKey('subhanallah_count')) {
      context.handle(
        _subhanallahCountMeta,
        subhanallahCount.isAcceptableOrUnknown(data['subhanallah_count']!, _subhanallahCountMeta),
      );
    }
    if (data.containsKey('alhamdulillah_count')) {
      context.handle(
        _alhamdulillahCountMeta,
        alhamdulillahCount.isAcceptableOrUnknown(
          data['alhamdulillah_count']!,
          _alhamdulillahCountMeta,
        ),
      );
    }
    if (data.containsKey('allahu_akbar_count')) {
      context.handle(
        _allahuAkbarCountMeta,
        allahuAkbarCount.isAcceptableOrUnknown(data['allahu_akbar_count']!, _allahuAkbarCountMeta),
      );
    }
    if (data.containsKey('azkar_nudges')) {
      context.handle(
        _azkarNudgesMeta,
        azkarNudges.isAcceptableOrUnknown(data['azkar_nudges']!, _azkarNudgesMeta),
      );
    }
    if (data.containsKey('azkar_voice')) {
      context.handle(
        _azkarVoiceMeta,
        azkarVoice.isAcceptableOrUnknown(data['azkar_voice']!, _azkarVoiceMeta),
      );
    }
    if (data.containsKey('prayer_countdown')) {
      context.handle(
        _prayerCountdownMeta,
        prayerCountdown.isAcceptableOrUnknown(data['prayer_countdown']!, _prayerCountdownMeta),
      );
    }
    if (data.containsKey('top_glow')) {
      context.handle(_topGlowMeta, topGlow.isAcceptableOrUnknown(data['top_glow']!, _topGlowMeta));
    }
    if (data.containsKey('onboarded')) {
      context.handle(
        _onboardedMeta,
        onboarded.isAcceptableOrUnknown(data['onboarded']!, _onboardedMeta),
      );
    }
    if (data.containsKey('crash_reports')) {
      context.handle(
        _crashReportsMeta,
        crashReports.isAcceptableOrUnknown(data['crash_reports']!, _crashReportsMeta),
      );
    }
    if (data.containsKey('last_read_surah')) {
      context.handle(
        _lastReadSurahMeta,
        lastReadSurah.isAcceptableOrUnknown(data['last_read_surah']!, _lastReadSurahMeta),
      );
    }
    if (data.containsKey('last_read_ayah')) {
      context.handle(
        _lastReadAyahMeta,
        lastReadAyah.isAcceptableOrUnknown(data['last_read_ayah']!, _lastReadAyahMeta),
      );
    }
    if (data.containsKey('last_read_page')) {
      context.handle(
        _lastReadPageMeta,
        lastReadPage.isAcceptableOrUnknown(data['last_read_page']!, _lastReadPageMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(data['last_read_at']!, _lastReadAtMeta),
      );
    }
    if (data.containsKey('keep_screen_on')) {
      context.handle(
        _keepScreenOnMeta,
        keepScreenOn.isAcceptableOrUnknown(data['keep_screen_on']!, _keepScreenOnMeta),
      );
    }
    if (data.containsKey('adhan_flip_stops')) {
      context.handle(
        _adhanFlipStopsMeta,
        adhanFlipStops.isAcceptableOrUnknown(data['adhan_flip_stops']!, _adhanFlipStopsMeta),
      );
    }
    if (data.containsKey('adhan_buttons_stop')) {
      context.handle(
        _adhanButtonsStopMeta,
        adhanButtonsStop.isAcceptableOrUnknown(data['adhan_buttons_stop']!, _adhanButtonsStopMeta),
      );
    }
    if (data.containsKey('prayer_silent')) {
      context.handle(
        _prayerSilentMeta,
        prayerSilent.isAcceptableOrUnknown(data['prayer_silent']!, _prayerSilentMeta),
      );
    }
    if (data.containsKey('prayer_silent_minutes')) {
      context.handle(
        _prayerSilentMinutesMeta,
        prayerSilentMinutes.isAcceptableOrUnknown(
          data['prayer_silent_minutes']!,
          _prayerSilentMinutesMeta,
        ),
      );
    }
    if (data.containsKey('mushaf_size')) {
      context.handle(
        _mushafSizeMeta,
        mushafSize.isAcceptableOrUnknown(data['mushaf_size']!, _mushafSizeMeta),
      );
    }
    if (data.containsKey('quran_arabic_size')) {
      context.handle(
        _quranArabicSizeMeta,
        quranArabicSize.isAcceptableOrUnknown(data['quran_arabic_size']!, _quranArabicSizeMeta),
      );
    }
    if (data.containsKey('quran_translation_size')) {
      context.handle(
        _quranTranslationSizeMeta,
        quranTranslationSize.isAcceptableOrUnknown(
          data['quran_translation_size']!,
          _quranTranslationSizeMeta,
        ),
      );
    }
    if (data.containsKey('recite_speed')) {
      context.handle(
        _reciteSpeedMeta,
        reciteSpeed.isAcceptableOrUnknown(data['recite_speed']!, _reciteSpeedMeta),
      );
    }
    if (data.containsKey('recite_repeat')) {
      context.handle(
        _reciteRepeatMeta,
        reciteRepeat.isAcceptableOrUnknown(data['recite_repeat']!, _reciteRepeatMeta),
      );
    }
    if (data.containsKey('recite_pause')) {
      context.handle(
        _recitePauseMeta,
        recitePause.isAcceptableOrUnknown(data['recite_pause']!, _recitePauseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettings map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettings(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      placeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name'],
      ),
      placeNameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name_ar'],
      ),
      regionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_name'],
      ),
      regionNameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_name_ar'],
      ),
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      locationMode: $SettingsTable.$converterlocationModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}location_mode'],
        ),
      ),
      method: $SettingsTable.$convertermethodn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}method']),
      ),
      asrMethod: $SettingsTable.$converterasrMethodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}asr_method'],
        ),
      ),
      hijriAdjust: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hijri_adjust'],
      )!,
      digits: $SettingsTable.$converterdigits.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}digits'])!,
      ),
      theme: $SettingsTable.$convertertheme.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}theme'])!,
      ),
      themeMode: $SettingsTable.$converterthemeMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_mode'],
        )!,
      ),
      reduceMotion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reduce_motion'],
      )!,
      haptics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}haptics'],
      )!,
      uiSounds: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ui_sounds'],
      )!,
      firstUse: $SettingsTable.$converterfirstUsen.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}first_use']),
      ),
      fajrSound: $SettingsTable.$converterfajrSound.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fajr_sound'],
        )!,
      ),
      dhuhrSound: $SettingsTable.$converterdhuhrSound.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dhuhr_sound'],
        )!,
      ),
      asrSound: $SettingsTable.$converterasrSound.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}asr_sound'],
        )!,
      ),
      maghribSound: $SettingsTable.$convertermaghribSound.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}maghrib_sound'],
        )!,
      ),
      ishaSound: $SettingsTable.$converterishaSound.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}isha_sound'],
        )!,
      ),
      fajrRecording: $SettingsTable.$converterfajrRecording.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fajr_recording'],
        )!,
      ),
      dhuhrRecording: $SettingsTable.$converterdhuhrRecording.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dhuhr_recording'],
        )!,
      ),
      asrRecording: $SettingsTable.$converterasrRecording.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}asr_recording'],
        )!,
      ),
      maghribRecording: $SettingsTable.$convertermaghribRecording.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}maghrib_recording'],
        )!,
      ),
      ishaRecording: $SettingsTable.$converterishaRecording.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}isha_recording'],
        )!,
      ),
      fajrTone: $SettingsTable.$converterfajrTone.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fajr_tone'],
        )!,
      ),
      dhuhrTone: $SettingsTable.$converterdhuhrTone.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dhuhr_tone'],
        )!,
      ),
      asrTone: $SettingsTable.$converterasrTone.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}asr_tone'])!,
      ),
      maghribTone: $SettingsTable.$convertermaghribTone.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}maghrib_tone'],
        )!,
      ),
      ishaTone: $SettingsTable.$converterishaTone.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}isha_tone'],
        )!,
      ),
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      )!,
      notificationsAsked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_asked'],
      )!,
      tasbihDhikr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasbih_dhikr'],
      )!,
      subhanallahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subhanallah_count'],
      )!,
      alhamdulillahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alhamdulillah_count'],
      )!,
      allahuAkbarCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allahu_akbar_count'],
      )!,
      morningOpenedOn: $SettingsTable.$convertermorningOpenedOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}morning_opened_on'],
        ),
      ),
      eveningOpenedOn: $SettingsTable.$convertereveningOpenedOnn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}evening_opened_on'],
        ),
      ),
      azkarNudges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}azkar_nudges'],
      )!,
      azkarVoice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}azkar_voice'],
      )!,
      prayerCountdown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prayer_countdown'],
      )!,
      calendarMode: $SettingsTable.$convertercalendarMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}calendar_mode'],
        )!,
      ),
      topGlow: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}top_glow'],
      )!,
      language: $SettingsTable.$converterlanguage.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      ),
      textSize: $SettingsTable.$convertertextSize.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}text_size'],
        )!,
      ),
      onboarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarded'],
      )!,
      crashReports: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}crash_reports'],
      )!,
      lastReadSurah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_surah'],
      )!,
      lastReadAyah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_ayah'],
      )!,
      lastReadPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_page'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      ),
      pageColor: $SettingsTable.$converterpageColor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}page_color'],
        )!,
      ),
      quranLayout: $SettingsTable.$converterquranLayout.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quran_layout'],
        )!,
      ),
      pageTurn: $SettingsTable.$converterpageTurn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}page_turn'],
        )!,
      ),
      keepScreenOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_screen_on'],
      )!,
      quranFont: $SettingsTable.$converterquranFont.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quran_font'],
        )!,
      ),
      mushafStyle: $SettingsTable.$convertermushafStyle.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mushaf_style'],
        )!,
      ),
      translation: $SettingsTable.$convertertranslationn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}translation'],
        ),
      ),
      adhanFlipStops: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}adhan_flip_stops'],
      )!,
      adhanButtonsStop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}adhan_buttons_stop'],
      )!,
      prayerSilent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prayer_silent'],
      )!,
      prayerSilentMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prayer_silent_minutes'],
      )!,
      mushafSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mushaf_size'],
      )!,
      quranArabicSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quran_arabic_size'],
      )!,
      quranTranslationSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quran_translation_size'],
      )!,
      reciteSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recite_speed'],
      )!,
      reciteRepeat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recite_repeat'],
      )!,
      reciter: $SettingsTable.$converterreciter.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reciter'])!,
      ),
      azkarFont: $SettingsTable.$converterazkarFont.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}azkar_font'],
        )!,
      ),
      recitePause: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recite_pause'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocationMode, String, String> $converterlocationMode =
      const EnumNameConverter<LocationMode>(LocationMode.values);
  static JsonTypeConverter2<LocationMode?, String?, String?> $converterlocationModen =
      JsonTypeConverter2.asNullable($converterlocationMode);
  static JsonTypeConverter2<PrayerMethod, String, String> $convertermethod =
      const EnumNameConverter<PrayerMethod>(PrayerMethod.values);
  static JsonTypeConverter2<PrayerMethod?, String?, String?> $convertermethodn =
      JsonTypeConverter2.asNullable($convertermethod);
  static JsonTypeConverter2<AsrMethod, String, String> $converterasrMethod =
      const EnumNameConverter<AsrMethod>(AsrMethod.values);
  static JsonTypeConverter2<AsrMethod?, String?, String?> $converterasrMethodn =
      JsonTypeConverter2.asNullable($converterasrMethod);
  static JsonTypeConverter2<Digits, String, String> $converterdigits =
      const EnumNameConverter<Digits>(Digits.values);
  static JsonTypeConverter2<BmThemeId, String, String> $convertertheme =
      const EnumNameConverter<BmThemeId>(BmThemeId.values);
  static JsonTypeConverter2<BmThemeMode, String, String> $converterthemeMode =
      const EnumNameConverter<BmThemeMode>(BmThemeMode.values);
  static TypeConverter<DateTime, String> $converterfirstUse = const CivilDate();
  static TypeConverter<DateTime?, String?> $converterfirstUsen = NullAwareTypeConverter.wrap(
    $converterfirstUse,
  );
  static JsonTypeConverter2<PrayerSound, String, String> $converterfajrSound =
      const EnumNameConverter<PrayerSound>(PrayerSound.values);
  static JsonTypeConverter2<PrayerSound, String, String> $converterdhuhrSound =
      const EnumNameConverter<PrayerSound>(PrayerSound.values);
  static JsonTypeConverter2<PrayerSound, String, String> $converterasrSound =
      const EnumNameConverter<PrayerSound>(PrayerSound.values);
  static JsonTypeConverter2<PrayerSound, String, String> $convertermaghribSound =
      const EnumNameConverter<PrayerSound>(PrayerSound.values);
  static JsonTypeConverter2<PrayerSound, String, String> $converterishaSound =
      const EnumNameConverter<PrayerSound>(PrayerSound.values);
  static JsonTypeConverter2<AdhanRecording, String, String> $converterfajrRecording =
      const EnumNameConverter<AdhanRecording>(AdhanRecording.values);
  static JsonTypeConverter2<AdhanRecording, String, String> $converterdhuhrRecording =
      const EnumNameConverter<AdhanRecording>(AdhanRecording.values);
  static JsonTypeConverter2<AdhanRecording, String, String> $converterasrRecording =
      const EnumNameConverter<AdhanRecording>(AdhanRecording.values);
  static JsonTypeConverter2<AdhanRecording, String, String> $convertermaghribRecording =
      const EnumNameConverter<AdhanRecording>(AdhanRecording.values);
  static JsonTypeConverter2<AdhanRecording, String, String> $converterishaRecording =
      const EnumNameConverter<AdhanRecording>(AdhanRecording.values);
  static JsonTypeConverter2<PrayerTone, String, String> $converterfajrTone =
      const EnumNameConverter<PrayerTone>(PrayerTone.values);
  static JsonTypeConverter2<PrayerTone, String, String> $converterdhuhrTone =
      const EnumNameConverter<PrayerTone>(PrayerTone.values);
  static JsonTypeConverter2<PrayerTone, String, String> $converterasrTone =
      const EnumNameConverter<PrayerTone>(PrayerTone.values);
  static JsonTypeConverter2<PrayerTone, String, String> $convertermaghribTone =
      const EnumNameConverter<PrayerTone>(PrayerTone.values);
  static JsonTypeConverter2<PrayerTone, String, String> $converterishaTone =
      const EnumNameConverter<PrayerTone>(PrayerTone.values);
  static TypeConverter<DateTime, String> $convertermorningOpenedOn = const CivilDate();
  static TypeConverter<DateTime?, String?> $convertermorningOpenedOnn = NullAwareTypeConverter.wrap(
    $convertermorningOpenedOn,
  );
  static TypeConverter<DateTime, String> $convertereveningOpenedOn = const CivilDate();
  static TypeConverter<DateTime?, String?> $convertereveningOpenedOnn = NullAwareTypeConverter.wrap(
    $convertereveningOpenedOn,
  );
  static JsonTypeConverter2<CalendarMode, String, String> $convertercalendarMode =
      const EnumNameConverter<CalendarMode>(CalendarMode.values);
  static JsonTypeConverter2<Language, String, String> $converterlanguage =
      const EnumNameConverter<Language>(Language.values);
  static JsonTypeConverter2<TextSize, String, String> $convertertextSize =
      const EnumNameConverter<TextSize>(TextSize.values);
  static JsonTypeConverter2<PageColor, String, String> $converterpageColor =
      const EnumNameConverter<PageColor>(PageColor.values);
  static JsonTypeConverter2<QuranLayout, String, String> $converterquranLayout =
      const EnumNameConverter<QuranLayout>(QuranLayout.values);
  static JsonTypeConverter2<PageTurn, String, String> $converterpageTurn =
      const EnumNameConverter<PageTurn>(PageTurn.values);
  static JsonTypeConverter2<QuranFont, String, String> $converterquranFont =
      const EnumNameConverter<QuranFont>(QuranFont.values);
  static JsonTypeConverter2<MushafStyle, String, String> $convertermushafStyle =
      const EnumNameConverter<MushafStyle>(MushafStyle.values);
  static JsonTypeConverter2<Translation, String, String> $convertertranslation =
      const EnumNameConverter<Translation>(Translation.values);
  static JsonTypeConverter2<Translation?, String?, String?> $convertertranslationn =
      JsonTypeConverter2.asNullable($convertertranslation);
  static JsonTypeConverter2<Reciter, String, String> $converterreciter =
      const EnumNameConverter<Reciter>(Reciter.values);
  static JsonTypeConverter2<AzkarFont, String, String> $converterazkarFont =
      const EnumNameConverter<AzkarFont>(AzkarFont.values);
}

class AppSettings extends DataClass implements Insertable<AppSettings> {
  final int id;

  /// null = no location yet
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? placeNameAr;
  final String? regionName;
  final String? regionNameAr;
  final String? countryCode;

  /// the place's zone, used in manual mode
  final String? timeZone;
  final LocationMode? locationMode;

  /// null = by country, a value = picked by the user and kept when the location changes
  final PrayerMethod? method;
  final AsrMethod? asrMethod;
  final int hijriAdjust;

  /// literal names, so drift exports the schema without running flutter code (the theme enums)
  final Digits digits;
  final BmThemeId theme;
  final BmThemeMode themeMode;
  final bool reduceMotion;
  final bool haptics;
  final bool uiSounds;

  /// the strip's earliest week. the v2 migration fills it with the upgrade date
  final DateTime? firstUse;
  final PrayerSound fajrSound;
  final PrayerSound dhuhrSound;
  final PrayerSound asrSound;
  final PrayerSound maghribSound;
  final PrayerSound ishaSound;

  /// each prayer's own recording, android fixes a channel's sound so it can't be one for all
  final AdhanRecording fajrRecording;
  final AdhanRecording dhuhrRecording;
  final AdhanRecording asrRecording;
  final AdhanRecording maghribRecording;
  final AdhanRecording ishaRecording;

  /// each prayer's own tone, android fixes a channel's sound like the recordings
  final PrayerTone fajrTone;
  final PrayerTone dhuhrTone;
  final PrayerTone asrTone;
  final PrayerTone maghribTone;
  final PrayerTone ishaTone;

  /// minutes before each prayer, 0 is off
  final int reminderMinutes;

  /// true once 4.12 or the off line asked the phone, after that the off line opens settings
  final bool notificationsAsked;

  /// 0 subhanallah, 1 alhamdulillah, 2 allahu akbar
  final int tasbihDhikr;
  final int subhanallahCount;
  final int alhamdulillahCount;
  final int allahuAkbarCount;

  /// the window last opened, the azkar tab's badge goes once it's the current one
  final DateTime? morningOpenedOn;
  final DateTime? eveningOpenedOn;
  final bool azkarNudges;
  final bool azkarVoice;

  /// Countdown before each prayer
  final bool prayerCountdown;
  final CalendarMode calendarMode;
  final bool topGlow;
  final Language language;
  final TextSize textSize;
  final bool onboarded;

  /// YOUR DATA's switch, off and sentry never starts, in the app or in the background
  final bool crashReports;
  final int lastReadSurah;
  final int lastReadAyah;
  final int lastReadPage;

  /// null = never read, the card shows no time
  final DateTime? lastReadAt;
  final PageColor pageColor;
  final QuranLayout quranLayout;
  final PageTurn pageTurn;
  final bool keepScreenOn;
  final QuranFont quranFont;
  final MushafStyle mushafStyle;

  /// null until picked, then Translation.of gives the app language's own
  final Translation? translation;

  /// android only, the full adhan is kotlin's and ios can't touch a posted sound
  final bool adhanFlipStops;
  final bool adhanButtonsStop;

  /// do not disturb after each prayer's sound, for this many minutes from its time
  final bool prayerSilent;
  final int prayerSilentMinutes;

  /// 10% steps around the printed page, above 0 the lines rewrap
  final int mushafSize;

  /// steps around 4.07's size
  final int quranArabicSize;
  final int quranTranslationSize;
  final double reciteSpeed;

  /// 1 is off, 0 is surah loop
  final int reciteRepeat;
  final Reciter reciter;
  final AzkarFont azkarFont;

  /// seconds between ayahs
  final int recitePause;
  const AppSettings({
    required this.id,
    this.latitude,
    this.longitude,
    this.placeName,
    this.placeNameAr,
    this.regionName,
    this.regionNameAr,
    this.countryCode,
    this.timeZone,
    this.locationMode,
    this.method,
    this.asrMethod,
    required this.hijriAdjust,
    required this.digits,
    required this.theme,
    required this.themeMode,
    required this.reduceMotion,
    required this.haptics,
    required this.uiSounds,
    this.firstUse,
    required this.fajrSound,
    required this.dhuhrSound,
    required this.asrSound,
    required this.maghribSound,
    required this.ishaSound,
    required this.fajrRecording,
    required this.dhuhrRecording,
    required this.asrRecording,
    required this.maghribRecording,
    required this.ishaRecording,
    required this.fajrTone,
    required this.dhuhrTone,
    required this.asrTone,
    required this.maghribTone,
    required this.ishaTone,
    required this.reminderMinutes,
    required this.notificationsAsked,
    required this.tasbihDhikr,
    required this.subhanallahCount,
    required this.alhamdulillahCount,
    required this.allahuAkbarCount,
    this.morningOpenedOn,
    this.eveningOpenedOn,
    required this.azkarNudges,
    required this.azkarVoice,
    required this.prayerCountdown,
    required this.calendarMode,
    required this.topGlow,
    required this.language,
    required this.textSize,
    required this.onboarded,
    required this.crashReports,
    required this.lastReadSurah,
    required this.lastReadAyah,
    required this.lastReadPage,
    this.lastReadAt,
    required this.pageColor,
    required this.quranLayout,
    required this.pageTurn,
    required this.keepScreenOn,
    required this.quranFont,
    required this.mushafStyle,
    this.translation,
    required this.adhanFlipStops,
    required this.adhanButtonsStop,
    required this.prayerSilent,
    required this.prayerSilentMinutes,
    required this.mushafSize,
    required this.quranArabicSize,
    required this.quranTranslationSize,
    required this.reciteSpeed,
    required this.reciteRepeat,
    required this.reciter,
    required this.azkarFont,
    required this.recitePause,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || placeName != null) {
      map['place_name'] = Variable<String>(placeName);
    }
    if (!nullToAbsent || placeNameAr != null) {
      map['place_name_ar'] = Variable<String>(placeNameAr);
    }
    if (!nullToAbsent || regionName != null) {
      map['region_name'] = Variable<String>(regionName);
    }
    if (!nullToAbsent || regionNameAr != null) {
      map['region_name_ar'] = Variable<String>(regionNameAr);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    if (!nullToAbsent || locationMode != null) {
      map['location_mode'] = Variable<String>(
        $SettingsTable.$converterlocationModen.toSql(locationMode),
      );
    }
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>($SettingsTable.$convertermethodn.toSql(method));
    }
    if (!nullToAbsent || asrMethod != null) {
      map['asr_method'] = Variable<String>($SettingsTable.$converterasrMethodn.toSql(asrMethod));
    }
    map['hijri_adjust'] = Variable<int>(hijriAdjust);
    {
      map['digits'] = Variable<String>($SettingsTable.$converterdigits.toSql(digits));
    }
    {
      map['theme'] = Variable<String>($SettingsTable.$convertertheme.toSql(theme));
    }
    {
      map['theme_mode'] = Variable<String>($SettingsTable.$converterthemeMode.toSql(themeMode));
    }
    map['reduce_motion'] = Variable<bool>(reduceMotion);
    map['haptics'] = Variable<bool>(haptics);
    map['ui_sounds'] = Variable<bool>(uiSounds);
    if (!nullToAbsent || firstUse != null) {
      map['first_use'] = Variable<String>($SettingsTable.$converterfirstUsen.toSql(firstUse));
    }
    {
      map['fajr_sound'] = Variable<String>($SettingsTable.$converterfajrSound.toSql(fajrSound));
    }
    {
      map['dhuhr_sound'] = Variable<String>($SettingsTable.$converterdhuhrSound.toSql(dhuhrSound));
    }
    {
      map['asr_sound'] = Variable<String>($SettingsTable.$converterasrSound.toSql(asrSound));
    }
    {
      map['maghrib_sound'] = Variable<String>(
        $SettingsTable.$convertermaghribSound.toSql(maghribSound),
      );
    }
    {
      map['isha_sound'] = Variable<String>($SettingsTable.$converterishaSound.toSql(ishaSound));
    }
    {
      map['fajr_recording'] = Variable<String>(
        $SettingsTable.$converterfajrRecording.toSql(fajrRecording),
      );
    }
    {
      map['dhuhr_recording'] = Variable<String>(
        $SettingsTable.$converterdhuhrRecording.toSql(dhuhrRecording),
      );
    }
    {
      map['asr_recording'] = Variable<String>(
        $SettingsTable.$converterasrRecording.toSql(asrRecording),
      );
    }
    {
      map['maghrib_recording'] = Variable<String>(
        $SettingsTable.$convertermaghribRecording.toSql(maghribRecording),
      );
    }
    {
      map['isha_recording'] = Variable<String>(
        $SettingsTable.$converterishaRecording.toSql(ishaRecording),
      );
    }
    {
      map['fajr_tone'] = Variable<String>($SettingsTable.$converterfajrTone.toSql(fajrTone));
    }
    {
      map['dhuhr_tone'] = Variable<String>($SettingsTable.$converterdhuhrTone.toSql(dhuhrTone));
    }
    {
      map['asr_tone'] = Variable<String>($SettingsTable.$converterasrTone.toSql(asrTone));
    }
    {
      map['maghrib_tone'] = Variable<String>(
        $SettingsTable.$convertermaghribTone.toSql(maghribTone),
      );
    }
    {
      map['isha_tone'] = Variable<String>($SettingsTable.$converterishaTone.toSql(ishaTone));
    }
    map['reminder_minutes'] = Variable<int>(reminderMinutes);
    map['notifications_asked'] = Variable<bool>(notificationsAsked);
    map['tasbih_dhikr'] = Variable<int>(tasbihDhikr);
    map['subhanallah_count'] = Variable<int>(subhanallahCount);
    map['alhamdulillah_count'] = Variable<int>(alhamdulillahCount);
    map['allahu_akbar_count'] = Variable<int>(allahuAkbarCount);
    if (!nullToAbsent || morningOpenedOn != null) {
      map['morning_opened_on'] = Variable<String>(
        $SettingsTable.$convertermorningOpenedOnn.toSql(morningOpenedOn),
      );
    }
    if (!nullToAbsent || eveningOpenedOn != null) {
      map['evening_opened_on'] = Variable<String>(
        $SettingsTable.$convertereveningOpenedOnn.toSql(eveningOpenedOn),
      );
    }
    map['azkar_nudges'] = Variable<bool>(azkarNudges);
    map['azkar_voice'] = Variable<bool>(azkarVoice);
    map['prayer_countdown'] = Variable<bool>(prayerCountdown);
    {
      map['calendar_mode'] = Variable<String>(
        $SettingsTable.$convertercalendarMode.toSql(calendarMode),
      );
    }
    map['top_glow'] = Variable<bool>(topGlow);
    {
      map['language'] = Variable<String>($SettingsTable.$converterlanguage.toSql(language));
    }
    {
      map['text_size'] = Variable<String>($SettingsTable.$convertertextSize.toSql(textSize));
    }
    map['onboarded'] = Variable<bool>(onboarded);
    map['crash_reports'] = Variable<bool>(crashReports);
    map['last_read_surah'] = Variable<int>(lastReadSurah);
    map['last_read_ayah'] = Variable<int>(lastReadAyah);
    map['last_read_page'] = Variable<int>(lastReadPage);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt);
    }
    {
      map['page_color'] = Variable<String>($SettingsTable.$converterpageColor.toSql(pageColor));
    }
    {
      map['quran_layout'] = Variable<String>(
        $SettingsTable.$converterquranLayout.toSql(quranLayout),
      );
    }
    {
      map['page_turn'] = Variable<String>($SettingsTable.$converterpageTurn.toSql(pageTurn));
    }
    map['keep_screen_on'] = Variable<bool>(keepScreenOn);
    {
      map['quran_font'] = Variable<String>($SettingsTable.$converterquranFont.toSql(quranFont));
    }
    {
      map['mushaf_style'] = Variable<String>(
        $SettingsTable.$convertermushafStyle.toSql(mushafStyle),
      );
    }
    if (!nullToAbsent || translation != null) {
      map['translation'] = Variable<String>(
        $SettingsTable.$convertertranslationn.toSql(translation),
      );
    }
    map['adhan_flip_stops'] = Variable<bool>(adhanFlipStops);
    map['adhan_buttons_stop'] = Variable<bool>(adhanButtonsStop);
    map['prayer_silent'] = Variable<bool>(prayerSilent);
    map['prayer_silent_minutes'] = Variable<int>(prayerSilentMinutes);
    map['mushaf_size'] = Variable<int>(mushafSize);
    map['quran_arabic_size'] = Variable<int>(quranArabicSize);
    map['quran_translation_size'] = Variable<int>(quranTranslationSize);
    map['recite_speed'] = Variable<double>(reciteSpeed);
    map['recite_repeat'] = Variable<int>(reciteRepeat);
    {
      map['reciter'] = Variable<String>($SettingsTable.$converterreciter.toSql(reciter));
    }
    {
      map['azkar_font'] = Variable<String>($SettingsTable.$converterazkarFont.toSql(azkarFont));
    }
    map['recite_pause'] = Variable<int>(recitePause);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      latitude: latitude == null && nullToAbsent ? const Value.absent() : Value(latitude),
      longitude: longitude == null && nullToAbsent ? const Value.absent() : Value(longitude),
      placeName: placeName == null && nullToAbsent ? const Value.absent() : Value(placeName),
      placeNameAr: placeNameAr == null && nullToAbsent ? const Value.absent() : Value(placeNameAr),
      regionName: regionName == null && nullToAbsent ? const Value.absent() : Value(regionName),
      regionNameAr: regionNameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(regionNameAr),
      countryCode: countryCode == null && nullToAbsent ? const Value.absent() : Value(countryCode),
      timeZone: timeZone == null && nullToAbsent ? const Value.absent() : Value(timeZone),
      locationMode: locationMode == null && nullToAbsent
          ? const Value.absent()
          : Value(locationMode),
      method: method == null && nullToAbsent ? const Value.absent() : Value(method),
      asrMethod: asrMethod == null && nullToAbsent ? const Value.absent() : Value(asrMethod),
      hijriAdjust: Value(hijriAdjust),
      digits: Value(digits),
      theme: Value(theme),
      themeMode: Value(themeMode),
      reduceMotion: Value(reduceMotion),
      haptics: Value(haptics),
      uiSounds: Value(uiSounds),
      firstUse: firstUse == null && nullToAbsent ? const Value.absent() : Value(firstUse),
      fajrSound: Value(fajrSound),
      dhuhrSound: Value(dhuhrSound),
      asrSound: Value(asrSound),
      maghribSound: Value(maghribSound),
      ishaSound: Value(ishaSound),
      fajrRecording: Value(fajrRecording),
      dhuhrRecording: Value(dhuhrRecording),
      asrRecording: Value(asrRecording),
      maghribRecording: Value(maghribRecording),
      ishaRecording: Value(ishaRecording),
      fajrTone: Value(fajrTone),
      dhuhrTone: Value(dhuhrTone),
      asrTone: Value(asrTone),
      maghribTone: Value(maghribTone),
      ishaTone: Value(ishaTone),
      reminderMinutes: Value(reminderMinutes),
      notificationsAsked: Value(notificationsAsked),
      tasbihDhikr: Value(tasbihDhikr),
      subhanallahCount: Value(subhanallahCount),
      alhamdulillahCount: Value(alhamdulillahCount),
      allahuAkbarCount: Value(allahuAkbarCount),
      morningOpenedOn: morningOpenedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(morningOpenedOn),
      eveningOpenedOn: eveningOpenedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(eveningOpenedOn),
      azkarNudges: Value(azkarNudges),
      azkarVoice: Value(azkarVoice),
      prayerCountdown: Value(prayerCountdown),
      calendarMode: Value(calendarMode),
      topGlow: Value(topGlow),
      language: Value(language),
      textSize: Value(textSize),
      onboarded: Value(onboarded),
      crashReports: Value(crashReports),
      lastReadSurah: Value(lastReadSurah),
      lastReadAyah: Value(lastReadAyah),
      lastReadPage: Value(lastReadPage),
      lastReadAt: lastReadAt == null && nullToAbsent ? const Value.absent() : Value(lastReadAt),
      pageColor: Value(pageColor),
      quranLayout: Value(quranLayout),
      pageTurn: Value(pageTurn),
      keepScreenOn: Value(keepScreenOn),
      quranFont: Value(quranFont),
      mushafStyle: Value(mushafStyle),
      translation: translation == null && nullToAbsent ? const Value.absent() : Value(translation),
      adhanFlipStops: Value(adhanFlipStops),
      adhanButtonsStop: Value(adhanButtonsStop),
      prayerSilent: Value(prayerSilent),
      prayerSilentMinutes: Value(prayerSilentMinutes),
      mushafSize: Value(mushafSize),
      quranArabicSize: Value(quranArabicSize),
      quranTranslationSize: Value(quranTranslationSize),
      reciteSpeed: Value(reciteSpeed),
      reciteRepeat: Value(reciteRepeat),
      reciter: Value(reciter),
      azkarFont: Value(azkarFont),
      recitePause: Value(recitePause),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettings(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      placeName: serializer.fromJson<String?>(json['placeName']),
      placeNameAr: serializer.fromJson<String?>(json['placeNameAr']),
      regionName: serializer.fromJson<String?>(json['regionName']),
      regionNameAr: serializer.fromJson<String?>(json['regionNameAr']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      locationMode: $SettingsTable.$converterlocationModen.fromJson(
        serializer.fromJson<String?>(json['locationMode']),
      ),
      method: $SettingsTable.$convertermethodn.fromJson(
        serializer.fromJson<String?>(json['method']),
      ),
      asrMethod: $SettingsTable.$converterasrMethodn.fromJson(
        serializer.fromJson<String?>(json['asrMethod']),
      ),
      hijriAdjust: serializer.fromJson<int>(json['hijriAdjust']),
      digits: $SettingsTable.$converterdigits.fromJson(serializer.fromJson<String>(json['digits'])),
      theme: $SettingsTable.$convertertheme.fromJson(serializer.fromJson<String>(json['theme'])),
      themeMode: $SettingsTable.$converterthemeMode.fromJson(
        serializer.fromJson<String>(json['themeMode']),
      ),
      reduceMotion: serializer.fromJson<bool>(json['reduceMotion']),
      haptics: serializer.fromJson<bool>(json['haptics']),
      uiSounds: serializer.fromJson<bool>(json['uiSounds']),
      firstUse: serializer.fromJson<DateTime?>(json['firstUse']),
      fajrSound: $SettingsTable.$converterfajrSound.fromJson(
        serializer.fromJson<String>(json['fajrSound']),
      ),
      dhuhrSound: $SettingsTable.$converterdhuhrSound.fromJson(
        serializer.fromJson<String>(json['dhuhrSound']),
      ),
      asrSound: $SettingsTable.$converterasrSound.fromJson(
        serializer.fromJson<String>(json['asrSound']),
      ),
      maghribSound: $SettingsTable.$convertermaghribSound.fromJson(
        serializer.fromJson<String>(json['maghribSound']),
      ),
      ishaSound: $SettingsTable.$converterishaSound.fromJson(
        serializer.fromJson<String>(json['ishaSound']),
      ),
      fajrRecording: $SettingsTable.$converterfajrRecording.fromJson(
        serializer.fromJson<String>(json['fajrRecording']),
      ),
      dhuhrRecording: $SettingsTable.$converterdhuhrRecording.fromJson(
        serializer.fromJson<String>(json['dhuhrRecording']),
      ),
      asrRecording: $SettingsTable.$converterasrRecording.fromJson(
        serializer.fromJson<String>(json['asrRecording']),
      ),
      maghribRecording: $SettingsTable.$convertermaghribRecording.fromJson(
        serializer.fromJson<String>(json['maghribRecording']),
      ),
      ishaRecording: $SettingsTable.$converterishaRecording.fromJson(
        serializer.fromJson<String>(json['ishaRecording']),
      ),
      fajrTone: $SettingsTable.$converterfajrTone.fromJson(
        serializer.fromJson<String>(json['fajrTone']),
      ),
      dhuhrTone: $SettingsTable.$converterdhuhrTone.fromJson(
        serializer.fromJson<String>(json['dhuhrTone']),
      ),
      asrTone: $SettingsTable.$converterasrTone.fromJson(
        serializer.fromJson<String>(json['asrTone']),
      ),
      maghribTone: $SettingsTable.$convertermaghribTone.fromJson(
        serializer.fromJson<String>(json['maghribTone']),
      ),
      ishaTone: $SettingsTable.$converterishaTone.fromJson(
        serializer.fromJson<String>(json['ishaTone']),
      ),
      reminderMinutes: serializer.fromJson<int>(json['reminderMinutes']),
      notificationsAsked: serializer.fromJson<bool>(json['notificationsAsked']),
      tasbihDhikr: serializer.fromJson<int>(json['tasbihDhikr']),
      subhanallahCount: serializer.fromJson<int>(json['subhanallahCount']),
      alhamdulillahCount: serializer.fromJson<int>(json['alhamdulillahCount']),
      allahuAkbarCount: serializer.fromJson<int>(json['allahuAkbarCount']),
      morningOpenedOn: serializer.fromJson<DateTime?>(json['morningOpenedOn']),
      eveningOpenedOn: serializer.fromJson<DateTime?>(json['eveningOpenedOn']),
      azkarNudges: serializer.fromJson<bool>(json['azkarNudges']),
      azkarVoice: serializer.fromJson<bool>(json['azkarVoice']),
      prayerCountdown: serializer.fromJson<bool>(json['prayerCountdown']),
      calendarMode: $SettingsTable.$convertercalendarMode.fromJson(
        serializer.fromJson<String>(json['calendarMode']),
      ),
      topGlow: serializer.fromJson<bool>(json['topGlow']),
      language: $SettingsTable.$converterlanguage.fromJson(
        serializer.fromJson<String>(json['language']),
      ),
      textSize: $SettingsTable.$convertertextSize.fromJson(
        serializer.fromJson<String>(json['textSize']),
      ),
      onboarded: serializer.fromJson<bool>(json['onboarded']),
      crashReports: serializer.fromJson<bool>(json['crashReports']),
      lastReadSurah: serializer.fromJson<int>(json['lastReadSurah']),
      lastReadAyah: serializer.fromJson<int>(json['lastReadAyah']),
      lastReadPage: serializer.fromJson<int>(json['lastReadPage']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
      pageColor: $SettingsTable.$converterpageColor.fromJson(
        serializer.fromJson<String>(json['pageColor']),
      ),
      quranLayout: $SettingsTable.$converterquranLayout.fromJson(
        serializer.fromJson<String>(json['quranLayout']),
      ),
      pageTurn: $SettingsTable.$converterpageTurn.fromJson(
        serializer.fromJson<String>(json['pageTurn']),
      ),
      keepScreenOn: serializer.fromJson<bool>(json['keepScreenOn']),
      quranFont: $SettingsTable.$converterquranFont.fromJson(
        serializer.fromJson<String>(json['quranFont']),
      ),
      mushafStyle: $SettingsTable.$convertermushafStyle.fromJson(
        serializer.fromJson<String>(json['mushafStyle']),
      ),
      translation: $SettingsTable.$convertertranslationn.fromJson(
        serializer.fromJson<String?>(json['translation']),
      ),
      adhanFlipStops: serializer.fromJson<bool>(json['adhanFlipStops']),
      adhanButtonsStop: serializer.fromJson<bool>(json['adhanButtonsStop']),
      prayerSilent: serializer.fromJson<bool>(json['prayerSilent']),
      prayerSilentMinutes: serializer.fromJson<int>(json['prayerSilentMinutes']),
      mushafSize: serializer.fromJson<int>(json['mushafSize']),
      quranArabicSize: serializer.fromJson<int>(json['quranArabicSize']),
      quranTranslationSize: serializer.fromJson<int>(json['quranTranslationSize']),
      reciteSpeed: serializer.fromJson<double>(json['reciteSpeed']),
      reciteRepeat: serializer.fromJson<int>(json['reciteRepeat']),
      reciter: $SettingsTable.$converterreciter.fromJson(
        serializer.fromJson<String>(json['reciter']),
      ),
      azkarFont: $SettingsTable.$converterazkarFont.fromJson(
        serializer.fromJson<String>(json['azkarFont']),
      ),
      recitePause: serializer.fromJson<int>(json['recitePause']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'placeName': serializer.toJson<String?>(placeName),
      'placeNameAr': serializer.toJson<String?>(placeNameAr),
      'regionName': serializer.toJson<String?>(regionName),
      'regionNameAr': serializer.toJson<String?>(regionNameAr),
      'countryCode': serializer.toJson<String?>(countryCode),
      'timeZone': serializer.toJson<String?>(timeZone),
      'locationMode': serializer.toJson<String?>(
        $SettingsTable.$converterlocationModen.toJson(locationMode),
      ),
      'method': serializer.toJson<String?>($SettingsTable.$convertermethodn.toJson(method)),
      'asrMethod': serializer.toJson<String?>(
        $SettingsTable.$converterasrMethodn.toJson(asrMethod),
      ),
      'hijriAdjust': serializer.toJson<int>(hijriAdjust),
      'digits': serializer.toJson<String>($SettingsTable.$converterdigits.toJson(digits)),
      'theme': serializer.toJson<String>($SettingsTable.$convertertheme.toJson(theme)),
      'themeMode': serializer.toJson<String>($SettingsTable.$converterthemeMode.toJson(themeMode)),
      'reduceMotion': serializer.toJson<bool>(reduceMotion),
      'haptics': serializer.toJson<bool>(haptics),
      'uiSounds': serializer.toJson<bool>(uiSounds),
      'firstUse': serializer.toJson<DateTime?>(firstUse),
      'fajrSound': serializer.toJson<String>($SettingsTable.$converterfajrSound.toJson(fajrSound)),
      'dhuhrSound': serializer.toJson<String>(
        $SettingsTable.$converterdhuhrSound.toJson(dhuhrSound),
      ),
      'asrSound': serializer.toJson<String>($SettingsTable.$converterasrSound.toJson(asrSound)),
      'maghribSound': serializer.toJson<String>(
        $SettingsTable.$convertermaghribSound.toJson(maghribSound),
      ),
      'ishaSound': serializer.toJson<String>($SettingsTable.$converterishaSound.toJson(ishaSound)),
      'fajrRecording': serializer.toJson<String>(
        $SettingsTable.$converterfajrRecording.toJson(fajrRecording),
      ),
      'dhuhrRecording': serializer.toJson<String>(
        $SettingsTable.$converterdhuhrRecording.toJson(dhuhrRecording),
      ),
      'asrRecording': serializer.toJson<String>(
        $SettingsTable.$converterasrRecording.toJson(asrRecording),
      ),
      'maghribRecording': serializer.toJson<String>(
        $SettingsTable.$convertermaghribRecording.toJson(maghribRecording),
      ),
      'ishaRecording': serializer.toJson<String>(
        $SettingsTable.$converterishaRecording.toJson(ishaRecording),
      ),
      'fajrTone': serializer.toJson<String>($SettingsTable.$converterfajrTone.toJson(fajrTone)),
      'dhuhrTone': serializer.toJson<String>($SettingsTable.$converterdhuhrTone.toJson(dhuhrTone)),
      'asrTone': serializer.toJson<String>($SettingsTable.$converterasrTone.toJson(asrTone)),
      'maghribTone': serializer.toJson<String>(
        $SettingsTable.$convertermaghribTone.toJson(maghribTone),
      ),
      'ishaTone': serializer.toJson<String>($SettingsTable.$converterishaTone.toJson(ishaTone)),
      'reminderMinutes': serializer.toJson<int>(reminderMinutes),
      'notificationsAsked': serializer.toJson<bool>(notificationsAsked),
      'tasbihDhikr': serializer.toJson<int>(tasbihDhikr),
      'subhanallahCount': serializer.toJson<int>(subhanallahCount),
      'alhamdulillahCount': serializer.toJson<int>(alhamdulillahCount),
      'allahuAkbarCount': serializer.toJson<int>(allahuAkbarCount),
      'morningOpenedOn': serializer.toJson<DateTime?>(morningOpenedOn),
      'eveningOpenedOn': serializer.toJson<DateTime?>(eveningOpenedOn),
      'azkarNudges': serializer.toJson<bool>(azkarNudges),
      'azkarVoice': serializer.toJson<bool>(azkarVoice),
      'prayerCountdown': serializer.toJson<bool>(prayerCountdown),
      'calendarMode': serializer.toJson<String>(
        $SettingsTable.$convertercalendarMode.toJson(calendarMode),
      ),
      'topGlow': serializer.toJson<bool>(topGlow),
      'language': serializer.toJson<String>($SettingsTable.$converterlanguage.toJson(language)),
      'textSize': serializer.toJson<String>($SettingsTable.$convertertextSize.toJson(textSize)),
      'onboarded': serializer.toJson<bool>(onboarded),
      'crashReports': serializer.toJson<bool>(crashReports),
      'lastReadSurah': serializer.toJson<int>(lastReadSurah),
      'lastReadAyah': serializer.toJson<int>(lastReadAyah),
      'lastReadPage': serializer.toJson<int>(lastReadPage),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
      'pageColor': serializer.toJson<String>($SettingsTable.$converterpageColor.toJson(pageColor)),
      'quranLayout': serializer.toJson<String>(
        $SettingsTable.$converterquranLayout.toJson(quranLayout),
      ),
      'pageTurn': serializer.toJson<String>($SettingsTable.$converterpageTurn.toJson(pageTurn)),
      'keepScreenOn': serializer.toJson<bool>(keepScreenOn),
      'quranFont': serializer.toJson<String>($SettingsTable.$converterquranFont.toJson(quranFont)),
      'mushafStyle': serializer.toJson<String>(
        $SettingsTable.$convertermushafStyle.toJson(mushafStyle),
      ),
      'translation': serializer.toJson<String?>(
        $SettingsTable.$convertertranslationn.toJson(translation),
      ),
      'adhanFlipStops': serializer.toJson<bool>(adhanFlipStops),
      'adhanButtonsStop': serializer.toJson<bool>(adhanButtonsStop),
      'prayerSilent': serializer.toJson<bool>(prayerSilent),
      'prayerSilentMinutes': serializer.toJson<int>(prayerSilentMinutes),
      'mushafSize': serializer.toJson<int>(mushafSize),
      'quranArabicSize': serializer.toJson<int>(quranArabicSize),
      'quranTranslationSize': serializer.toJson<int>(quranTranslationSize),
      'reciteSpeed': serializer.toJson<double>(reciteSpeed),
      'reciteRepeat': serializer.toJson<int>(reciteRepeat),
      'reciter': serializer.toJson<String>($SettingsTable.$converterreciter.toJson(reciter)),
      'azkarFont': serializer.toJson<String>($SettingsTable.$converterazkarFont.toJson(azkarFont)),
      'recitePause': serializer.toJson<int>(recitePause),
    };
  }

  AppSettings copyWith({
    int? id,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> placeName = const Value.absent(),
    Value<String?> placeNameAr = const Value.absent(),
    Value<String?> regionName = const Value.absent(),
    Value<String?> regionNameAr = const Value.absent(),
    Value<String?> countryCode = const Value.absent(),
    Value<String?> timeZone = const Value.absent(),
    Value<LocationMode?> locationMode = const Value.absent(),
    Value<PrayerMethod?> method = const Value.absent(),
    Value<AsrMethod?> asrMethod = const Value.absent(),
    int? hijriAdjust,
    Digits? digits,
    BmThemeId? theme,
    BmThemeMode? themeMode,
    bool? reduceMotion,
    bool? haptics,
    bool? uiSounds,
    Value<DateTime?> firstUse = const Value.absent(),
    PrayerSound? fajrSound,
    PrayerSound? dhuhrSound,
    PrayerSound? asrSound,
    PrayerSound? maghribSound,
    PrayerSound? ishaSound,
    AdhanRecording? fajrRecording,
    AdhanRecording? dhuhrRecording,
    AdhanRecording? asrRecording,
    AdhanRecording? maghribRecording,
    AdhanRecording? ishaRecording,
    PrayerTone? fajrTone,
    PrayerTone? dhuhrTone,
    PrayerTone? asrTone,
    PrayerTone? maghribTone,
    PrayerTone? ishaTone,
    int? reminderMinutes,
    bool? notificationsAsked,
    int? tasbihDhikr,
    int? subhanallahCount,
    int? alhamdulillahCount,
    int? allahuAkbarCount,
    Value<DateTime?> morningOpenedOn = const Value.absent(),
    Value<DateTime?> eveningOpenedOn = const Value.absent(),
    bool? azkarNudges,
    bool? azkarVoice,
    bool? prayerCountdown,
    CalendarMode? calendarMode,
    bool? topGlow,
    Language? language,
    TextSize? textSize,
    bool? onboarded,
    bool? crashReports,
    int? lastReadSurah,
    int? lastReadAyah,
    int? lastReadPage,
    Value<DateTime?> lastReadAt = const Value.absent(),
    PageColor? pageColor,
    QuranLayout? quranLayout,
    PageTurn? pageTurn,
    bool? keepScreenOn,
    QuranFont? quranFont,
    MushafStyle? mushafStyle,
    Value<Translation?> translation = const Value.absent(),
    bool? adhanFlipStops,
    bool? adhanButtonsStop,
    bool? prayerSilent,
    int? prayerSilentMinutes,
    int? mushafSize,
    int? quranArabicSize,
    int? quranTranslationSize,
    double? reciteSpeed,
    int? reciteRepeat,
    Reciter? reciter,
    AzkarFont? azkarFont,
    int? recitePause,
  }) => AppSettings(
    id: id ?? this.id,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    placeName: placeName.present ? placeName.value : this.placeName,
    placeNameAr: placeNameAr.present ? placeNameAr.value : this.placeNameAr,
    regionName: regionName.present ? regionName.value : this.regionName,
    regionNameAr: regionNameAr.present ? regionNameAr.value : this.regionNameAr,
    countryCode: countryCode.present ? countryCode.value : this.countryCode,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    locationMode: locationMode.present ? locationMode.value : this.locationMode,
    method: method.present ? method.value : this.method,
    asrMethod: asrMethod.present ? asrMethod.value : this.asrMethod,
    hijriAdjust: hijriAdjust ?? this.hijriAdjust,
    digits: digits ?? this.digits,
    theme: theme ?? this.theme,
    themeMode: themeMode ?? this.themeMode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    haptics: haptics ?? this.haptics,
    uiSounds: uiSounds ?? this.uiSounds,
    firstUse: firstUse.present ? firstUse.value : this.firstUse,
    fajrSound: fajrSound ?? this.fajrSound,
    dhuhrSound: dhuhrSound ?? this.dhuhrSound,
    asrSound: asrSound ?? this.asrSound,
    maghribSound: maghribSound ?? this.maghribSound,
    ishaSound: ishaSound ?? this.ishaSound,
    fajrRecording: fajrRecording ?? this.fajrRecording,
    dhuhrRecording: dhuhrRecording ?? this.dhuhrRecording,
    asrRecording: asrRecording ?? this.asrRecording,
    maghribRecording: maghribRecording ?? this.maghribRecording,
    ishaRecording: ishaRecording ?? this.ishaRecording,
    fajrTone: fajrTone ?? this.fajrTone,
    dhuhrTone: dhuhrTone ?? this.dhuhrTone,
    asrTone: asrTone ?? this.asrTone,
    maghribTone: maghribTone ?? this.maghribTone,
    ishaTone: ishaTone ?? this.ishaTone,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    notificationsAsked: notificationsAsked ?? this.notificationsAsked,
    tasbihDhikr: tasbihDhikr ?? this.tasbihDhikr,
    subhanallahCount: subhanallahCount ?? this.subhanallahCount,
    alhamdulillahCount: alhamdulillahCount ?? this.alhamdulillahCount,
    allahuAkbarCount: allahuAkbarCount ?? this.allahuAkbarCount,
    morningOpenedOn: morningOpenedOn.present ? morningOpenedOn.value : this.morningOpenedOn,
    eveningOpenedOn: eveningOpenedOn.present ? eveningOpenedOn.value : this.eveningOpenedOn,
    azkarNudges: azkarNudges ?? this.azkarNudges,
    azkarVoice: azkarVoice ?? this.azkarVoice,
    prayerCountdown: prayerCountdown ?? this.prayerCountdown,
    calendarMode: calendarMode ?? this.calendarMode,
    topGlow: topGlow ?? this.topGlow,
    language: language ?? this.language,
    textSize: textSize ?? this.textSize,
    onboarded: onboarded ?? this.onboarded,
    crashReports: crashReports ?? this.crashReports,
    lastReadSurah: lastReadSurah ?? this.lastReadSurah,
    lastReadAyah: lastReadAyah ?? this.lastReadAyah,
    lastReadPage: lastReadPage ?? this.lastReadPage,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    pageColor: pageColor ?? this.pageColor,
    quranLayout: quranLayout ?? this.quranLayout,
    pageTurn: pageTurn ?? this.pageTurn,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    quranFont: quranFont ?? this.quranFont,
    mushafStyle: mushafStyle ?? this.mushafStyle,
    translation: translation.present ? translation.value : this.translation,
    adhanFlipStops: adhanFlipStops ?? this.adhanFlipStops,
    adhanButtonsStop: adhanButtonsStop ?? this.adhanButtonsStop,
    prayerSilent: prayerSilent ?? this.prayerSilent,
    prayerSilentMinutes: prayerSilentMinutes ?? this.prayerSilentMinutes,
    mushafSize: mushafSize ?? this.mushafSize,
    quranArabicSize: quranArabicSize ?? this.quranArabicSize,
    quranTranslationSize: quranTranslationSize ?? this.quranTranslationSize,
    reciteSpeed: reciteSpeed ?? this.reciteSpeed,
    reciteRepeat: reciteRepeat ?? this.reciteRepeat,
    reciter: reciter ?? this.reciter,
    azkarFont: azkarFont ?? this.azkarFont,
    recitePause: recitePause ?? this.recitePause,
  );
  AppSettings copyWithCompanion(SettingsCompanion data) {
    return AppSettings(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      placeNameAr: data.placeNameAr.present ? data.placeNameAr.value : this.placeNameAr,
      regionName: data.regionName.present ? data.regionName.value : this.regionName,
      regionNameAr: data.regionNameAr.present ? data.regionNameAr.value : this.regionNameAr,
      countryCode: data.countryCode.present ? data.countryCode.value : this.countryCode,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      locationMode: data.locationMode.present ? data.locationMode.value : this.locationMode,
      method: data.method.present ? data.method.value : this.method,
      asrMethod: data.asrMethod.present ? data.asrMethod.value : this.asrMethod,
      hijriAdjust: data.hijriAdjust.present ? data.hijriAdjust.value : this.hijriAdjust,
      digits: data.digits.present ? data.digits.value : this.digits,
      theme: data.theme.present ? data.theme.value : this.theme,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      reduceMotion: data.reduceMotion.present ? data.reduceMotion.value : this.reduceMotion,
      haptics: data.haptics.present ? data.haptics.value : this.haptics,
      uiSounds: data.uiSounds.present ? data.uiSounds.value : this.uiSounds,
      firstUse: data.firstUse.present ? data.firstUse.value : this.firstUse,
      fajrSound: data.fajrSound.present ? data.fajrSound.value : this.fajrSound,
      dhuhrSound: data.dhuhrSound.present ? data.dhuhrSound.value : this.dhuhrSound,
      asrSound: data.asrSound.present ? data.asrSound.value : this.asrSound,
      maghribSound: data.maghribSound.present ? data.maghribSound.value : this.maghribSound,
      ishaSound: data.ishaSound.present ? data.ishaSound.value : this.ishaSound,
      fajrRecording: data.fajrRecording.present ? data.fajrRecording.value : this.fajrRecording,
      dhuhrRecording: data.dhuhrRecording.present ? data.dhuhrRecording.value : this.dhuhrRecording,
      asrRecording: data.asrRecording.present ? data.asrRecording.value : this.asrRecording,
      maghribRecording: data.maghribRecording.present
          ? data.maghribRecording.value
          : this.maghribRecording,
      ishaRecording: data.ishaRecording.present ? data.ishaRecording.value : this.ishaRecording,
      fajrTone: data.fajrTone.present ? data.fajrTone.value : this.fajrTone,
      dhuhrTone: data.dhuhrTone.present ? data.dhuhrTone.value : this.dhuhrTone,
      asrTone: data.asrTone.present ? data.asrTone.value : this.asrTone,
      maghribTone: data.maghribTone.present ? data.maghribTone.value : this.maghribTone,
      ishaTone: data.ishaTone.present ? data.ishaTone.value : this.ishaTone,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      notificationsAsked: data.notificationsAsked.present
          ? data.notificationsAsked.value
          : this.notificationsAsked,
      tasbihDhikr: data.tasbihDhikr.present ? data.tasbihDhikr.value : this.tasbihDhikr,
      subhanallahCount: data.subhanallahCount.present
          ? data.subhanallahCount.value
          : this.subhanallahCount,
      alhamdulillahCount: data.alhamdulillahCount.present
          ? data.alhamdulillahCount.value
          : this.alhamdulillahCount,
      allahuAkbarCount: data.allahuAkbarCount.present
          ? data.allahuAkbarCount.value
          : this.allahuAkbarCount,
      morningOpenedOn: data.morningOpenedOn.present
          ? data.morningOpenedOn.value
          : this.morningOpenedOn,
      eveningOpenedOn: data.eveningOpenedOn.present
          ? data.eveningOpenedOn.value
          : this.eveningOpenedOn,
      azkarNudges: data.azkarNudges.present ? data.azkarNudges.value : this.azkarNudges,
      azkarVoice: data.azkarVoice.present ? data.azkarVoice.value : this.azkarVoice,
      prayerCountdown: data.prayerCountdown.present
          ? data.prayerCountdown.value
          : this.prayerCountdown,
      calendarMode: data.calendarMode.present ? data.calendarMode.value : this.calendarMode,
      topGlow: data.topGlow.present ? data.topGlow.value : this.topGlow,
      language: data.language.present ? data.language.value : this.language,
      textSize: data.textSize.present ? data.textSize.value : this.textSize,
      onboarded: data.onboarded.present ? data.onboarded.value : this.onboarded,
      crashReports: data.crashReports.present ? data.crashReports.value : this.crashReports,
      lastReadSurah: data.lastReadSurah.present ? data.lastReadSurah.value : this.lastReadSurah,
      lastReadAyah: data.lastReadAyah.present ? data.lastReadAyah.value : this.lastReadAyah,
      lastReadPage: data.lastReadPage.present ? data.lastReadPage.value : this.lastReadPage,
      lastReadAt: data.lastReadAt.present ? data.lastReadAt.value : this.lastReadAt,
      pageColor: data.pageColor.present ? data.pageColor.value : this.pageColor,
      quranLayout: data.quranLayout.present ? data.quranLayout.value : this.quranLayout,
      pageTurn: data.pageTurn.present ? data.pageTurn.value : this.pageTurn,
      keepScreenOn: data.keepScreenOn.present ? data.keepScreenOn.value : this.keepScreenOn,
      quranFont: data.quranFont.present ? data.quranFont.value : this.quranFont,
      mushafStyle: data.mushafStyle.present ? data.mushafStyle.value : this.mushafStyle,
      translation: data.translation.present ? data.translation.value : this.translation,
      adhanFlipStops: data.adhanFlipStops.present ? data.adhanFlipStops.value : this.adhanFlipStops,
      adhanButtonsStop: data.adhanButtonsStop.present
          ? data.adhanButtonsStop.value
          : this.adhanButtonsStop,
      prayerSilent: data.prayerSilent.present ? data.prayerSilent.value : this.prayerSilent,
      prayerSilentMinutes: data.prayerSilentMinutes.present
          ? data.prayerSilentMinutes.value
          : this.prayerSilentMinutes,
      mushafSize: data.mushafSize.present ? data.mushafSize.value : this.mushafSize,
      quranArabicSize: data.quranArabicSize.present
          ? data.quranArabicSize.value
          : this.quranArabicSize,
      quranTranslationSize: data.quranTranslationSize.present
          ? data.quranTranslationSize.value
          : this.quranTranslationSize,
      reciteSpeed: data.reciteSpeed.present ? data.reciteSpeed.value : this.reciteSpeed,
      reciteRepeat: data.reciteRepeat.present ? data.reciteRepeat.value : this.reciteRepeat,
      reciter: data.reciter.present ? data.reciter.value : this.reciter,
      azkarFont: data.azkarFont.present ? data.azkarFont.value : this.azkarFont,
      recitePause: data.recitePause.present ? data.recitePause.value : this.recitePause,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettings(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeName: $placeName, ')
          ..write('placeNameAr: $placeNameAr, ')
          ..write('regionName: $regionName, ')
          ..write('regionNameAr: $regionNameAr, ')
          ..write('countryCode: $countryCode, ')
          ..write('timeZone: $timeZone, ')
          ..write('locationMode: $locationMode, ')
          ..write('method: $method, ')
          ..write('asrMethod: $asrMethod, ')
          ..write('hijriAdjust: $hijriAdjust, ')
          ..write('digits: $digits, ')
          ..write('theme: $theme, ')
          ..write('themeMode: $themeMode, ')
          ..write('reduceMotion: $reduceMotion, ')
          ..write('haptics: $haptics, ')
          ..write('uiSounds: $uiSounds, ')
          ..write('firstUse: $firstUse, ')
          ..write('fajrSound: $fajrSound, ')
          ..write('dhuhrSound: $dhuhrSound, ')
          ..write('asrSound: $asrSound, ')
          ..write('maghribSound: $maghribSound, ')
          ..write('ishaSound: $ishaSound, ')
          ..write('fajrRecording: $fajrRecording, ')
          ..write('dhuhrRecording: $dhuhrRecording, ')
          ..write('asrRecording: $asrRecording, ')
          ..write('maghribRecording: $maghribRecording, ')
          ..write('ishaRecording: $ishaRecording, ')
          ..write('fajrTone: $fajrTone, ')
          ..write('dhuhrTone: $dhuhrTone, ')
          ..write('asrTone: $asrTone, ')
          ..write('maghribTone: $maghribTone, ')
          ..write('ishaTone: $ishaTone, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('notificationsAsked: $notificationsAsked, ')
          ..write('tasbihDhikr: $tasbihDhikr, ')
          ..write('subhanallahCount: $subhanallahCount, ')
          ..write('alhamdulillahCount: $alhamdulillahCount, ')
          ..write('allahuAkbarCount: $allahuAkbarCount, ')
          ..write('morningOpenedOn: $morningOpenedOn, ')
          ..write('eveningOpenedOn: $eveningOpenedOn, ')
          ..write('azkarNudges: $azkarNudges, ')
          ..write('azkarVoice: $azkarVoice, ')
          ..write('prayerCountdown: $prayerCountdown, ')
          ..write('calendarMode: $calendarMode, ')
          ..write('topGlow: $topGlow, ')
          ..write('language: $language, ')
          ..write('textSize: $textSize, ')
          ..write('onboarded: $onboarded, ')
          ..write('crashReports: $crashReports, ')
          ..write('lastReadSurah: $lastReadSurah, ')
          ..write('lastReadAyah: $lastReadAyah, ')
          ..write('lastReadPage: $lastReadPage, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('pageColor: $pageColor, ')
          ..write('quranLayout: $quranLayout, ')
          ..write('pageTurn: $pageTurn, ')
          ..write('keepScreenOn: $keepScreenOn, ')
          ..write('quranFont: $quranFont, ')
          ..write('mushafStyle: $mushafStyle, ')
          ..write('translation: $translation, ')
          ..write('adhanFlipStops: $adhanFlipStops, ')
          ..write('adhanButtonsStop: $adhanButtonsStop, ')
          ..write('prayerSilent: $prayerSilent, ')
          ..write('prayerSilentMinutes: $prayerSilentMinutes, ')
          ..write('mushafSize: $mushafSize, ')
          ..write('quranArabicSize: $quranArabicSize, ')
          ..write('quranTranslationSize: $quranTranslationSize, ')
          ..write('reciteSpeed: $reciteSpeed, ')
          ..write('reciteRepeat: $reciteRepeat, ')
          ..write('reciter: $reciter, ')
          ..write('azkarFont: $azkarFont, ')
          ..write('recitePause: $recitePause')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    latitude,
    longitude,
    placeName,
    placeNameAr,
    regionName,
    regionNameAr,
    countryCode,
    timeZone,
    locationMode,
    method,
    asrMethod,
    hijriAdjust,
    digits,
    theme,
    themeMode,
    reduceMotion,
    haptics,
    uiSounds,
    firstUse,
    fajrSound,
    dhuhrSound,
    asrSound,
    maghribSound,
    ishaSound,
    fajrRecording,
    dhuhrRecording,
    asrRecording,
    maghribRecording,
    ishaRecording,
    fajrTone,
    dhuhrTone,
    asrTone,
    maghribTone,
    ishaTone,
    reminderMinutes,
    notificationsAsked,
    tasbihDhikr,
    subhanallahCount,
    alhamdulillahCount,
    allahuAkbarCount,
    morningOpenedOn,
    eveningOpenedOn,
    azkarNudges,
    azkarVoice,
    prayerCountdown,
    calendarMode,
    topGlow,
    language,
    textSize,
    onboarded,
    crashReports,
    lastReadSurah,
    lastReadAyah,
    lastReadPage,
    lastReadAt,
    pageColor,
    quranLayout,
    pageTurn,
    keepScreenOn,
    quranFont,
    mushafStyle,
    translation,
    adhanFlipStops,
    adhanButtonsStop,
    prayerSilent,
    prayerSilentMinutes,
    mushafSize,
    quranArabicSize,
    quranTranslationSize,
    reciteSpeed,
    reciteRepeat,
    reciter,
    azkarFont,
    recitePause,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.placeName == this.placeName &&
          other.placeNameAr == this.placeNameAr &&
          other.regionName == this.regionName &&
          other.regionNameAr == this.regionNameAr &&
          other.countryCode == this.countryCode &&
          other.timeZone == this.timeZone &&
          other.locationMode == this.locationMode &&
          other.method == this.method &&
          other.asrMethod == this.asrMethod &&
          other.hijriAdjust == this.hijriAdjust &&
          other.digits == this.digits &&
          other.theme == this.theme &&
          other.themeMode == this.themeMode &&
          other.reduceMotion == this.reduceMotion &&
          other.haptics == this.haptics &&
          other.uiSounds == this.uiSounds &&
          other.firstUse == this.firstUse &&
          other.fajrSound == this.fajrSound &&
          other.dhuhrSound == this.dhuhrSound &&
          other.asrSound == this.asrSound &&
          other.maghribSound == this.maghribSound &&
          other.ishaSound == this.ishaSound &&
          other.fajrRecording == this.fajrRecording &&
          other.dhuhrRecording == this.dhuhrRecording &&
          other.asrRecording == this.asrRecording &&
          other.maghribRecording == this.maghribRecording &&
          other.ishaRecording == this.ishaRecording &&
          other.fajrTone == this.fajrTone &&
          other.dhuhrTone == this.dhuhrTone &&
          other.asrTone == this.asrTone &&
          other.maghribTone == this.maghribTone &&
          other.ishaTone == this.ishaTone &&
          other.reminderMinutes == this.reminderMinutes &&
          other.notificationsAsked == this.notificationsAsked &&
          other.tasbihDhikr == this.tasbihDhikr &&
          other.subhanallahCount == this.subhanallahCount &&
          other.alhamdulillahCount == this.alhamdulillahCount &&
          other.allahuAkbarCount == this.allahuAkbarCount &&
          other.morningOpenedOn == this.morningOpenedOn &&
          other.eveningOpenedOn == this.eveningOpenedOn &&
          other.azkarNudges == this.azkarNudges &&
          other.azkarVoice == this.azkarVoice &&
          other.prayerCountdown == this.prayerCountdown &&
          other.calendarMode == this.calendarMode &&
          other.topGlow == this.topGlow &&
          other.language == this.language &&
          other.textSize == this.textSize &&
          other.onboarded == this.onboarded &&
          other.crashReports == this.crashReports &&
          other.lastReadSurah == this.lastReadSurah &&
          other.lastReadAyah == this.lastReadAyah &&
          other.lastReadPage == this.lastReadPage &&
          other.lastReadAt == this.lastReadAt &&
          other.pageColor == this.pageColor &&
          other.quranLayout == this.quranLayout &&
          other.pageTurn == this.pageTurn &&
          other.keepScreenOn == this.keepScreenOn &&
          other.quranFont == this.quranFont &&
          other.mushafStyle == this.mushafStyle &&
          other.translation == this.translation &&
          other.adhanFlipStops == this.adhanFlipStops &&
          other.adhanButtonsStop == this.adhanButtonsStop &&
          other.prayerSilent == this.prayerSilent &&
          other.prayerSilentMinutes == this.prayerSilentMinutes &&
          other.mushafSize == this.mushafSize &&
          other.quranArabicSize == this.quranArabicSize &&
          other.quranTranslationSize == this.quranTranslationSize &&
          other.reciteSpeed == this.reciteSpeed &&
          other.reciteRepeat == this.reciteRepeat &&
          other.reciter == this.reciter &&
          other.azkarFont == this.azkarFont &&
          other.recitePause == this.recitePause);
}

class SettingsCompanion extends UpdateCompanion<AppSettings> {
  final Value<int> id;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> placeName;
  final Value<String?> placeNameAr;
  final Value<String?> regionName;
  final Value<String?> regionNameAr;
  final Value<String?> countryCode;
  final Value<String?> timeZone;
  final Value<LocationMode?> locationMode;
  final Value<PrayerMethod?> method;
  final Value<AsrMethod?> asrMethod;
  final Value<int> hijriAdjust;
  final Value<Digits> digits;
  final Value<BmThemeId> theme;
  final Value<BmThemeMode> themeMode;
  final Value<bool> reduceMotion;
  final Value<bool> haptics;
  final Value<bool> uiSounds;
  final Value<DateTime?> firstUse;
  final Value<PrayerSound> fajrSound;
  final Value<PrayerSound> dhuhrSound;
  final Value<PrayerSound> asrSound;
  final Value<PrayerSound> maghribSound;
  final Value<PrayerSound> ishaSound;
  final Value<AdhanRecording> fajrRecording;
  final Value<AdhanRecording> dhuhrRecording;
  final Value<AdhanRecording> asrRecording;
  final Value<AdhanRecording> maghribRecording;
  final Value<AdhanRecording> ishaRecording;
  final Value<PrayerTone> fajrTone;
  final Value<PrayerTone> dhuhrTone;
  final Value<PrayerTone> asrTone;
  final Value<PrayerTone> maghribTone;
  final Value<PrayerTone> ishaTone;
  final Value<int> reminderMinutes;
  final Value<bool> notificationsAsked;
  final Value<int> tasbihDhikr;
  final Value<int> subhanallahCount;
  final Value<int> alhamdulillahCount;
  final Value<int> allahuAkbarCount;
  final Value<DateTime?> morningOpenedOn;
  final Value<DateTime?> eveningOpenedOn;
  final Value<bool> azkarNudges;
  final Value<bool> azkarVoice;
  final Value<bool> prayerCountdown;
  final Value<CalendarMode> calendarMode;
  final Value<bool> topGlow;
  final Value<Language> language;
  final Value<TextSize> textSize;
  final Value<bool> onboarded;
  final Value<bool> crashReports;
  final Value<int> lastReadSurah;
  final Value<int> lastReadAyah;
  final Value<int> lastReadPage;
  final Value<DateTime?> lastReadAt;
  final Value<PageColor> pageColor;
  final Value<QuranLayout> quranLayout;
  final Value<PageTurn> pageTurn;
  final Value<bool> keepScreenOn;
  final Value<QuranFont> quranFont;
  final Value<MushafStyle> mushafStyle;
  final Value<Translation?> translation;
  final Value<bool> adhanFlipStops;
  final Value<bool> adhanButtonsStop;
  final Value<bool> prayerSilent;
  final Value<int> prayerSilentMinutes;
  final Value<int> mushafSize;
  final Value<int> quranArabicSize;
  final Value<int> quranTranslationSize;
  final Value<double> reciteSpeed;
  final Value<int> reciteRepeat;
  final Value<Reciter> reciter;
  final Value<AzkarFont> azkarFont;
  final Value<int> recitePause;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeName = const Value.absent(),
    this.placeNameAr = const Value.absent(),
    this.regionName = const Value.absent(),
    this.regionNameAr = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.locationMode = const Value.absent(),
    this.method = const Value.absent(),
    this.asrMethod = const Value.absent(),
    this.hijriAdjust = const Value.absent(),
    this.digits = const Value.absent(),
    this.theme = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.reduceMotion = const Value.absent(),
    this.haptics = const Value.absent(),
    this.uiSounds = const Value.absent(),
    this.firstUse = const Value.absent(),
    this.fajrSound = const Value.absent(),
    this.dhuhrSound = const Value.absent(),
    this.asrSound = const Value.absent(),
    this.maghribSound = const Value.absent(),
    this.ishaSound = const Value.absent(),
    this.fajrRecording = const Value.absent(),
    this.dhuhrRecording = const Value.absent(),
    this.asrRecording = const Value.absent(),
    this.maghribRecording = const Value.absent(),
    this.ishaRecording = const Value.absent(),
    this.fajrTone = const Value.absent(),
    this.dhuhrTone = const Value.absent(),
    this.asrTone = const Value.absent(),
    this.maghribTone = const Value.absent(),
    this.ishaTone = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.notificationsAsked = const Value.absent(),
    this.tasbihDhikr = const Value.absent(),
    this.subhanallahCount = const Value.absent(),
    this.alhamdulillahCount = const Value.absent(),
    this.allahuAkbarCount = const Value.absent(),
    this.morningOpenedOn = const Value.absent(),
    this.eveningOpenedOn = const Value.absent(),
    this.azkarNudges = const Value.absent(),
    this.azkarVoice = const Value.absent(),
    this.prayerCountdown = const Value.absent(),
    this.calendarMode = const Value.absent(),
    this.topGlow = const Value.absent(),
    this.language = const Value.absent(),
    this.textSize = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.crashReports = const Value.absent(),
    this.lastReadSurah = const Value.absent(),
    this.lastReadAyah = const Value.absent(),
    this.lastReadPage = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.pageColor = const Value.absent(),
    this.quranLayout = const Value.absent(),
    this.pageTurn = const Value.absent(),
    this.keepScreenOn = const Value.absent(),
    this.quranFont = const Value.absent(),
    this.mushafStyle = const Value.absent(),
    this.translation = const Value.absent(),
    this.adhanFlipStops = const Value.absent(),
    this.adhanButtonsStop = const Value.absent(),
    this.prayerSilent = const Value.absent(),
    this.prayerSilentMinutes = const Value.absent(),
    this.mushafSize = const Value.absent(),
    this.quranArabicSize = const Value.absent(),
    this.quranTranslationSize = const Value.absent(),
    this.reciteSpeed = const Value.absent(),
    this.reciteRepeat = const Value.absent(),
    this.reciter = const Value.absent(),
    this.azkarFont = const Value.absent(),
    this.recitePause = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeName = const Value.absent(),
    this.placeNameAr = const Value.absent(),
    this.regionName = const Value.absent(),
    this.regionNameAr = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.locationMode = const Value.absent(),
    this.method = const Value.absent(),
    this.asrMethod = const Value.absent(),
    this.hijriAdjust = const Value.absent(),
    this.digits = const Value.absent(),
    this.theme = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.reduceMotion = const Value.absent(),
    this.haptics = const Value.absent(),
    this.uiSounds = const Value.absent(),
    this.firstUse = const Value.absent(),
    this.fajrSound = const Value.absent(),
    this.dhuhrSound = const Value.absent(),
    this.asrSound = const Value.absent(),
    this.maghribSound = const Value.absent(),
    this.ishaSound = const Value.absent(),
    this.fajrRecording = const Value.absent(),
    this.dhuhrRecording = const Value.absent(),
    this.asrRecording = const Value.absent(),
    this.maghribRecording = const Value.absent(),
    this.ishaRecording = const Value.absent(),
    this.fajrTone = const Value.absent(),
    this.dhuhrTone = const Value.absent(),
    this.asrTone = const Value.absent(),
    this.maghribTone = const Value.absent(),
    this.ishaTone = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.notificationsAsked = const Value.absent(),
    this.tasbihDhikr = const Value.absent(),
    this.subhanallahCount = const Value.absent(),
    this.alhamdulillahCount = const Value.absent(),
    this.allahuAkbarCount = const Value.absent(),
    this.morningOpenedOn = const Value.absent(),
    this.eveningOpenedOn = const Value.absent(),
    this.azkarNudges = const Value.absent(),
    this.azkarVoice = const Value.absent(),
    this.prayerCountdown = const Value.absent(),
    this.calendarMode = const Value.absent(),
    this.topGlow = const Value.absent(),
    this.language = const Value.absent(),
    this.textSize = const Value.absent(),
    this.onboarded = const Value.absent(),
    this.crashReports = const Value.absent(),
    this.lastReadSurah = const Value.absent(),
    this.lastReadAyah = const Value.absent(),
    this.lastReadPage = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.pageColor = const Value.absent(),
    this.quranLayout = const Value.absent(),
    this.pageTurn = const Value.absent(),
    this.keepScreenOn = const Value.absent(),
    this.quranFont = const Value.absent(),
    this.mushafStyle = const Value.absent(),
    this.translation = const Value.absent(),
    this.adhanFlipStops = const Value.absent(),
    this.adhanButtonsStop = const Value.absent(),
    this.prayerSilent = const Value.absent(),
    this.prayerSilentMinutes = const Value.absent(),
    this.mushafSize = const Value.absent(),
    this.quranArabicSize = const Value.absent(),
    this.quranTranslationSize = const Value.absent(),
    this.reciteSpeed = const Value.absent(),
    this.reciteRepeat = const Value.absent(),
    this.reciter = const Value.absent(),
    this.azkarFont = const Value.absent(),
    this.recitePause = const Value.absent(),
  });
  static Insertable<AppSettings> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? placeName,
    Expression<String>? placeNameAr,
    Expression<String>? regionName,
    Expression<String>? regionNameAr,
    Expression<String>? countryCode,
    Expression<String>? timeZone,
    Expression<String>? locationMode,
    Expression<String>? method,
    Expression<String>? asrMethod,
    Expression<int>? hijriAdjust,
    Expression<String>? digits,
    Expression<String>? theme,
    Expression<String>? themeMode,
    Expression<bool>? reduceMotion,
    Expression<bool>? haptics,
    Expression<bool>? uiSounds,
    Expression<String>? firstUse,
    Expression<String>? fajrSound,
    Expression<String>? dhuhrSound,
    Expression<String>? asrSound,
    Expression<String>? maghribSound,
    Expression<String>? ishaSound,
    Expression<String>? fajrRecording,
    Expression<String>? dhuhrRecording,
    Expression<String>? asrRecording,
    Expression<String>? maghribRecording,
    Expression<String>? ishaRecording,
    Expression<String>? fajrTone,
    Expression<String>? dhuhrTone,
    Expression<String>? asrTone,
    Expression<String>? maghribTone,
    Expression<String>? ishaTone,
    Expression<int>? reminderMinutes,
    Expression<bool>? notificationsAsked,
    Expression<int>? tasbihDhikr,
    Expression<int>? subhanallahCount,
    Expression<int>? alhamdulillahCount,
    Expression<int>? allahuAkbarCount,
    Expression<String>? morningOpenedOn,
    Expression<String>? eveningOpenedOn,
    Expression<bool>? azkarNudges,
    Expression<bool>? azkarVoice,
    Expression<bool>? prayerCountdown,
    Expression<String>? calendarMode,
    Expression<bool>? topGlow,
    Expression<String>? language,
    Expression<String>? textSize,
    Expression<bool>? onboarded,
    Expression<bool>? crashReports,
    Expression<int>? lastReadSurah,
    Expression<int>? lastReadAyah,
    Expression<int>? lastReadPage,
    Expression<DateTime>? lastReadAt,
    Expression<String>? pageColor,
    Expression<String>? quranLayout,
    Expression<String>? pageTurn,
    Expression<bool>? keepScreenOn,
    Expression<String>? quranFont,
    Expression<String>? mushafStyle,
    Expression<String>? translation,
    Expression<bool>? adhanFlipStops,
    Expression<bool>? adhanButtonsStop,
    Expression<bool>? prayerSilent,
    Expression<int>? prayerSilentMinutes,
    Expression<int>? mushafSize,
    Expression<int>? quranArabicSize,
    Expression<int>? quranTranslationSize,
    Expression<double>? reciteSpeed,
    Expression<int>? reciteRepeat,
    Expression<String>? reciter,
    Expression<String>? azkarFont,
    Expression<int>? recitePause,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeName != null) 'place_name': placeName,
      if (placeNameAr != null) 'place_name_ar': placeNameAr,
      if (regionName != null) 'region_name': regionName,
      if (regionNameAr != null) 'region_name_ar': regionNameAr,
      if (countryCode != null) 'country_code': countryCode,
      if (timeZone != null) 'time_zone': timeZone,
      if (locationMode != null) 'location_mode': locationMode,
      if (method != null) 'method': method,
      if (asrMethod != null) 'asr_method': asrMethod,
      if (hijriAdjust != null) 'hijri_adjust': hijriAdjust,
      if (digits != null) 'digits': digits,
      if (theme != null) 'theme': theme,
      if (themeMode != null) 'theme_mode': themeMode,
      if (reduceMotion != null) 'reduce_motion': reduceMotion,
      if (haptics != null) 'haptics': haptics,
      if (uiSounds != null) 'ui_sounds': uiSounds,
      if (firstUse != null) 'first_use': firstUse,
      if (fajrSound != null) 'fajr_sound': fajrSound,
      if (dhuhrSound != null) 'dhuhr_sound': dhuhrSound,
      if (asrSound != null) 'asr_sound': asrSound,
      if (maghribSound != null) 'maghrib_sound': maghribSound,
      if (ishaSound != null) 'isha_sound': ishaSound,
      if (fajrRecording != null) 'fajr_recording': fajrRecording,
      if (dhuhrRecording != null) 'dhuhr_recording': dhuhrRecording,
      if (asrRecording != null) 'asr_recording': asrRecording,
      if (maghribRecording != null) 'maghrib_recording': maghribRecording,
      if (ishaRecording != null) 'isha_recording': ishaRecording,
      if (fajrTone != null) 'fajr_tone': fajrTone,
      if (dhuhrTone != null) 'dhuhr_tone': dhuhrTone,
      if (asrTone != null) 'asr_tone': asrTone,
      if (maghribTone != null) 'maghrib_tone': maghribTone,
      if (ishaTone != null) 'isha_tone': ishaTone,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (notificationsAsked != null) 'notifications_asked': notificationsAsked,
      if (tasbihDhikr != null) 'tasbih_dhikr': tasbihDhikr,
      if (subhanallahCount != null) 'subhanallah_count': subhanallahCount,
      if (alhamdulillahCount != null) 'alhamdulillah_count': alhamdulillahCount,
      if (allahuAkbarCount != null) 'allahu_akbar_count': allahuAkbarCount,
      if (morningOpenedOn != null) 'morning_opened_on': morningOpenedOn,
      if (eveningOpenedOn != null) 'evening_opened_on': eveningOpenedOn,
      if (azkarNudges != null) 'azkar_nudges': azkarNudges,
      if (azkarVoice != null) 'azkar_voice': azkarVoice,
      if (prayerCountdown != null) 'prayer_countdown': prayerCountdown,
      if (calendarMode != null) 'calendar_mode': calendarMode,
      if (topGlow != null) 'top_glow': topGlow,
      if (language != null) 'language': language,
      if (textSize != null) 'text_size': textSize,
      if (onboarded != null) 'onboarded': onboarded,
      if (crashReports != null) 'crash_reports': crashReports,
      if (lastReadSurah != null) 'last_read_surah': lastReadSurah,
      if (lastReadAyah != null) 'last_read_ayah': lastReadAyah,
      if (lastReadPage != null) 'last_read_page': lastReadPage,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (pageColor != null) 'page_color': pageColor,
      if (quranLayout != null) 'quran_layout': quranLayout,
      if (pageTurn != null) 'page_turn': pageTurn,
      if (keepScreenOn != null) 'keep_screen_on': keepScreenOn,
      if (quranFont != null) 'quran_font': quranFont,
      if (mushafStyle != null) 'mushaf_style': mushafStyle,
      if (translation != null) 'translation': translation,
      if (adhanFlipStops != null) 'adhan_flip_stops': adhanFlipStops,
      if (adhanButtonsStop != null) 'adhan_buttons_stop': adhanButtonsStop,
      if (prayerSilent != null) 'prayer_silent': prayerSilent,
      if (prayerSilentMinutes != null) 'prayer_silent_minutes': prayerSilentMinutes,
      if (mushafSize != null) 'mushaf_size': mushafSize,
      if (quranArabicSize != null) 'quran_arabic_size': quranArabicSize,
      if (quranTranslationSize != null) 'quran_translation_size': quranTranslationSize,
      if (reciteSpeed != null) 'recite_speed': reciteSpeed,
      if (reciteRepeat != null) 'recite_repeat': reciteRepeat,
      if (reciter != null) 'reciter': reciter,
      if (azkarFont != null) 'azkar_font': azkarFont,
      if (recitePause != null) 'recite_pause': recitePause,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? placeName,
    Value<String?>? placeNameAr,
    Value<String?>? regionName,
    Value<String?>? regionNameAr,
    Value<String?>? countryCode,
    Value<String?>? timeZone,
    Value<LocationMode?>? locationMode,
    Value<PrayerMethod?>? method,
    Value<AsrMethod?>? asrMethod,
    Value<int>? hijriAdjust,
    Value<Digits>? digits,
    Value<BmThemeId>? theme,
    Value<BmThemeMode>? themeMode,
    Value<bool>? reduceMotion,
    Value<bool>? haptics,
    Value<bool>? uiSounds,
    Value<DateTime?>? firstUse,
    Value<PrayerSound>? fajrSound,
    Value<PrayerSound>? dhuhrSound,
    Value<PrayerSound>? asrSound,
    Value<PrayerSound>? maghribSound,
    Value<PrayerSound>? ishaSound,
    Value<AdhanRecording>? fajrRecording,
    Value<AdhanRecording>? dhuhrRecording,
    Value<AdhanRecording>? asrRecording,
    Value<AdhanRecording>? maghribRecording,
    Value<AdhanRecording>? ishaRecording,
    Value<PrayerTone>? fajrTone,
    Value<PrayerTone>? dhuhrTone,
    Value<PrayerTone>? asrTone,
    Value<PrayerTone>? maghribTone,
    Value<PrayerTone>? ishaTone,
    Value<int>? reminderMinutes,
    Value<bool>? notificationsAsked,
    Value<int>? tasbihDhikr,
    Value<int>? subhanallahCount,
    Value<int>? alhamdulillahCount,
    Value<int>? allahuAkbarCount,
    Value<DateTime?>? morningOpenedOn,
    Value<DateTime?>? eveningOpenedOn,
    Value<bool>? azkarNudges,
    Value<bool>? azkarVoice,
    Value<bool>? prayerCountdown,
    Value<CalendarMode>? calendarMode,
    Value<bool>? topGlow,
    Value<Language>? language,
    Value<TextSize>? textSize,
    Value<bool>? onboarded,
    Value<bool>? crashReports,
    Value<int>? lastReadSurah,
    Value<int>? lastReadAyah,
    Value<int>? lastReadPage,
    Value<DateTime?>? lastReadAt,
    Value<PageColor>? pageColor,
    Value<QuranLayout>? quranLayout,
    Value<PageTurn>? pageTurn,
    Value<bool>? keepScreenOn,
    Value<QuranFont>? quranFont,
    Value<MushafStyle>? mushafStyle,
    Value<Translation?>? translation,
    Value<bool>? adhanFlipStops,
    Value<bool>? adhanButtonsStop,
    Value<bool>? prayerSilent,
    Value<int>? prayerSilentMinutes,
    Value<int>? mushafSize,
    Value<int>? quranArabicSize,
    Value<int>? quranTranslationSize,
    Value<double>? reciteSpeed,
    Value<int>? reciteRepeat,
    Value<Reciter>? reciter,
    Value<AzkarFont>? azkarFont,
    Value<int>? recitePause,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      placeNameAr: placeNameAr ?? this.placeNameAr,
      regionName: regionName ?? this.regionName,
      regionNameAr: regionNameAr ?? this.regionNameAr,
      countryCode: countryCode ?? this.countryCode,
      timeZone: timeZone ?? this.timeZone,
      locationMode: locationMode ?? this.locationMode,
      method: method ?? this.method,
      asrMethod: asrMethod ?? this.asrMethod,
      hijriAdjust: hijriAdjust ?? this.hijriAdjust,
      digits: digits ?? this.digits,
      theme: theme ?? this.theme,
      themeMode: themeMode ?? this.themeMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      haptics: haptics ?? this.haptics,
      uiSounds: uiSounds ?? this.uiSounds,
      firstUse: firstUse ?? this.firstUse,
      fajrSound: fajrSound ?? this.fajrSound,
      dhuhrSound: dhuhrSound ?? this.dhuhrSound,
      asrSound: asrSound ?? this.asrSound,
      maghribSound: maghribSound ?? this.maghribSound,
      ishaSound: ishaSound ?? this.ishaSound,
      fajrRecording: fajrRecording ?? this.fajrRecording,
      dhuhrRecording: dhuhrRecording ?? this.dhuhrRecording,
      asrRecording: asrRecording ?? this.asrRecording,
      maghribRecording: maghribRecording ?? this.maghribRecording,
      ishaRecording: ishaRecording ?? this.ishaRecording,
      fajrTone: fajrTone ?? this.fajrTone,
      dhuhrTone: dhuhrTone ?? this.dhuhrTone,
      asrTone: asrTone ?? this.asrTone,
      maghribTone: maghribTone ?? this.maghribTone,
      ishaTone: ishaTone ?? this.ishaTone,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      notificationsAsked: notificationsAsked ?? this.notificationsAsked,
      tasbihDhikr: tasbihDhikr ?? this.tasbihDhikr,
      subhanallahCount: subhanallahCount ?? this.subhanallahCount,
      alhamdulillahCount: alhamdulillahCount ?? this.alhamdulillahCount,
      allahuAkbarCount: allahuAkbarCount ?? this.allahuAkbarCount,
      morningOpenedOn: morningOpenedOn ?? this.morningOpenedOn,
      eveningOpenedOn: eveningOpenedOn ?? this.eveningOpenedOn,
      azkarNudges: azkarNudges ?? this.azkarNudges,
      azkarVoice: azkarVoice ?? this.azkarVoice,
      prayerCountdown: prayerCountdown ?? this.prayerCountdown,
      calendarMode: calendarMode ?? this.calendarMode,
      topGlow: topGlow ?? this.topGlow,
      language: language ?? this.language,
      textSize: textSize ?? this.textSize,
      onboarded: onboarded ?? this.onboarded,
      crashReports: crashReports ?? this.crashReports,
      lastReadSurah: lastReadSurah ?? this.lastReadSurah,
      lastReadAyah: lastReadAyah ?? this.lastReadAyah,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      pageColor: pageColor ?? this.pageColor,
      quranLayout: quranLayout ?? this.quranLayout,
      pageTurn: pageTurn ?? this.pageTurn,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      quranFont: quranFont ?? this.quranFont,
      mushafStyle: mushafStyle ?? this.mushafStyle,
      translation: translation ?? this.translation,
      adhanFlipStops: adhanFlipStops ?? this.adhanFlipStops,
      adhanButtonsStop: adhanButtonsStop ?? this.adhanButtonsStop,
      prayerSilent: prayerSilent ?? this.prayerSilent,
      prayerSilentMinutes: prayerSilentMinutes ?? this.prayerSilentMinutes,
      mushafSize: mushafSize ?? this.mushafSize,
      quranArabicSize: quranArabicSize ?? this.quranArabicSize,
      quranTranslationSize: quranTranslationSize ?? this.quranTranslationSize,
      reciteSpeed: reciteSpeed ?? this.reciteSpeed,
      reciteRepeat: reciteRepeat ?? this.reciteRepeat,
      reciter: reciter ?? this.reciter,
      azkarFont: azkarFont ?? this.azkarFont,
      recitePause: recitePause ?? this.recitePause,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (placeNameAr.present) {
      map['place_name_ar'] = Variable<String>(placeNameAr.value);
    }
    if (regionName.present) {
      map['region_name'] = Variable<String>(regionName.value);
    }
    if (regionNameAr.present) {
      map['region_name_ar'] = Variable<String>(regionNameAr.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (locationMode.present) {
      map['location_mode'] = Variable<String>(
        $SettingsTable.$converterlocationModen.toSql(locationMode.value),
      );
    }
    if (method.present) {
      map['method'] = Variable<String>($SettingsTable.$convertermethodn.toSql(method.value));
    }
    if (asrMethod.present) {
      map['asr_method'] = Variable<String>(
        $SettingsTable.$converterasrMethodn.toSql(asrMethod.value),
      );
    }
    if (hijriAdjust.present) {
      map['hijri_adjust'] = Variable<int>(hijriAdjust.value);
    }
    if (digits.present) {
      map['digits'] = Variable<String>($SettingsTable.$converterdigits.toSql(digits.value));
    }
    if (theme.present) {
      map['theme'] = Variable<String>($SettingsTable.$convertertheme.toSql(theme.value));
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(
        $SettingsTable.$converterthemeMode.toSql(themeMode.value),
      );
    }
    if (reduceMotion.present) {
      map['reduce_motion'] = Variable<bool>(reduceMotion.value);
    }
    if (haptics.present) {
      map['haptics'] = Variable<bool>(haptics.value);
    }
    if (uiSounds.present) {
      map['ui_sounds'] = Variable<bool>(uiSounds.value);
    }
    if (firstUse.present) {
      map['first_use'] = Variable<String>($SettingsTable.$converterfirstUsen.toSql(firstUse.value));
    }
    if (fajrSound.present) {
      map['fajr_sound'] = Variable<String>(
        $SettingsTable.$converterfajrSound.toSql(fajrSound.value),
      );
    }
    if (dhuhrSound.present) {
      map['dhuhr_sound'] = Variable<String>(
        $SettingsTable.$converterdhuhrSound.toSql(dhuhrSound.value),
      );
    }
    if (asrSound.present) {
      map['asr_sound'] = Variable<String>($SettingsTable.$converterasrSound.toSql(asrSound.value));
    }
    if (maghribSound.present) {
      map['maghrib_sound'] = Variable<String>(
        $SettingsTable.$convertermaghribSound.toSql(maghribSound.value),
      );
    }
    if (ishaSound.present) {
      map['isha_sound'] = Variable<String>(
        $SettingsTable.$converterishaSound.toSql(ishaSound.value),
      );
    }
    if (fajrRecording.present) {
      map['fajr_recording'] = Variable<String>(
        $SettingsTable.$converterfajrRecording.toSql(fajrRecording.value),
      );
    }
    if (dhuhrRecording.present) {
      map['dhuhr_recording'] = Variable<String>(
        $SettingsTable.$converterdhuhrRecording.toSql(dhuhrRecording.value),
      );
    }
    if (asrRecording.present) {
      map['asr_recording'] = Variable<String>(
        $SettingsTable.$converterasrRecording.toSql(asrRecording.value),
      );
    }
    if (maghribRecording.present) {
      map['maghrib_recording'] = Variable<String>(
        $SettingsTable.$convertermaghribRecording.toSql(maghribRecording.value),
      );
    }
    if (ishaRecording.present) {
      map['isha_recording'] = Variable<String>(
        $SettingsTable.$converterishaRecording.toSql(ishaRecording.value),
      );
    }
    if (fajrTone.present) {
      map['fajr_tone'] = Variable<String>($SettingsTable.$converterfajrTone.toSql(fajrTone.value));
    }
    if (dhuhrTone.present) {
      map['dhuhr_tone'] = Variable<String>(
        $SettingsTable.$converterdhuhrTone.toSql(dhuhrTone.value),
      );
    }
    if (asrTone.present) {
      map['asr_tone'] = Variable<String>($SettingsTable.$converterasrTone.toSql(asrTone.value));
    }
    if (maghribTone.present) {
      map['maghrib_tone'] = Variable<String>(
        $SettingsTable.$convertermaghribTone.toSql(maghribTone.value),
      );
    }
    if (ishaTone.present) {
      map['isha_tone'] = Variable<String>($SettingsTable.$converterishaTone.toSql(ishaTone.value));
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (notificationsAsked.present) {
      map['notifications_asked'] = Variable<bool>(notificationsAsked.value);
    }
    if (tasbihDhikr.present) {
      map['tasbih_dhikr'] = Variable<int>(tasbihDhikr.value);
    }
    if (subhanallahCount.present) {
      map['subhanallah_count'] = Variable<int>(subhanallahCount.value);
    }
    if (alhamdulillahCount.present) {
      map['alhamdulillah_count'] = Variable<int>(alhamdulillahCount.value);
    }
    if (allahuAkbarCount.present) {
      map['allahu_akbar_count'] = Variable<int>(allahuAkbarCount.value);
    }
    if (morningOpenedOn.present) {
      map['morning_opened_on'] = Variable<String>(
        $SettingsTable.$convertermorningOpenedOnn.toSql(morningOpenedOn.value),
      );
    }
    if (eveningOpenedOn.present) {
      map['evening_opened_on'] = Variable<String>(
        $SettingsTable.$convertereveningOpenedOnn.toSql(eveningOpenedOn.value),
      );
    }
    if (azkarNudges.present) {
      map['azkar_nudges'] = Variable<bool>(azkarNudges.value);
    }
    if (azkarVoice.present) {
      map['azkar_voice'] = Variable<bool>(azkarVoice.value);
    }
    if (prayerCountdown.present) {
      map['prayer_countdown'] = Variable<bool>(prayerCountdown.value);
    }
    if (calendarMode.present) {
      map['calendar_mode'] = Variable<String>(
        $SettingsTable.$convertercalendarMode.toSql(calendarMode.value),
      );
    }
    if (topGlow.present) {
      map['top_glow'] = Variable<bool>(topGlow.value);
    }
    if (language.present) {
      map['language'] = Variable<String>($SettingsTable.$converterlanguage.toSql(language.value));
    }
    if (textSize.present) {
      map['text_size'] = Variable<String>($SettingsTable.$convertertextSize.toSql(textSize.value));
    }
    if (onboarded.present) {
      map['onboarded'] = Variable<bool>(onboarded.value);
    }
    if (crashReports.present) {
      map['crash_reports'] = Variable<bool>(crashReports.value);
    }
    if (lastReadSurah.present) {
      map['last_read_surah'] = Variable<int>(lastReadSurah.value);
    }
    if (lastReadAyah.present) {
      map['last_read_ayah'] = Variable<int>(lastReadAyah.value);
    }
    if (lastReadPage.present) {
      map['last_read_page'] = Variable<int>(lastReadPage.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (pageColor.present) {
      map['page_color'] = Variable<String>(
        $SettingsTable.$converterpageColor.toSql(pageColor.value),
      );
    }
    if (quranLayout.present) {
      map['quran_layout'] = Variable<String>(
        $SettingsTable.$converterquranLayout.toSql(quranLayout.value),
      );
    }
    if (pageTurn.present) {
      map['page_turn'] = Variable<String>($SettingsTable.$converterpageTurn.toSql(pageTurn.value));
    }
    if (keepScreenOn.present) {
      map['keep_screen_on'] = Variable<bool>(keepScreenOn.value);
    }
    if (quranFont.present) {
      map['quran_font'] = Variable<String>(
        $SettingsTable.$converterquranFont.toSql(quranFont.value),
      );
    }
    if (mushafStyle.present) {
      map['mushaf_style'] = Variable<String>(
        $SettingsTable.$convertermushafStyle.toSql(mushafStyle.value),
      );
    }
    if (translation.present) {
      map['translation'] = Variable<String>(
        $SettingsTable.$convertertranslationn.toSql(translation.value),
      );
    }
    if (adhanFlipStops.present) {
      map['adhan_flip_stops'] = Variable<bool>(adhanFlipStops.value);
    }
    if (adhanButtonsStop.present) {
      map['adhan_buttons_stop'] = Variable<bool>(adhanButtonsStop.value);
    }
    if (prayerSilent.present) {
      map['prayer_silent'] = Variable<bool>(prayerSilent.value);
    }
    if (prayerSilentMinutes.present) {
      map['prayer_silent_minutes'] = Variable<int>(prayerSilentMinutes.value);
    }
    if (mushafSize.present) {
      map['mushaf_size'] = Variable<int>(mushafSize.value);
    }
    if (quranArabicSize.present) {
      map['quran_arabic_size'] = Variable<int>(quranArabicSize.value);
    }
    if (quranTranslationSize.present) {
      map['quran_translation_size'] = Variable<int>(quranTranslationSize.value);
    }
    if (reciteSpeed.present) {
      map['recite_speed'] = Variable<double>(reciteSpeed.value);
    }
    if (reciteRepeat.present) {
      map['recite_repeat'] = Variable<int>(reciteRepeat.value);
    }
    if (reciter.present) {
      map['reciter'] = Variable<String>($SettingsTable.$converterreciter.toSql(reciter.value));
    }
    if (azkarFont.present) {
      map['azkar_font'] = Variable<String>(
        $SettingsTable.$converterazkarFont.toSql(azkarFont.value),
      );
    }
    if (recitePause.present) {
      map['recite_pause'] = Variable<int>(recitePause.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeName: $placeName, ')
          ..write('placeNameAr: $placeNameAr, ')
          ..write('regionName: $regionName, ')
          ..write('regionNameAr: $regionNameAr, ')
          ..write('countryCode: $countryCode, ')
          ..write('timeZone: $timeZone, ')
          ..write('locationMode: $locationMode, ')
          ..write('method: $method, ')
          ..write('asrMethod: $asrMethod, ')
          ..write('hijriAdjust: $hijriAdjust, ')
          ..write('digits: $digits, ')
          ..write('theme: $theme, ')
          ..write('themeMode: $themeMode, ')
          ..write('reduceMotion: $reduceMotion, ')
          ..write('haptics: $haptics, ')
          ..write('uiSounds: $uiSounds, ')
          ..write('firstUse: $firstUse, ')
          ..write('fajrSound: $fajrSound, ')
          ..write('dhuhrSound: $dhuhrSound, ')
          ..write('asrSound: $asrSound, ')
          ..write('maghribSound: $maghribSound, ')
          ..write('ishaSound: $ishaSound, ')
          ..write('fajrRecording: $fajrRecording, ')
          ..write('dhuhrRecording: $dhuhrRecording, ')
          ..write('asrRecording: $asrRecording, ')
          ..write('maghribRecording: $maghribRecording, ')
          ..write('ishaRecording: $ishaRecording, ')
          ..write('fajrTone: $fajrTone, ')
          ..write('dhuhrTone: $dhuhrTone, ')
          ..write('asrTone: $asrTone, ')
          ..write('maghribTone: $maghribTone, ')
          ..write('ishaTone: $ishaTone, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('notificationsAsked: $notificationsAsked, ')
          ..write('tasbihDhikr: $tasbihDhikr, ')
          ..write('subhanallahCount: $subhanallahCount, ')
          ..write('alhamdulillahCount: $alhamdulillahCount, ')
          ..write('allahuAkbarCount: $allahuAkbarCount, ')
          ..write('morningOpenedOn: $morningOpenedOn, ')
          ..write('eveningOpenedOn: $eveningOpenedOn, ')
          ..write('azkarNudges: $azkarNudges, ')
          ..write('azkarVoice: $azkarVoice, ')
          ..write('prayerCountdown: $prayerCountdown, ')
          ..write('calendarMode: $calendarMode, ')
          ..write('topGlow: $topGlow, ')
          ..write('language: $language, ')
          ..write('textSize: $textSize, ')
          ..write('onboarded: $onboarded, ')
          ..write('crashReports: $crashReports, ')
          ..write('lastReadSurah: $lastReadSurah, ')
          ..write('lastReadAyah: $lastReadAyah, ')
          ..write('lastReadPage: $lastReadPage, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('pageColor: $pageColor, ')
          ..write('quranLayout: $quranLayout, ')
          ..write('pageTurn: $pageTurn, ')
          ..write('keepScreenOn: $keepScreenOn, ')
          ..write('quranFont: $quranFont, ')
          ..write('mushafStyle: $mushafStyle, ')
          ..write('translation: $translation, ')
          ..write('adhanFlipStops: $adhanFlipStops, ')
          ..write('adhanButtonsStop: $adhanButtonsStop, ')
          ..write('prayerSilent: $prayerSilent, ')
          ..write('prayerSilentMinutes: $prayerSilentMinutes, ')
          ..write('mushafSize: $mushafSize, ')
          ..write('quranArabicSize: $quranArabicSize, ')
          ..write('quranTranslationSize: $quranTranslationSize, ')
          ..write('reciteSpeed: $reciteSpeed, ')
          ..write('reciteRepeat: $reciteRepeat, ')
          ..write('reciter: $reciter, ')
          ..write('azkarFont: $azkarFont, ')
          ..write('recitePause: $recitePause')
          ..write(')'))
        .toString();
  }
}

class $PrayerLogTable extends PrayerLog with TableInfo<$PrayerLogTable, PrayerLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerLogTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($PrayerLogTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<Prayer, String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Prayer>($PrayerLogTable.$converterprayer);
  @override
  List<GeneratedColumn> get $columns => [date, prayer];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_log';
  @override
  Set<GeneratedColumn> get $primaryKey => {date, prayer};
  @override
  PrayerLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerLogData(
      date: $PrayerLogTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      ),
      prayer: $PrayerLogTable.$converterprayer.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}prayer'])!,
      ),
    );
  }

  @override
  $PrayerLogTable createAlias(String alias) {
    return $PrayerLogTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterdate = const CivilDate();
  static JsonTypeConverter2<Prayer, String, String> $converterprayer =
      const EnumNameConverter<Prayer>(Prayer.values);
}

class PrayerLogData extends DataClass implements Insertable<PrayerLogData> {
  /// the prayer day the prayer belongs to, not the clock time it was marked
  final DateTime date;
  final Prayer prayer;
  const PrayerLogData({required this.date, required this.prayer});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['date'] = Variable<String>($PrayerLogTable.$converterdate.toSql(date));
    }
    {
      map['prayer'] = Variable<String>($PrayerLogTable.$converterprayer.toSql(prayer));
    }
    return map;
  }

  PrayerLogCompanion toCompanion(bool nullToAbsent) {
    return PrayerLogCompanion(date: Value(date), prayer: Value(prayer));
  }

  factory PrayerLogData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerLogData(
      date: serializer.fromJson<DateTime>(json['date']),
      prayer: $PrayerLogTable.$converterprayer.fromJson(
        serializer.fromJson<String>(json['prayer']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'prayer': serializer.toJson<String>($PrayerLogTable.$converterprayer.toJson(prayer)),
    };
  }

  PrayerLogData copyWith({DateTime? date, Prayer? prayer}) =>
      PrayerLogData(date: date ?? this.date, prayer: prayer ?? this.prayer);
  PrayerLogData copyWithCompanion(PrayerLogCompanion data) {
    return PrayerLogData(
      date: data.date.present ? data.date.value : this.date,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogData(')
          ..write('date: $date, ')
          ..write('prayer: $prayer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, prayer);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerLogData && other.date == this.date && other.prayer == this.prayer);
}

class PrayerLogCompanion extends UpdateCompanion<PrayerLogData> {
  final Value<DateTime> date;
  final Value<Prayer> prayer;
  final Value<int> rowid;
  const PrayerLogCompanion({
    this.date = const Value.absent(),
    this.prayer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerLogCompanion.insert({
    required DateTime date,
    required Prayer prayer,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       prayer = Value(prayer);
  static Insertable<PrayerLogData> custom({
    Expression<String>? date,
    Expression<String>? prayer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (prayer != null) 'prayer': prayer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerLogCompanion copyWith({Value<DateTime>? date, Value<Prayer>? prayer, Value<int>? rowid}) {
    return PrayerLogCompanion(
      date: date ?? this.date,
      prayer: prayer ?? this.prayer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>($PrayerLogTable.$converterdate.toSql(date.value));
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>($PrayerLogTable.$converterprayer.toSql(prayer.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogCompanion(')
          ..write('date: $date, ')
          ..write('prayer: $prayer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QadaEntriesTable extends QadaEntries with TableInfo<$QadaEntriesTable, QadaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QadaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Prayer, String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Prayer>($QadaEntriesTable.$converterprayer);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> missedOn = GeneratedColumn<String>(
    'missed_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($QadaEntriesTable.$convertermissedOnn);
  static const VerificationMeta _madeUpAtMeta = const VerificationMeta('madeUpAt');
  @override
  late final GeneratedColumn<DateTime> madeUpAt = GeneratedColumn<DateTime>(
    'made_up_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, prayer, missedOn, madeUpAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qada_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QadaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('made_up_at')) {
      context.handle(
        _madeUpAtMeta,
        madeUpAt.isAcceptableOrUnknown(data['made_up_at']!, _madeUpAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QadaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QadaEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      prayer: $QadaEntriesTable.$converterprayer.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}prayer'])!,
      ),
      missedOn: $QadaEntriesTable.$convertermissedOnn.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}missed_on']),
      ),
      madeUpAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}made_up_at'],
      ),
    );
  }

  @override
  $QadaEntriesTable createAlias(String alias) {
    return $QadaEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Prayer, String, String> $converterprayer =
      const EnumNameConverter<Prayer>(Prayer.values);
  static TypeConverter<DateTime, String> $convertermissedOn = const CivilDate();
  static TypeConverter<DateTime?, String?> $convertermissedOnn = NullAwareTypeConverter.wrap(
    $convertermissedOn,
  );
}

class QadaEntry extends DataClass implements Insertable<QadaEntry> {
  final int id;
  final Prayer prayer;

  /// null = missed before using the app
  final DateTime? missedOn;

  /// null = still open
  final DateTime? madeUpAt;
  const QadaEntry({required this.id, required this.prayer, this.missedOn, this.madeUpAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['prayer'] = Variable<String>($QadaEntriesTable.$converterprayer.toSql(prayer));
    }
    if (!nullToAbsent || missedOn != null) {
      map['missed_on'] = Variable<String>($QadaEntriesTable.$convertermissedOnn.toSql(missedOn));
    }
    if (!nullToAbsent || madeUpAt != null) {
      map['made_up_at'] = Variable<DateTime>(madeUpAt);
    }
    return map;
  }

  QadaEntriesCompanion toCompanion(bool nullToAbsent) {
    return QadaEntriesCompanion(
      id: Value(id),
      prayer: Value(prayer),
      missedOn: missedOn == null && nullToAbsent ? const Value.absent() : Value(missedOn),
      madeUpAt: madeUpAt == null && nullToAbsent ? const Value.absent() : Value(madeUpAt),
    );
  }

  factory QadaEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QadaEntry(
      id: serializer.fromJson<int>(json['id']),
      prayer: $QadaEntriesTable.$converterprayer.fromJson(
        serializer.fromJson<String>(json['prayer']),
      ),
      missedOn: serializer.fromJson<DateTime?>(json['missedOn']),
      madeUpAt: serializer.fromJson<DateTime?>(json['madeUpAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prayer': serializer.toJson<String>($QadaEntriesTable.$converterprayer.toJson(prayer)),
      'missedOn': serializer.toJson<DateTime?>(missedOn),
      'madeUpAt': serializer.toJson<DateTime?>(madeUpAt),
    };
  }

  QadaEntry copyWith({
    int? id,
    Prayer? prayer,
    Value<DateTime?> missedOn = const Value.absent(),
    Value<DateTime?> madeUpAt = const Value.absent(),
  }) => QadaEntry(
    id: id ?? this.id,
    prayer: prayer ?? this.prayer,
    missedOn: missedOn.present ? missedOn.value : this.missedOn,
    madeUpAt: madeUpAt.present ? madeUpAt.value : this.madeUpAt,
  );
  QadaEntry copyWithCompanion(QadaEntriesCompanion data) {
    return QadaEntry(
      id: data.id.present ? data.id.value : this.id,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      missedOn: data.missedOn.present ? data.missedOn.value : this.missedOn,
      madeUpAt: data.madeUpAt.present ? data.madeUpAt.value : this.madeUpAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QadaEntry(')
          ..write('id: $id, ')
          ..write('prayer: $prayer, ')
          ..write('missedOn: $missedOn, ')
          ..write('madeUpAt: $madeUpAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, prayer, missedOn, madeUpAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QadaEntry &&
          other.id == this.id &&
          other.prayer == this.prayer &&
          other.missedOn == this.missedOn &&
          other.madeUpAt == this.madeUpAt);
}

class QadaEntriesCompanion extends UpdateCompanion<QadaEntry> {
  final Value<int> id;
  final Value<Prayer> prayer;
  final Value<DateTime?> missedOn;
  final Value<DateTime?> madeUpAt;
  const QadaEntriesCompanion({
    this.id = const Value.absent(),
    this.prayer = const Value.absent(),
    this.missedOn = const Value.absent(),
    this.madeUpAt = const Value.absent(),
  });
  QadaEntriesCompanion.insert({
    this.id = const Value.absent(),
    required Prayer prayer,
    this.missedOn = const Value.absent(),
    this.madeUpAt = const Value.absent(),
  }) : prayer = Value(prayer);
  static Insertable<QadaEntry> custom({
    Expression<int>? id,
    Expression<String>? prayer,
    Expression<String>? missedOn,
    Expression<DateTime>? madeUpAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prayer != null) 'prayer': prayer,
      if (missedOn != null) 'missed_on': missedOn,
      if (madeUpAt != null) 'made_up_at': madeUpAt,
    });
  }

  QadaEntriesCompanion copyWith({
    Value<int>? id,
    Value<Prayer>? prayer,
    Value<DateTime?>? missedOn,
    Value<DateTime?>? madeUpAt,
  }) {
    return QadaEntriesCompanion(
      id: id ?? this.id,
      prayer: prayer ?? this.prayer,
      missedOn: missedOn ?? this.missedOn,
      madeUpAt: madeUpAt ?? this.madeUpAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>($QadaEntriesTable.$converterprayer.toSql(prayer.value));
    }
    if (missedOn.present) {
      map['missed_on'] = Variable<String>(
        $QadaEntriesTable.$convertermissedOnn.toSql(missedOn.value),
      );
    }
    if (madeUpAt.present) {
      map['made_up_at'] = Variable<DateTime>(madeUpAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QadaEntriesCompanion(')
          ..write('id: $id, ')
          ..write('prayer: $prayer, ')
          ..write('missedOn: $missedOn, ')
          ..write('madeUpAt: $madeUpAt')
          ..write(')'))
        .toString();
  }
}

class $AzkarCountsTable extends AzkarCounts with TableInfo<$AzkarCountsTable, AzkarCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AzkarCountsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<AzkarSet, String> setId = GeneratedColumn<String>(
    'set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AzkarSet>($AzkarCountsTable.$convertersetId);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($AzkarCountsTable.$converterday);
  static const VerificationMeta _zikrMeta = const VerificationMeta('zikr');
  @override
  late final GeneratedColumn<String> zikr = GeneratedColumn<String>(
    'zikr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [setId, day, zikr, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'azkar_counts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AzkarCount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('zikr')) {
      context.handle(_zikrMeta, zikr.isAcceptableOrUnknown(data['zikr']!, _zikrMeta));
    } else if (isInserting) {
      context.missing(_zikrMeta);
    }
    if (data.containsKey('count')) {
      context.handle(_countMeta, count.isAcceptableOrUnknown(data['count']!, _countMeta));
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setId, day, zikr};
  @override
  AzkarCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AzkarCount(
      setId: $AzkarCountsTable.$convertersetId.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      ),
      day: $AzkarCountsTable.$converterday.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      ),
      zikr: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}zikr'])!,
      count: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}count'])!,
    );
  }

  @override
  $AzkarCountsTable createAlias(String alias) {
    return $AzkarCountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AzkarSet, String, String> $convertersetId =
      const EnumNameConverter<AzkarSet>(AzkarSet.values);
  static TypeConverter<DateTime, String> $converterday = const CivilDate();
}

class AzkarCount extends DataClass implements Insertable<AzkarCount> {
  final AzkarSet setId;

  /// the window's prayer day
  final DateTime day;

  /// the item's id in azkar.json
  final String zikr;
  final int count;
  const AzkarCount({
    required this.setId,
    required this.day,
    required this.zikr,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['set_id'] = Variable<String>($AzkarCountsTable.$convertersetId.toSql(setId));
    }
    {
      map['day'] = Variable<String>($AzkarCountsTable.$converterday.toSql(day));
    }
    map['zikr'] = Variable<String>(zikr);
    map['count'] = Variable<int>(count);
    return map;
  }

  AzkarCountsCompanion toCompanion(bool nullToAbsent) {
    return AzkarCountsCompanion(
      setId: Value(setId),
      day: Value(day),
      zikr: Value(zikr),
      count: Value(count),
    );
  }

  factory AzkarCount.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AzkarCount(
      setId: $AzkarCountsTable.$convertersetId.fromJson(serializer.fromJson<String>(json['setId'])),
      day: serializer.fromJson<DateTime>(json['day']),
      zikr: serializer.fromJson<String>(json['zikr']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setId': serializer.toJson<String>($AzkarCountsTable.$convertersetId.toJson(setId)),
      'day': serializer.toJson<DateTime>(day),
      'zikr': serializer.toJson<String>(zikr),
      'count': serializer.toJson<int>(count),
    };
  }

  AzkarCount copyWith({AzkarSet? setId, DateTime? day, String? zikr, int? count}) => AzkarCount(
    setId: setId ?? this.setId,
    day: day ?? this.day,
    zikr: zikr ?? this.zikr,
    count: count ?? this.count,
  );
  AzkarCount copyWithCompanion(AzkarCountsCompanion data) {
    return AzkarCount(
      setId: data.setId.present ? data.setId.value : this.setId,
      day: data.day.present ? data.day.value : this.day,
      zikr: data.zikr.present ? data.zikr.value : this.zikr,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AzkarCount(')
          ..write('setId: $setId, ')
          ..write('day: $day, ')
          ..write('zikr: $zikr, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setId, day, zikr, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AzkarCount &&
          other.setId == this.setId &&
          other.day == this.day &&
          other.zikr == this.zikr &&
          other.count == this.count);
}

class AzkarCountsCompanion extends UpdateCompanion<AzkarCount> {
  final Value<AzkarSet> setId;
  final Value<DateTime> day;
  final Value<String> zikr;
  final Value<int> count;
  final Value<int> rowid;
  const AzkarCountsCompanion({
    this.setId = const Value.absent(),
    this.day = const Value.absent(),
    this.zikr = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AzkarCountsCompanion.insert({
    required AzkarSet setId,
    required DateTime day,
    required String zikr,
    required int count,
    this.rowid = const Value.absent(),
  }) : setId = Value(setId),
       day = Value(day),
       zikr = Value(zikr),
       count = Value(count);
  static Insertable<AzkarCount> custom({
    Expression<String>? setId,
    Expression<String>? day,
    Expression<String>? zikr,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setId != null) 'set_id': setId,
      if (day != null) 'day': day,
      if (zikr != null) 'zikr': zikr,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AzkarCountsCompanion copyWith({
    Value<AzkarSet>? setId,
    Value<DateTime>? day,
    Value<String>? zikr,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return AzkarCountsCompanion(
      setId: setId ?? this.setId,
      day: day ?? this.day,
      zikr: zikr ?? this.zikr,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setId.present) {
      map['set_id'] = Variable<String>($AzkarCountsTable.$convertersetId.toSql(setId.value));
    }
    if (day.present) {
      map['day'] = Variable<String>($AzkarCountsTable.$converterday.toSql(day.value));
    }
    if (zikr.present) {
      map['zikr'] = Variable<String>(zikr.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AzkarCountsCompanion(')
          ..write('setId: $setId, ')
          ..write('day: $day, ')
          ..write('zikr: $zikr, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedDuasTable extends SavedDuas with TableInfo<$SavedDuasTable, SavedDua> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedDuasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _duaMeta = const VerificationMeta('dua');
  @override
  late final GeneratedColumn<String> dua = GeneratedColumn<String>(
    'dua',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dua, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_duas';
  @override
  VerificationContext validateIntegrity(Insertable<SavedDua> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dua')) {
      context.handle(_duaMeta, dua.isAcceptableOrUnknown(data['dua']!, _duaMeta));
    } else if (isInserting) {
      context.missing(_duaMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dua};
  @override
  SavedDua map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedDua(
      dua: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}dua'])!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedDuasTable createAlias(String alias) {
    return $SavedDuasTable(attachedDatabase, alias);
  }
}

class SavedDua extends DataClass implements Insertable<SavedDua> {
  /// the dua's id in duas.json
  final String dua;
  final DateTime savedAt;
  const SavedDua({required this.dua, required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dua'] = Variable<String>(dua);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedDuasCompanion toCompanion(bool nullToAbsent) {
    return SavedDuasCompanion(dua: Value(dua), savedAt: Value(savedAt));
  }

  factory SavedDua.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedDua(
      dua: serializer.fromJson<String>(json['dua']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dua': serializer.toJson<String>(dua),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedDua copyWith({String? dua, DateTime? savedAt}) =>
      SavedDua(dua: dua ?? this.dua, savedAt: savedAt ?? this.savedAt);
  SavedDua copyWithCompanion(SavedDuasCompanion data) {
    return SavedDua(
      dua: data.dua.present ? data.dua.value : this.dua,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedDua(')
          ..write('dua: $dua, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dua, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedDua && other.dua == this.dua && other.savedAt == this.savedAt);
}

class SavedDuasCompanion extends UpdateCompanion<SavedDua> {
  final Value<String> dua;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedDuasCompanion({
    this.dua = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedDuasCompanion.insert({
    required String dua,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : dua = Value(dua),
       savedAt = Value(savedAt);
  static Insertable<SavedDua> custom({
    Expression<String>? dua,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dua != null) 'dua': dua,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedDuasCompanion copyWith({Value<String>? dua, Value<DateTime>? savedAt, Value<int>? rowid}) {
    return SavedDuasCompanion(
      dua: dua ?? this.dua,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dua.present) {
      map['dua'] = Variable<String>(dua.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedDuasCompanion(')
          ..write('dua: $dua, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuranCategoriesTable extends QuranCategories
    with TableInfo<$QuranCategoriesTable, QuranCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryColor, String> color =
      GeneratedColumn<String>(
        'color',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryColor>($QuranCategoriesTable.$convertercolor);
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranCategory(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name']),
      color: $QuranCategoriesTable.$convertercolor.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $QuranCategoriesTable createAlias(String alias) {
    return $QuranCategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryColor, String, String> $convertercolor =
      const EnumNameConverter<CategoryColor>(CategoryColor.values);
}

class QuranCategory extends DataClass implements Insertable<QuranCategory> {
  final int id;

  /// null on the default shows "Bookmarks" in the app's language
  final String? name;
  final CategoryColor color;
  final int position;
  const QuranCategory({required this.id, this.name, required this.color, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    {
      map['color'] = Variable<String>($QuranCategoriesTable.$convertercolor.toSql(color));
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  QuranCategoriesCompanion toCompanion(bool nullToAbsent) {
    return QuranCategoriesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      color: Value(color),
      position: Value(position),
    );
  }

  factory QuranCategory.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      color: $QuranCategoriesTable.$convertercolor.fromJson(
        serializer.fromJson<String>(json['color']),
      ),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'color': serializer.toJson<String>($QuranCategoriesTable.$convertercolor.toJson(color)),
      'position': serializer.toJson<int>(position),
    };
  }

  QuranCategory copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    CategoryColor? color,
    int? position,
  }) => QuranCategory(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    color: color ?? this.color,
    position: position ?? this.position,
  );
  QuranCategory copyWithCompanion(QuranCategoriesCompanion data) {
    return QuranCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.position == this.position);
}

class QuranCategoriesCompanion extends UpdateCompanion<QuranCategory> {
  final Value<int> id;
  final Value<String?> name;
  final Value<CategoryColor> color;
  final Value<int> position;
  const QuranCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.position = const Value.absent(),
  });
  QuranCategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required CategoryColor color,
    required int position,
  }) : color = Value(color),
       position = Value(position);
  static Insertable<QuranCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (position != null) 'position': position,
    });
  }

  QuranCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<CategoryColor>? color,
    Value<int>? position,
  }) {
    return QuranCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>($QuranCategoriesTable.$convertercolor.toSql(color.value));
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $QuranBookmarksTable extends QuranBookmarks
    with TableInfo<$QuranBookmarksTable, QuranBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    check: () => ComparableExpr(page).isBetweenValues(1, 604),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, surah, ayah, page, name, category, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(_surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    }
    if (data.containsKey('ayah')) {
      context.handle(_ayahMeta, ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta));
    }
    if (data.containsKey('page')) {
      context.handle(_pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuranBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranBookmark(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      surah: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}surah']),
      ayah: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ayah']),
      page: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name']),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuranBookmarksTable createAlias(String alias) {
    return $QuranBookmarksTable(attachedDatabase, alias);
  }
}

class QuranBookmark extends DataClass implements Insertable<QuranBookmark> {
  final int id;

  /// null for a page bookmark
  final int? surah;
  final int? ayah;

  /// always set, the ayah's page for an ayah bookmark
  final int page;

  /// null shows the reference
  final String? name;
  final int category;
  final DateTime createdAt;
  const QuranBookmark({
    required this.id,
    this.surah,
    this.ayah,
    required this.page,
    this.name,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || surah != null) {
      map['surah'] = Variable<int>(surah);
    }
    if (!nullToAbsent || ayah != null) {
      map['ayah'] = Variable<int>(ayah);
    }
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['category'] = Variable<int>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuranBookmarksCompanion toCompanion(bool nullToAbsent) {
    return QuranBookmarksCompanion(
      id: Value(id),
      surah: surah == null && nullToAbsent ? const Value.absent() : Value(surah),
      ayah: ayah == null && nullToAbsent ? const Value.absent() : Value(ayah),
      page: Value(page),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory QuranBookmark.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranBookmark(
      id: serializer.fromJson<int>(json['id']),
      surah: serializer.fromJson<int?>(json['surah']),
      ayah: serializer.fromJson<int?>(json['ayah']),
      page: serializer.fromJson<int>(json['page']),
      name: serializer.fromJson<String?>(json['name']),
      category: serializer.fromJson<int>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surah': serializer.toJson<int?>(surah),
      'ayah': serializer.toJson<int?>(ayah),
      'page': serializer.toJson<int>(page),
      'name': serializer.toJson<String?>(name),
      'category': serializer.toJson<int>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuranBookmark copyWith({
    int? id,
    Value<int?> surah = const Value.absent(),
    Value<int?> ayah = const Value.absent(),
    int? page,
    Value<String?> name = const Value.absent(),
    int? category,
    DateTime? createdAt,
  }) => QuranBookmark(
    id: id ?? this.id,
    surah: surah.present ? surah.value : this.surah,
    ayah: ayah.present ? ayah.value : this.ayah,
    page: page ?? this.page,
    name: name.present ? name.value : this.name,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  QuranBookmark copyWithCompanion(QuranBookmarksCompanion data) {
    return QuranBookmark(
      id: data.id.present ? data.id.value : this.id,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      page: data.page.present ? data.page.value : this.page,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranBookmark(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surah, ayah, page, name, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranBookmark &&
          other.id == this.id &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.page == this.page &&
          other.name == this.name &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class QuranBookmarksCompanion extends UpdateCompanion<QuranBookmark> {
  final Value<int> id;
  final Value<int?> surah;
  final Value<int?> ayah;
  final Value<int> page;
  final Value<String?> name;
  final Value<int> category;
  final Value<DateTime> createdAt;
  const QuranBookmarksCompanion({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.page = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuranBookmarksCompanion.insert({
    this.id = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    required int page,
    this.name = const Value.absent(),
    required int category,
    required DateTime createdAt,
  }) : page = Value(page),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<QuranBookmark> custom({
    Expression<int>? id,
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<int>? page,
    Expression<String>? name,
    Expression<int>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (page != null) 'page': page,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuranBookmarksCompanion copyWith({
    Value<int>? id,
    Value<int?>? surah,
    Value<int?>? ayah,
    Value<int>? page,
    Value<String?>? name,
    Value<int>? category,
    Value<DateTime>? createdAt,
  }) {
    return QuranBookmarksCompanion(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      name: name ?? this.name,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('page: $page, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuranNotesTable extends QuranNotes with TableInfo<$QuranNotesTable, QuranNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highlightMeta = const VerificationMeta('highlight');
  @override
  late final GeneratedColumn<bool> highlight = GeneratedColumn<bool>(
    'highlight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("highlight" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [surah, ayah, note, highlight, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah')) {
      context.handle(_surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    } else if (isInserting) {
      context.missing(_surahMeta);
    }
    if (data.containsKey('ayah')) {
      context.handle(_ayahMeta, ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta));
    } else if (isInserting) {
      context.missing(_ayahMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('highlight')) {
      context.handle(
        _highlightMeta,
        highlight.isAcceptableOrUnknown(data['highlight']!, _highlightMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surah, ayah};
  @override
  QuranNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranNote(
      surah: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}surah'])!,
      ayah: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ayah'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      highlight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}highlight'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuranNotesTable createAlias(String alias) {
    return $QuranNotesTable(attachedDatabase, alias);
  }
}

class QuranNote extends DataClass implements Insertable<QuranNote> {
  final int surah;
  final int ayah;
  final String note;
  final bool highlight;
  final DateTime updatedAt;
  const QuranNote({
    required this.surah,
    required this.ayah,
    required this.note,
    required this.highlight,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah'] = Variable<int>(surah);
    map['ayah'] = Variable<int>(ayah);
    map['note'] = Variable<String>(note);
    map['highlight'] = Variable<bool>(highlight);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuranNotesCompanion toCompanion(bool nullToAbsent) {
    return QuranNotesCompanion(
      surah: Value(surah),
      ayah: Value(ayah),
      note: Value(note),
      highlight: Value(highlight),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuranNote.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranNote(
      surah: serializer.fromJson<int>(json['surah']),
      ayah: serializer.fromJson<int>(json['ayah']),
      note: serializer.fromJson<String>(json['note']),
      highlight: serializer.fromJson<bool>(json['highlight']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surah': serializer.toJson<int>(surah),
      'ayah': serializer.toJson<int>(ayah),
      'note': serializer.toJson<String>(note),
      'highlight': serializer.toJson<bool>(highlight),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuranNote copyWith({int? surah, int? ayah, String? note, bool? highlight, DateTime? updatedAt}) =>
      QuranNote(
        surah: surah ?? this.surah,
        ayah: ayah ?? this.ayah,
        note: note ?? this.note,
        highlight: highlight ?? this.highlight,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  QuranNote copyWithCompanion(QuranNotesCompanion data) {
    return QuranNote(
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
      note: data.note.present ? data.note.value : this.note,
      highlight: data.highlight.present ? data.highlight.value : this.highlight,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranNote(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('note: $note, ')
          ..write('highlight: $highlight, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surah, ayah, note, highlight, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranNote &&
          other.surah == this.surah &&
          other.ayah == this.ayah &&
          other.note == this.note &&
          other.highlight == this.highlight &&
          other.updatedAt == this.updatedAt);
}

class QuranNotesCompanion extends UpdateCompanion<QuranNote> {
  final Value<int> surah;
  final Value<int> ayah;
  final Value<String> note;
  final Value<bool> highlight;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuranNotesCompanion({
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
    this.note = const Value.absent(),
    this.highlight = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuranNotesCompanion.insert({
    required int surah,
    required int ayah,
    required String note,
    this.highlight = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : surah = Value(surah),
       ayah = Value(ayah),
       note = Value(note),
       updatedAt = Value(updatedAt);
  static Insertable<QuranNote> custom({
    Expression<int>? surah,
    Expression<int>? ayah,
    Expression<String>? note,
    Expression<bool>? highlight,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      if (note != null) 'note': note,
      if (highlight != null) 'highlight': highlight,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuranNotesCompanion copyWith({
    Value<int>? surah,
    Value<int>? ayah,
    Value<String>? note,
    Value<bool>? highlight,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuranNotesCompanion(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      note: note ?? this.note,
      highlight: highlight ?? this.highlight,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (highlight.present) {
      map['highlight'] = Variable<bool>(highlight.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranNotesCompanion(')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah, ')
          ..write('note: $note, ')
          ..write('highlight: $highlight, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuranSearchesTable extends QuranSearches with TableInfo<$QuranSearchesTable, QuranSearche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranSearchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta('searchedAt');
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_searches';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuranSearche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(_queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(
        _searchedAtMeta,
        searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  QuranSearche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranSearche(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      searchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}searched_at'],
      )!,
    );
  }

  @override
  $QuranSearchesTable createAlias(String alias) {
    return $QuranSearchesTable(attachedDatabase, alias);
  }
}

class QuranSearche extends DataClass implements Insertable<QuranSearche> {
  final String query;
  final DateTime searchedAt;
  const QuranSearche({required this.query, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['searched_at'] = Variable<DateTime>(searchedAt);
    return map;
  }

  QuranSearchesCompanion toCompanion(bool nullToAbsent) {
    return QuranSearchesCompanion(query: Value(query), searchedAt: Value(searchedAt));
  }

  factory QuranSearche.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranSearche(
      query: serializer.fromJson<String>(json['query']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
    };
  }

  QuranSearche copyWith({String? query, DateTime? searchedAt}) =>
      QuranSearche(query: query ?? this.query, searchedAt: searchedAt ?? this.searchedAt);
  QuranSearche copyWithCompanion(QuranSearchesCompanion data) {
    return QuranSearche(
      query: data.query.present ? data.query.value : this.query,
      searchedAt: data.searchedAt.present ? data.searchedAt.value : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranSearche(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranSearche && other.query == this.query && other.searchedAt == this.searchedAt);
}

class QuranSearchesCompanion extends UpdateCompanion<QuranSearche> {
  final Value<String> query;
  final Value<DateTime> searchedAt;
  final Value<int> rowid;
  const QuranSearchesCompanion({
    this.query = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuranSearchesCompanion.insert({
    required String query,
    required DateTime searchedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       searchedAt = Value(searchedAt);
  static Insertable<QuranSearche> custom({
    Expression<String>? query,
    Expression<DateTime>? searchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuranSearchesCompanion copyWith({
    Value<String>? query,
    Value<DateTime>? searchedAt,
    Value<int>? rowid,
  }) {
    return QuranSearchesCompanion(
      query: query ?? this.query,
      searchedAt: searchedAt ?? this.searchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranSearchesCompanion(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PrayerLogTable prayerLog = $PrayerLogTable(this);
  late final $QadaEntriesTable qadaEntries = $QadaEntriesTable(this);
  late final $AzkarCountsTable azkarCounts = $AzkarCountsTable(this);
  late final $SavedDuasTable savedDuas = $SavedDuasTable(this);
  late final $QuranCategoriesTable quranCategories = $QuranCategoriesTable(this);
  late final $QuranBookmarksTable quranBookmarks = $QuranBookmarksTable(this);
  late final $QuranNotesTable quranNotes = $QuranNotesTable(this);
  late final $QuranSearchesTable quranSearches = $QuranSearchesTable(this);
  late final Index qadaDay = Index(
    'qada_day',
    'CREATE UNIQUE INDEX qada_day ON qada_entries (missed_on, prayer)',
  );
  late final Index quranBookmarkAyah = Index(
    'quran_bookmark_ayah',
    'CREATE UNIQUE INDEX quran_bookmark_ayah ON quran_bookmarks (surah, ayah)',
  );
  late final Index quranBookmarkPage = Index(
    'quran_bookmark_page',
    'CREATE UNIQUE INDEX quran_bookmark_page ON quran_bookmarks (page) WHERE surah IS NULL',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    prayerLog,
    qadaEntries,
    azkarCounts,
    savedDuas,
    quranCategories,
    quranBookmarks,
    quranNotes,
    quranSearches,
    qadaDay,
    quranBookmarkAyah,
    quranBookmarkPage,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeName,
  Value<String?> placeNameAr,
  Value<String?> regionName,
  Value<String?> regionNameAr,
  Value<String?> countryCode,
  Value<String?> timeZone,
  Value<LocationMode?> locationMode,
  Value<PrayerMethod?> method,
  Value<AsrMethod?> asrMethod,
  Value<int> hijriAdjust,
  Value<Digits> digits,
  Value<BmThemeId> theme,
  Value<BmThemeMode> themeMode,
  Value<bool> reduceMotion,
  Value<bool> haptics,
  Value<bool> uiSounds,
  Value<DateTime?> firstUse,
  Value<PrayerSound> fajrSound,
  Value<PrayerSound> dhuhrSound,
  Value<PrayerSound> asrSound,
  Value<PrayerSound> maghribSound,
  Value<PrayerSound> ishaSound,
  Value<AdhanRecording> fajrRecording,
  Value<AdhanRecording> dhuhrRecording,
  Value<AdhanRecording> asrRecording,
  Value<AdhanRecording> maghribRecording,
  Value<AdhanRecording> ishaRecording,
  Value<PrayerTone> fajrTone,
  Value<PrayerTone> dhuhrTone,
  Value<PrayerTone> asrTone,
  Value<PrayerTone> maghribTone,
  Value<PrayerTone> ishaTone,
  Value<int> reminderMinutes,
  Value<bool> notificationsAsked,
  Value<int> tasbihDhikr,
  Value<int> subhanallahCount,
  Value<int> alhamdulillahCount,
  Value<int> allahuAkbarCount,
  Value<DateTime?> morningOpenedOn,
  Value<DateTime?> eveningOpenedOn,
  Value<bool> azkarNudges,
  Value<bool> azkarVoice,
  Value<bool> prayerCountdown,
  Value<CalendarMode> calendarMode,
  Value<bool> topGlow,
  Value<Language> language,
  Value<TextSize> textSize,
  Value<bool> onboarded,
  Value<bool> crashReports,
  Value<int> lastReadSurah,
  Value<int> lastReadAyah,
  Value<int> lastReadPage,
  Value<DateTime?> lastReadAt,
  Value<PageColor> pageColor,
  Value<QuranLayout> quranLayout,
  Value<PageTurn> pageTurn,
  Value<bool> keepScreenOn,
  Value<QuranFont> quranFont,
  Value<MushafStyle> mushafStyle,
  Value<Translation?> translation,
  Value<bool> adhanFlipStops,
  Value<bool> adhanButtonsStop,
  Value<bool> prayerSilent,
  Value<int> prayerSilentMinutes,
  Value<int> mushafSize,
  Value<int> quranArabicSize,
  Value<int> quranTranslationSize,
  Value<double> reciteSpeed,
  Value<int> reciteRepeat,
  Value<Reciter> reciter,
  Value<AzkarFont> azkarFont,
  Value<int> recitePause,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeName,
  Value<String?> placeNameAr,
  Value<String?> regionName,
  Value<String?> regionNameAr,
  Value<String?> countryCode,
  Value<String?> timeZone,
  Value<LocationMode?> locationMode,
  Value<PrayerMethod?> method,
  Value<AsrMethod?> asrMethod,
  Value<int> hijriAdjust,
  Value<Digits> digits,
  Value<BmThemeId> theme,
  Value<BmThemeMode> themeMode,
  Value<bool> reduceMotion,
  Value<bool> haptics,
  Value<bool> uiSounds,
  Value<DateTime?> firstUse,
  Value<PrayerSound> fajrSound,
  Value<PrayerSound> dhuhrSound,
  Value<PrayerSound> asrSound,
  Value<PrayerSound> maghribSound,
  Value<PrayerSound> ishaSound,
  Value<AdhanRecording> fajrRecording,
  Value<AdhanRecording> dhuhrRecording,
  Value<AdhanRecording> asrRecording,
  Value<AdhanRecording> maghribRecording,
  Value<AdhanRecording> ishaRecording,
  Value<PrayerTone> fajrTone,
  Value<PrayerTone> dhuhrTone,
  Value<PrayerTone> asrTone,
  Value<PrayerTone> maghribTone,
  Value<PrayerTone> ishaTone,
  Value<int> reminderMinutes,
  Value<bool> notificationsAsked,
  Value<int> tasbihDhikr,
  Value<int> subhanallahCount,
  Value<int> alhamdulillahCount,
  Value<int> allahuAkbarCount,
  Value<DateTime?> morningOpenedOn,
  Value<DateTime?> eveningOpenedOn,
  Value<bool> azkarNudges,
  Value<bool> azkarVoice,
  Value<bool> prayerCountdown,
  Value<CalendarMode> calendarMode,
  Value<bool> topGlow,
  Value<Language> language,
  Value<TextSize> textSize,
  Value<bool> onboarded,
  Value<bool> crashReports,
  Value<int> lastReadSurah,
  Value<int> lastReadAyah,
  Value<int> lastReadPage,
  Value<DateTime?> lastReadAt,
  Value<PageColor> pageColor,
  Value<QuranLayout> quranLayout,
  Value<PageTurn> pageTurn,
  Value<bool> keepScreenOn,
  Value<QuranFont> quranFont,
  Value<MushafStyle> mushafStyle,
  Value<Translation?> translation,
  Value<bool> adhanFlipStops,
  Value<bool> adhanButtonsStop,
  Value<bool> prayerSilent,
  Value<int> prayerSilentMinutes,
  Value<int> mushafSize,
  Value<int> quranArabicSize,
  Value<int> quranTranslationSize,
  Value<double> reciteSpeed,
  Value<int> reciteRepeat,
  Value<Reciter> reciter,
  Value<AzkarFont> azkarFont,
  Value<int> recitePause,
});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeNameAr =>
      $composableBuilder(column: $table.placeNameAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regionName =>
      $composableBuilder(column: $table.regionName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regionNameAr =>
      $composableBuilder(column: $table.regionNameAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get countryCode =>
      $composableBuilder(column: $table.countryCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LocationMode?, LocationMode, String> get locationMode =>
      $composableBuilder(
        column: $table.locationMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerMethod?, PrayerMethod, String> get method =>
      $composableBuilder(
        column: $table.method,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AsrMethod?, AsrMethod, String> get asrMethod => $composableBuilder(
    column: $table.asrMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get hijriAdjust =>
      $composableBuilder(column: $table.hijriAdjust, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Digits, Digits, String> get digits => $composableBuilder(
    column: $table.digits,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<BmThemeId, BmThemeId, String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<BmThemeMode, BmThemeMode, String> get themeMode =>
      $composableBuilder(
        column: $table.themeMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get reduceMotion =>
      $composableBuilder(column: $table.reduceMotion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get haptics =>
      $composableBuilder(column: $table.haptics, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get uiSounds =>
      $composableBuilder(column: $table.uiSounds, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get firstUse => $composableBuilder(
    column: $table.firstUse,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerSound, PrayerSound, String> get fajrSound =>
      $composableBuilder(
        column: $table.fajrSound,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerSound, PrayerSound, String> get dhuhrSound =>
      $composableBuilder(
        column: $table.dhuhrSound,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerSound, PrayerSound, String> get asrSound =>
      $composableBuilder(
        column: $table.asrSound,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerSound, PrayerSound, String> get maghribSound =>
      $composableBuilder(
        column: $table.maghribSound,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerSound, PrayerSound, String> get ishaSound =>
      $composableBuilder(
        column: $table.ishaSound,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AdhanRecording, AdhanRecording, String> get fajrRecording =>
      $composableBuilder(
        column: $table.fajrRecording,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AdhanRecording, AdhanRecording, String> get dhuhrRecording =>
      $composableBuilder(
        column: $table.dhuhrRecording,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AdhanRecording, AdhanRecording, String> get asrRecording =>
      $composableBuilder(
        column: $table.asrRecording,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AdhanRecording, AdhanRecording, String> get maghribRecording =>
      $composableBuilder(
        column: $table.maghribRecording,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AdhanRecording, AdhanRecording, String> get ishaRecording =>
      $composableBuilder(
        column: $table.ishaRecording,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerTone, PrayerTone, String> get fajrTone => $composableBuilder(
    column: $table.fajrTone,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerTone, PrayerTone, String> get dhuhrTone =>
      $composableBuilder(
        column: $table.dhuhrTone,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerTone, PrayerTone, String> get asrTone => $composableBuilder(
    column: $table.asrTone,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerTone, PrayerTone, String> get maghribTone =>
      $composableBuilder(
        column: $table.maghribTone,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PrayerTone, PrayerTone, String> get ishaTone => $composableBuilder(
    column: $table.ishaTone,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsAsked => $composableBuilder(
    column: $table.notificationsAsked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasbihDhikr =>
      $composableBuilder(column: $table.tasbihDhikr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subhanallahCount => $composableBuilder(
    column: $table.subhanallahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get alhamdulillahCount => $composableBuilder(
    column: $table.alhamdulillahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allahuAkbarCount => $composableBuilder(
    column: $table.allahuAkbarCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get morningOpenedOn =>
      $composableBuilder(
        column: $table.morningOpenedOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get eveningOpenedOn =>
      $composableBuilder(
        column: $table.eveningOpenedOn,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get azkarNudges =>
      $composableBuilder(column: $table.azkarNudges, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get azkarVoice =>
      $composableBuilder(column: $table.azkarVoice, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get prayerCountdown => $composableBuilder(
    column: $table.prayerCountdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarMode, CalendarMode, String> get calendarMode =>
      $composableBuilder(
        column: $table.calendarMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get topGlow =>
      $composableBuilder(column: $table.topGlow, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Language, Language, String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TextSize, TextSize, String> get textSize => $composableBuilder(
    column: $table.textSize,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get onboarded =>
      $composableBuilder(column: $table.onboarded, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get crashReports =>
      $composableBuilder(column: $table.crashReports, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReadSurah =>
      $composableBuilder(column: $table.lastReadSurah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReadAyah =>
      $composableBuilder(column: $table.lastReadAyah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReadPage =>
      $composableBuilder(column: $table.lastReadPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReadAt =>
      $composableBuilder(column: $table.lastReadAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PageColor, PageColor, String> get pageColor => $composableBuilder(
    column: $table.pageColor,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<QuranLayout, QuranLayout, String> get quranLayout =>
      $composableBuilder(
        column: $table.quranLayout,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PageTurn, PageTurn, String> get pageTurn => $composableBuilder(
    column: $table.pageTurn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get keepScreenOn =>
      $composableBuilder(column: $table.keepScreenOn, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<QuranFont, QuranFont, String> get quranFont => $composableBuilder(
    column: $table.quranFont,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MushafStyle, MushafStyle, String> get mushafStyle =>
      $composableBuilder(
        column: $table.mushafStyle,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Translation?, Translation, String> get translation =>
      $composableBuilder(
        column: $table.translation,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get adhanFlipStops =>
      $composableBuilder(column: $table.adhanFlipStops, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get adhanButtonsStop => $composableBuilder(
    column: $table.adhanButtonsStop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get prayerSilent =>
      $composableBuilder(column: $table.prayerSilent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get prayerSilentMinutes => $composableBuilder(
    column: $table.prayerSilentMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mushafSize =>
      $composableBuilder(column: $table.mushafSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quranArabicSize => $composableBuilder(
    column: $table.quranArabicSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quranTranslationSize => $composableBuilder(
    column: $table.quranTranslationSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reciteSpeed =>
      $composableBuilder(column: $table.reciteSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reciteRepeat =>
      $composableBuilder(column: $table.reciteRepeat, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Reciter, Reciter, String> get reciter => $composableBuilder(
    column: $table.reciter,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<AzkarFont, AzkarFont, String> get azkarFont => $composableBuilder(
    column: $table.azkarFont,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get recitePause =>
      $composableBuilder(column: $table.recitePause, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeNameAr =>
      $composableBuilder(column: $table.placeNameAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regionName =>
      $composableBuilder(column: $table.regionName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regionNameAr =>
      $composableBuilder(column: $table.regionNameAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get countryCode =>
      $composableBuilder(column: $table.countryCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationMode =>
      $composableBuilder(column: $table.locationMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asrMethod =>
      $composableBuilder(column: $table.asrMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hijriAdjust =>
      $composableBuilder(column: $table.hijriAdjust, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get digits =>
      $composableBuilder(column: $table.digits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reduceMotion =>
      $composableBuilder(column: $table.reduceMotion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get haptics =>
      $composableBuilder(column: $table.haptics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get uiSounds =>
      $composableBuilder(column: $table.uiSounds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstUse =>
      $composableBuilder(column: $table.firstUse, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fajrSound =>
      $composableBuilder(column: $table.fajrSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dhuhrSound =>
      $composableBuilder(column: $table.dhuhrSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asrSound =>
      $composableBuilder(column: $table.asrSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get maghribSound =>
      $composableBuilder(column: $table.maghribSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ishaSound =>
      $composableBuilder(column: $table.ishaSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fajrRecording => $composableBuilder(
    column: $table.fajrRecording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dhuhrRecording => $composableBuilder(
    column: $table.dhuhrRecording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asrRecording =>
      $composableBuilder(column: $table.asrRecording, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get maghribRecording => $composableBuilder(
    column: $table.maghribRecording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ishaRecording => $composableBuilder(
    column: $table.ishaRecording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fajrTone =>
      $composableBuilder(column: $table.fajrTone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dhuhrTone =>
      $composableBuilder(column: $table.dhuhrTone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asrTone =>
      $composableBuilder(column: $table.asrTone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get maghribTone =>
      $composableBuilder(column: $table.maghribTone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ishaTone =>
      $composableBuilder(column: $table.ishaTone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsAsked => $composableBuilder(
    column: $table.notificationsAsked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasbihDhikr =>
      $composableBuilder(column: $table.tasbihDhikr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subhanallahCount => $composableBuilder(
    column: $table.subhanallahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alhamdulillahCount => $composableBuilder(
    column: $table.alhamdulillahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allahuAkbarCount => $composableBuilder(
    column: $table.allahuAkbarCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get morningOpenedOn => $composableBuilder(
    column: $table.morningOpenedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eveningOpenedOn => $composableBuilder(
    column: $table.eveningOpenedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get azkarNudges =>
      $composableBuilder(column: $table.azkarNudges, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get azkarVoice =>
      $composableBuilder(column: $table.azkarVoice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get prayerCountdown => $composableBuilder(
    column: $table.prayerCountdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarMode =>
      $composableBuilder(column: $table.calendarMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get topGlow =>
      $composableBuilder(column: $table.topGlow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textSize =>
      $composableBuilder(column: $table.textSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get onboarded =>
      $composableBuilder(column: $table.onboarded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get crashReports =>
      $composableBuilder(column: $table.crashReports, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReadSurah => $composableBuilder(
    column: $table.lastReadSurah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadAyah =>
      $composableBuilder(column: $table.lastReadAyah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReadPage =>
      $composableBuilder(column: $table.lastReadPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReadAt =>
      $composableBuilder(column: $table.lastReadAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageColor =>
      $composableBuilder(column: $table.pageColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quranLayout =>
      $composableBuilder(column: $table.quranLayout, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageTurn =>
      $composableBuilder(column: $table.pageTurn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get keepScreenOn =>
      $composableBuilder(column: $table.keepScreenOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quranFont =>
      $composableBuilder(column: $table.quranFont, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mushafStyle =>
      $composableBuilder(column: $table.mushafStyle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get translation =>
      $composableBuilder(column: $table.translation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get adhanFlipStops => $composableBuilder(
    column: $table.adhanFlipStops,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get adhanButtonsStop => $composableBuilder(
    column: $table.adhanButtonsStop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get prayerSilent =>
      $composableBuilder(column: $table.prayerSilent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get prayerSilentMinutes => $composableBuilder(
    column: $table.prayerSilentMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mushafSize =>
      $composableBuilder(column: $table.mushafSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quranArabicSize => $composableBuilder(
    column: $table.quranArabicSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quranTranslationSize => $composableBuilder(
    column: $table.quranTranslationSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reciteSpeed =>
      $composableBuilder(column: $table.reciteSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reciteRepeat =>
      $composableBuilder(column: $table.reciteRepeat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reciter =>
      $composableBuilder(column: $table.reciter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get azkarFont =>
      $composableBuilder(column: $table.azkarFont, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recitePause =>
      $composableBuilder(column: $table.recitePause, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumn<String> get placeNameAr =>
      $composableBuilder(column: $table.placeNameAr, builder: (column) => column);

  GeneratedColumn<String> get regionName =>
      $composableBuilder(column: $table.regionName, builder: (column) => column);

  GeneratedColumn<String> get regionNameAr =>
      $composableBuilder(column: $table.regionNameAr, builder: (column) => column);

  GeneratedColumn<String> get countryCode =>
      $composableBuilder(column: $table.countryCode, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocationMode?, String> get locationMode =>
      $composableBuilder(column: $table.locationMode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerMethod?, String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AsrMethod?, String> get asrMethod =>
      $composableBuilder(column: $table.asrMethod, builder: (column) => column);

  GeneratedColumn<int> get hijriAdjust =>
      $composableBuilder(column: $table.hijriAdjust, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Digits, String> get digits =>
      $composableBuilder(column: $table.digits, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BmThemeId, String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BmThemeMode, String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get reduceMotion =>
      $composableBuilder(column: $table.reduceMotion, builder: (column) => column);

  GeneratedColumn<bool> get haptics =>
      $composableBuilder(column: $table.haptics, builder: (column) => column);

  GeneratedColumn<bool> get uiSounds =>
      $composableBuilder(column: $table.uiSounds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get firstUse =>
      $composableBuilder(column: $table.firstUse, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerSound, String> get fajrSound =>
      $composableBuilder(column: $table.fajrSound, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerSound, String> get dhuhrSound =>
      $composableBuilder(column: $table.dhuhrSound, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerSound, String> get asrSound =>
      $composableBuilder(column: $table.asrSound, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerSound, String> get maghribSound =>
      $composableBuilder(column: $table.maghribSound, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerSound, String> get ishaSound =>
      $composableBuilder(column: $table.ishaSound, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdhanRecording, String> get fajrRecording =>
      $composableBuilder(column: $table.fajrRecording, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdhanRecording, String> get dhuhrRecording =>
      $composableBuilder(column: $table.dhuhrRecording, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdhanRecording, String> get asrRecording =>
      $composableBuilder(column: $table.asrRecording, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdhanRecording, String> get maghribRecording =>
      $composableBuilder(column: $table.maghribRecording, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdhanRecording, String> get ishaRecording =>
      $composableBuilder(column: $table.ishaRecording, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerTone, String> get fajrTone =>
      $composableBuilder(column: $table.fajrTone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerTone, String> get dhuhrTone =>
      $composableBuilder(column: $table.dhuhrTone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerTone, String> get asrTone =>
      $composableBuilder(column: $table.asrTone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerTone, String> get maghribTone =>
      $composableBuilder(column: $table.maghribTone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerTone, String> get ishaTone =>
      $composableBuilder(column: $table.ishaTone, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<bool> get notificationsAsked =>
      $composableBuilder(column: $table.notificationsAsked, builder: (column) => column);

  GeneratedColumn<int> get tasbihDhikr =>
      $composableBuilder(column: $table.tasbihDhikr, builder: (column) => column);

  GeneratedColumn<int> get subhanallahCount =>
      $composableBuilder(column: $table.subhanallahCount, builder: (column) => column);

  GeneratedColumn<int> get alhamdulillahCount =>
      $composableBuilder(column: $table.alhamdulillahCount, builder: (column) => column);

  GeneratedColumn<int> get allahuAkbarCount =>
      $composableBuilder(column: $table.allahuAkbarCount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get morningOpenedOn =>
      $composableBuilder(column: $table.morningOpenedOn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get eveningOpenedOn =>
      $composableBuilder(column: $table.eveningOpenedOn, builder: (column) => column);

  GeneratedColumn<bool> get azkarNudges =>
      $composableBuilder(column: $table.azkarNudges, builder: (column) => column);

  GeneratedColumn<bool> get azkarVoice =>
      $composableBuilder(column: $table.azkarVoice, builder: (column) => column);

  GeneratedColumn<bool> get prayerCountdown =>
      $composableBuilder(column: $table.prayerCountdown, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarMode, String> get calendarMode =>
      $composableBuilder(column: $table.calendarMode, builder: (column) => column);

  GeneratedColumn<bool> get topGlow =>
      $composableBuilder(column: $table.topGlow, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Language, String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TextSize, String> get textSize =>
      $composableBuilder(column: $table.textSize, builder: (column) => column);

  GeneratedColumn<bool> get onboarded =>
      $composableBuilder(column: $table.onboarded, builder: (column) => column);

  GeneratedColumn<bool> get crashReports =>
      $composableBuilder(column: $table.crashReports, builder: (column) => column);

  GeneratedColumn<int> get lastReadSurah =>
      $composableBuilder(column: $table.lastReadSurah, builder: (column) => column);

  GeneratedColumn<int> get lastReadAyah =>
      $composableBuilder(column: $table.lastReadAyah, builder: (column) => column);

  GeneratedColumn<int> get lastReadPage =>
      $composableBuilder(column: $table.lastReadPage, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadAt =>
      $composableBuilder(column: $table.lastReadAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageColor, String> get pageColor =>
      $composableBuilder(column: $table.pageColor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QuranLayout, String> get quranLayout =>
      $composableBuilder(column: $table.quranLayout, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageTurn, String> get pageTurn =>
      $composableBuilder(column: $table.pageTurn, builder: (column) => column);

  GeneratedColumn<bool> get keepScreenOn =>
      $composableBuilder(column: $table.keepScreenOn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QuranFont, String> get quranFont =>
      $composableBuilder(column: $table.quranFont, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MushafStyle, String> get mushafStyle =>
      $composableBuilder(column: $table.mushafStyle, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Translation?, String> get translation =>
      $composableBuilder(column: $table.translation, builder: (column) => column);

  GeneratedColumn<bool> get adhanFlipStops =>
      $composableBuilder(column: $table.adhanFlipStops, builder: (column) => column);

  GeneratedColumn<bool> get adhanButtonsStop =>
      $composableBuilder(column: $table.adhanButtonsStop, builder: (column) => column);

  GeneratedColumn<bool> get prayerSilent =>
      $composableBuilder(column: $table.prayerSilent, builder: (column) => column);

  GeneratedColumn<int> get prayerSilentMinutes =>
      $composableBuilder(column: $table.prayerSilentMinutes, builder: (column) => column);

  GeneratedColumn<int> get mushafSize =>
      $composableBuilder(column: $table.mushafSize, builder: (column) => column);

  GeneratedColumn<int> get quranArabicSize =>
      $composableBuilder(column: $table.quranArabicSize, builder: (column) => column);

  GeneratedColumn<int> get quranTranslationSize =>
      $composableBuilder(column: $table.quranTranslationSize, builder: (column) => column);

  GeneratedColumn<double> get reciteSpeed =>
      $composableBuilder(column: $table.reciteSpeed, builder: (column) => column);

  GeneratedColumn<int> get reciteRepeat =>
      $composableBuilder(column: $table.reciteRepeat, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Reciter, String> get reciter =>
      $composableBuilder(column: $table.reciter, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AzkarFont, String> get azkarFont =>
      $composableBuilder(column: $table.azkarFont, builder: (column) => column);

  GeneratedColumn<int> get recitePause =>
      $composableBuilder(column: $table.recitePause, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          AppSettings,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (AppSettings, BaseReferences<_$AppDatabase, $SettingsTable, AppSettings>),
          AppSettings,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<String?> placeNameAr = const Value.absent(),
                Value<String?> regionName = const Value.absent(),
                Value<String?> regionNameAr = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<LocationMode?> locationMode = const Value.absent(),
                Value<PrayerMethod?> method = const Value.absent(),
                Value<AsrMethod?> asrMethod = const Value.absent(),
                Value<int> hijriAdjust = const Value.absent(),
                Value<Digits> digits = const Value.absent(),
                Value<BmThemeId> theme = const Value.absent(),
                Value<BmThemeMode> themeMode = const Value.absent(),
                Value<bool> reduceMotion = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> uiSounds = const Value.absent(),
                Value<DateTime?> firstUse = const Value.absent(),
                Value<PrayerSound> fajrSound = const Value.absent(),
                Value<PrayerSound> dhuhrSound = const Value.absent(),
                Value<PrayerSound> asrSound = const Value.absent(),
                Value<PrayerSound> maghribSound = const Value.absent(),
                Value<PrayerSound> ishaSound = const Value.absent(),
                Value<AdhanRecording> fajrRecording = const Value.absent(),
                Value<AdhanRecording> dhuhrRecording = const Value.absent(),
                Value<AdhanRecording> asrRecording = const Value.absent(),
                Value<AdhanRecording> maghribRecording = const Value.absent(),
                Value<AdhanRecording> ishaRecording = const Value.absent(),
                Value<PrayerTone> fajrTone = const Value.absent(),
                Value<PrayerTone> dhuhrTone = const Value.absent(),
                Value<PrayerTone> asrTone = const Value.absent(),
                Value<PrayerTone> maghribTone = const Value.absent(),
                Value<PrayerTone> ishaTone = const Value.absent(),
                Value<int> reminderMinutes = const Value.absent(),
                Value<bool> notificationsAsked = const Value.absent(),
                Value<int> tasbihDhikr = const Value.absent(),
                Value<int> subhanallahCount = const Value.absent(),
                Value<int> alhamdulillahCount = const Value.absent(),
                Value<int> allahuAkbarCount = const Value.absent(),
                Value<DateTime?> morningOpenedOn = const Value.absent(),
                Value<DateTime?> eveningOpenedOn = const Value.absent(),
                Value<bool> azkarNudges = const Value.absent(),
                Value<bool> azkarVoice = const Value.absent(),
                Value<bool> prayerCountdown = const Value.absent(),
                Value<CalendarMode> calendarMode = const Value.absent(),
                Value<bool> topGlow = const Value.absent(),
                Value<Language> language = const Value.absent(),
                Value<TextSize> textSize = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<bool> crashReports = const Value.absent(),
                Value<int> lastReadSurah = const Value.absent(),
                Value<int> lastReadAyah = const Value.absent(),
                Value<int> lastReadPage = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<PageColor> pageColor = const Value.absent(),
                Value<QuranLayout> quranLayout = const Value.absent(),
                Value<PageTurn> pageTurn = const Value.absent(),
                Value<bool> keepScreenOn = const Value.absent(),
                Value<QuranFont> quranFont = const Value.absent(),
                Value<MushafStyle> mushafStyle = const Value.absent(),
                Value<Translation?> translation = const Value.absent(),
                Value<bool> adhanFlipStops = const Value.absent(),
                Value<bool> adhanButtonsStop = const Value.absent(),
                Value<bool> prayerSilent = const Value.absent(),
                Value<int> prayerSilentMinutes = const Value.absent(),
                Value<int> mushafSize = const Value.absent(),
                Value<int> quranArabicSize = const Value.absent(),
                Value<int> quranTranslationSize = const Value.absent(),
                Value<double> reciteSpeed = const Value.absent(),
                Value<int> reciteRepeat = const Value.absent(),
                Value<Reciter> reciter = const Value.absent(),
                Value<AzkarFont> azkarFont = const Value.absent(),
                Value<int> recitePause = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                placeName: placeName,
                placeNameAr: placeNameAr,
                regionName: regionName,
                regionNameAr: regionNameAr,
                countryCode: countryCode,
                timeZone: timeZone,
                locationMode: locationMode,
                method: method,
                asrMethod: asrMethod,
                hijriAdjust: hijriAdjust,
                digits: digits,
                theme: theme,
                themeMode: themeMode,
                reduceMotion: reduceMotion,
                haptics: haptics,
                uiSounds: uiSounds,
                firstUse: firstUse,
                fajrSound: fajrSound,
                dhuhrSound: dhuhrSound,
                asrSound: asrSound,
                maghribSound: maghribSound,
                ishaSound: ishaSound,
                fajrRecording: fajrRecording,
                dhuhrRecording: dhuhrRecording,
                asrRecording: asrRecording,
                maghribRecording: maghribRecording,
                ishaRecording: ishaRecording,
                fajrTone: fajrTone,
                dhuhrTone: dhuhrTone,
                asrTone: asrTone,
                maghribTone: maghribTone,
                ishaTone: ishaTone,
                reminderMinutes: reminderMinutes,
                notificationsAsked: notificationsAsked,
                tasbihDhikr: tasbihDhikr,
                subhanallahCount: subhanallahCount,
                alhamdulillahCount: alhamdulillahCount,
                allahuAkbarCount: allahuAkbarCount,
                morningOpenedOn: morningOpenedOn,
                eveningOpenedOn: eveningOpenedOn,
                azkarNudges: azkarNudges,
                azkarVoice: azkarVoice,
                prayerCountdown: prayerCountdown,
                calendarMode: calendarMode,
                topGlow: topGlow,
                language: language,
                textSize: textSize,
                onboarded: onboarded,
                crashReports: crashReports,
                lastReadSurah: lastReadSurah,
                lastReadAyah: lastReadAyah,
                lastReadPage: lastReadPage,
                lastReadAt: lastReadAt,
                pageColor: pageColor,
                quranLayout: quranLayout,
                pageTurn: pageTurn,
                keepScreenOn: keepScreenOn,
                quranFont: quranFont,
                mushafStyle: mushafStyle,
                translation: translation,
                adhanFlipStops: adhanFlipStops,
                adhanButtonsStop: adhanButtonsStop,
                prayerSilent: prayerSilent,
                prayerSilentMinutes: prayerSilentMinutes,
                mushafSize: mushafSize,
                quranArabicSize: quranArabicSize,
                quranTranslationSize: quranTranslationSize,
                reciteSpeed: reciteSpeed,
                reciteRepeat: reciteRepeat,
                reciter: reciter,
                azkarFont: azkarFont,
                recitePause: recitePause,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<String?> placeNameAr = const Value.absent(),
                Value<String?> regionName = const Value.absent(),
                Value<String?> regionNameAr = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<LocationMode?> locationMode = const Value.absent(),
                Value<PrayerMethod?> method = const Value.absent(),
                Value<AsrMethod?> asrMethod = const Value.absent(),
                Value<int> hijriAdjust = const Value.absent(),
                Value<Digits> digits = const Value.absent(),
                Value<BmThemeId> theme = const Value.absent(),
                Value<BmThemeMode> themeMode = const Value.absent(),
                Value<bool> reduceMotion = const Value.absent(),
                Value<bool> haptics = const Value.absent(),
                Value<bool> uiSounds = const Value.absent(),
                Value<DateTime?> firstUse = const Value.absent(),
                Value<PrayerSound> fajrSound = const Value.absent(),
                Value<PrayerSound> dhuhrSound = const Value.absent(),
                Value<PrayerSound> asrSound = const Value.absent(),
                Value<PrayerSound> maghribSound = const Value.absent(),
                Value<PrayerSound> ishaSound = const Value.absent(),
                Value<AdhanRecording> fajrRecording = const Value.absent(),
                Value<AdhanRecording> dhuhrRecording = const Value.absent(),
                Value<AdhanRecording> asrRecording = const Value.absent(),
                Value<AdhanRecording> maghribRecording = const Value.absent(),
                Value<AdhanRecording> ishaRecording = const Value.absent(),
                Value<PrayerTone> fajrTone = const Value.absent(),
                Value<PrayerTone> dhuhrTone = const Value.absent(),
                Value<PrayerTone> asrTone = const Value.absent(),
                Value<PrayerTone> maghribTone = const Value.absent(),
                Value<PrayerTone> ishaTone = const Value.absent(),
                Value<int> reminderMinutes = const Value.absent(),
                Value<bool> notificationsAsked = const Value.absent(),
                Value<int> tasbihDhikr = const Value.absent(),
                Value<int> subhanallahCount = const Value.absent(),
                Value<int> alhamdulillahCount = const Value.absent(),
                Value<int> allahuAkbarCount = const Value.absent(),
                Value<DateTime?> morningOpenedOn = const Value.absent(),
                Value<DateTime?> eveningOpenedOn = const Value.absent(),
                Value<bool> azkarNudges = const Value.absent(),
                Value<bool> azkarVoice = const Value.absent(),
                Value<bool> prayerCountdown = const Value.absent(),
                Value<CalendarMode> calendarMode = const Value.absent(),
                Value<bool> topGlow = const Value.absent(),
                Value<Language> language = const Value.absent(),
                Value<TextSize> textSize = const Value.absent(),
                Value<bool> onboarded = const Value.absent(),
                Value<bool> crashReports = const Value.absent(),
                Value<int> lastReadSurah = const Value.absent(),
                Value<int> lastReadAyah = const Value.absent(),
                Value<int> lastReadPage = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<PageColor> pageColor = const Value.absent(),
                Value<QuranLayout> quranLayout = const Value.absent(),
                Value<PageTurn> pageTurn = const Value.absent(),
                Value<bool> keepScreenOn = const Value.absent(),
                Value<QuranFont> quranFont = const Value.absent(),
                Value<MushafStyle> mushafStyle = const Value.absent(),
                Value<Translation?> translation = const Value.absent(),
                Value<bool> adhanFlipStops = const Value.absent(),
                Value<bool> adhanButtonsStop = const Value.absent(),
                Value<bool> prayerSilent = const Value.absent(),
                Value<int> prayerSilentMinutes = const Value.absent(),
                Value<int> mushafSize = const Value.absent(),
                Value<int> quranArabicSize = const Value.absent(),
                Value<int> quranTranslationSize = const Value.absent(),
                Value<double> reciteSpeed = const Value.absent(),
                Value<int> reciteRepeat = const Value.absent(),
                Value<Reciter> reciter = const Value.absent(),
                Value<AzkarFont> azkarFont = const Value.absent(),
                Value<int> recitePause = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                placeName: placeName,
                placeNameAr: placeNameAr,
                regionName: regionName,
                regionNameAr: regionNameAr,
                countryCode: countryCode,
                timeZone: timeZone,
                locationMode: locationMode,
                method: method,
                asrMethod: asrMethod,
                hijriAdjust: hijriAdjust,
                digits: digits,
                theme: theme,
                themeMode: themeMode,
                reduceMotion: reduceMotion,
                haptics: haptics,
                uiSounds: uiSounds,
                firstUse: firstUse,
                fajrSound: fajrSound,
                dhuhrSound: dhuhrSound,
                asrSound: asrSound,
                maghribSound: maghribSound,
                ishaSound: ishaSound,
                fajrRecording: fajrRecording,
                dhuhrRecording: dhuhrRecording,
                asrRecording: asrRecording,
                maghribRecording: maghribRecording,
                ishaRecording: ishaRecording,
                fajrTone: fajrTone,
                dhuhrTone: dhuhrTone,
                asrTone: asrTone,
                maghribTone: maghribTone,
                ishaTone: ishaTone,
                reminderMinutes: reminderMinutes,
                notificationsAsked: notificationsAsked,
                tasbihDhikr: tasbihDhikr,
                subhanallahCount: subhanallahCount,
                alhamdulillahCount: alhamdulillahCount,
                allahuAkbarCount: allahuAkbarCount,
                morningOpenedOn: morningOpenedOn,
                eveningOpenedOn: eveningOpenedOn,
                azkarNudges: azkarNudges,
                azkarVoice: azkarVoice,
                prayerCountdown: prayerCountdown,
                calendarMode: calendarMode,
                topGlow: topGlow,
                language: language,
                textSize: textSize,
                onboarded: onboarded,
                crashReports: crashReports,
                lastReadSurah: lastReadSurah,
                lastReadAyah: lastReadAyah,
                lastReadPage: lastReadPage,
                lastReadAt: lastReadAt,
                pageColor: pageColor,
                quranLayout: quranLayout,
                pageTurn: pageTurn,
                keepScreenOn: keepScreenOn,
                quranFont: quranFont,
                mushafStyle: mushafStyle,
                translation: translation,
                adhanFlipStops: adhanFlipStops,
                adhanButtonsStop: adhanButtonsStop,
                prayerSilent: prayerSilent,
                prayerSilentMinutes: prayerSilentMinutes,
                mushafSize: mushafSize,
                quranArabicSize: quranArabicSize,
                quranTranslationSize: quranTranslationSize,
                reciteSpeed: reciteSpeed,
                reciteRepeat: reciteRepeat,
                reciter: reciter,
                azkarFont: azkarFont,
                recitePause: recitePause,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, AppSettings>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, AppSettings>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      AppSettings,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (AppSettings, BaseReferences<_$AppDatabase, $SettingsTable, AppSettings>),
      AppSettings,
      PrefetchHooks Function()
    >;
typedef $$PrayerLogTableCreateCompanionBuilder = PrayerLogCompanion Function({
  required DateTime date,
  required Prayer prayer,
  Value<int> rowid,
});
typedef $$PrayerLogTableUpdateCompanionBuilder = PrayerLogCompanion Function({
  Value<DateTime> date,
  Value<Prayer> prayer,
  Value<int> rowid,
});

class $$PrayerLogTableFilterComposer extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Prayer, Prayer, String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$PrayerLogTableOrderingComposer extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => ColumnOrderings(column));
}

class $$PrayerLogTableAnnotationComposer extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DateTime, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Prayer, String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);
}

class $$PrayerLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerLogTable,
          PrayerLogData,
          $$PrayerLogTableFilterComposer,
          $$PrayerLogTableOrderingComposer,
          $$PrayerLogTableAnnotationComposer,
          $$PrayerLogTableCreateCompanionBuilder,
          $$PrayerLogTableUpdateCompanionBuilder,
          (PrayerLogData, BaseReferences<_$AppDatabase, $PrayerLogTable, PrayerLogData>),
          PrayerLogData,
          PrefetchHooks Function()
        > {
  $$PrayerLogTableTableManager(_$AppDatabase db, $PrayerLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrayerLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrayerLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> date = const Value.absent(),
            Value<Prayer> prayer = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrayerLogCompanion(date: date, prayer: prayer, rowid: rowid),
          createCompanionCallback: ({
            required DateTime date,
            required Prayer prayer,
            Value<int> rowid = const Value.absent(),
          }) => PrayerLogCompanion.insert(date: date, prayer: prayer, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerLogTable, PrayerLogData>(table),
                  BaseReferences<_$AppDatabase, $PrayerLogTable, PrayerLogData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerLogTable,
      PrayerLogData,
      $$PrayerLogTableFilterComposer,
      $$PrayerLogTableOrderingComposer,
      $$PrayerLogTableAnnotationComposer,
      $$PrayerLogTableCreateCompanionBuilder,
      $$PrayerLogTableUpdateCompanionBuilder,
      (PrayerLogData, BaseReferences<_$AppDatabase, $PrayerLogTable, PrayerLogData>),
      PrayerLogData,
      PrefetchHooks Function()
    >;
typedef $$QadaEntriesTableCreateCompanionBuilder = QadaEntriesCompanion Function({
  Value<int> id,
  required Prayer prayer,
  Value<DateTime?> missedOn,
  Value<DateTime?> madeUpAt,
});
typedef $$QadaEntriesTableUpdateCompanionBuilder = QadaEntriesCompanion Function({
  Value<int> id,
  Value<Prayer> prayer,
  Value<DateTime?> missedOn,
  Value<DateTime?> madeUpAt,
});

class $$QadaEntriesTableFilterComposer extends Composer<_$AppDatabase, $QadaEntriesTable> {
  $$QadaEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Prayer, Prayer, String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get missedOn => $composableBuilder(
    column: $table.missedOn,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get madeUpAt =>
      $composableBuilder(column: $table.madeUpAt, builder: (column) => ColumnFilters(column));
}

class $$QadaEntriesTableOrderingComposer extends Composer<_$AppDatabase, $QadaEntriesTable> {
  $$QadaEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get missedOn =>
      $composableBuilder(column: $table.missedOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get madeUpAt =>
      $composableBuilder(column: $table.madeUpAt, builder: (column) => ColumnOrderings(column));
}

class $$QadaEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $QadaEntriesTable> {
  $$QadaEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Prayer, String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get missedOn =>
      $composableBuilder(column: $table.missedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get madeUpAt =>
      $composableBuilder(column: $table.madeUpAt, builder: (column) => column);
}

class $$QadaEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QadaEntriesTable,
          QadaEntry,
          $$QadaEntriesTableFilterComposer,
          $$QadaEntriesTableOrderingComposer,
          $$QadaEntriesTableAnnotationComposer,
          $$QadaEntriesTableCreateCompanionBuilder,
          $$QadaEntriesTableUpdateCompanionBuilder,
          (QadaEntry, BaseReferences<_$AppDatabase, $QadaEntriesTable, QadaEntry>),
          QadaEntry,
          PrefetchHooks Function()
        > {
  $$QadaEntriesTableTableManager(_$AppDatabase db, $QadaEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$QadaEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$QadaEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QadaEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Prayer> prayer = const Value.absent(),
                Value<DateTime?> missedOn = const Value.absent(),
                Value<DateTime?> madeUpAt = const Value.absent(),
              }) => QadaEntriesCompanion(
                id: id,
                prayer: prayer,
                missedOn: missedOn,
                madeUpAt: madeUpAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Prayer prayer,
                Value<DateTime?> missedOn = const Value.absent(),
                Value<DateTime?> madeUpAt = const Value.absent(),
              }) => QadaEntriesCompanion.insert(
                id: id,
                prayer: prayer,
                missedOn: missedOn,
                madeUpAt: madeUpAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QadaEntriesTable, QadaEntry>(table),
                  BaseReferences<_$AppDatabase, $QadaEntriesTable, QadaEntry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QadaEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QadaEntriesTable,
      QadaEntry,
      $$QadaEntriesTableFilterComposer,
      $$QadaEntriesTableOrderingComposer,
      $$QadaEntriesTableAnnotationComposer,
      $$QadaEntriesTableCreateCompanionBuilder,
      $$QadaEntriesTableUpdateCompanionBuilder,
      (QadaEntry, BaseReferences<_$AppDatabase, $QadaEntriesTable, QadaEntry>),
      QadaEntry,
      PrefetchHooks Function()
    >;
typedef $$AzkarCountsTableCreateCompanionBuilder = AzkarCountsCompanion Function({
  required AzkarSet setId,
  required DateTime day,
  required String zikr,
  required int count,
  Value<int> rowid,
});
typedef $$AzkarCountsTableUpdateCompanionBuilder = AzkarCountsCompanion Function({
  Value<AzkarSet> setId,
  Value<DateTime> day,
  Value<String> zikr,
  Value<int> count,
  Value<int> rowid,
});

class $$AzkarCountsTableFilterComposer extends Composer<_$AppDatabase, $AzkarCountsTable> {
  $$AzkarCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<AzkarSet, AzkarSet, String> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get zikr =>
      $composableBuilder(column: $table.zikr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnFilters(column));
}

class $$AzkarCountsTableOrderingComposer extends Composer<_$AppDatabase, $AzkarCountsTable> {
  $$AzkarCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get zikr =>
      $composableBuilder(column: $table.zikr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnOrderings(column));
}

class $$AzkarCountsTableAnnotationComposer extends Composer<_$AppDatabase, $AzkarCountsTable> {
  $$AzkarCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<AzkarSet, String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get zikr =>
      $composableBuilder(column: $table.zikr, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$AzkarCountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AzkarCountsTable,
          AzkarCount,
          $$AzkarCountsTableFilterComposer,
          $$AzkarCountsTableOrderingComposer,
          $$AzkarCountsTableAnnotationComposer,
          $$AzkarCountsTableCreateCompanionBuilder,
          $$AzkarCountsTableUpdateCompanionBuilder,
          (AzkarCount, BaseReferences<_$AppDatabase, $AzkarCountsTable, AzkarCount>),
          AzkarCount,
          PrefetchHooks Function()
        > {
  $$AzkarCountsTableTableManager(_$AppDatabase db, $AzkarCountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AzkarCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AzkarCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AzkarCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<AzkarSet> setId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<String> zikr = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AzkarCountsCompanion(
                setId: setId,
                day: day,
                zikr: zikr,
                count: count,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required AzkarSet setId,
                required DateTime day,
                required String zikr,
                required int count,
                Value<int> rowid = const Value.absent(),
              }) => AzkarCountsCompanion.insert(
                setId: setId,
                day: day,
                zikr: zikr,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AzkarCountsTable, AzkarCount>(table),
                  BaseReferences<_$AppDatabase, $AzkarCountsTable, AzkarCount>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AzkarCountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AzkarCountsTable,
      AzkarCount,
      $$AzkarCountsTableFilterComposer,
      $$AzkarCountsTableOrderingComposer,
      $$AzkarCountsTableAnnotationComposer,
      $$AzkarCountsTableCreateCompanionBuilder,
      $$AzkarCountsTableUpdateCompanionBuilder,
      (AzkarCount, BaseReferences<_$AppDatabase, $AzkarCountsTable, AzkarCount>),
      AzkarCount,
      PrefetchHooks Function()
    >;
typedef $$SavedDuasTableCreateCompanionBuilder = SavedDuasCompanion Function({
  required String dua,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedDuasTableUpdateCompanionBuilder = SavedDuasCompanion Function({
  Value<String> dua,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedDuasTableFilterComposer extends Composer<_$AppDatabase, $SavedDuasTable> {
  $$SavedDuasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dua =>
      $composableBuilder(column: $table.dua, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedDuasTableOrderingComposer extends Composer<_$AppDatabase, $SavedDuasTable> {
  $$SavedDuasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dua =>
      $composableBuilder(column: $table.dua, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedDuasTableAnnotationComposer extends Composer<_$AppDatabase, $SavedDuasTable> {
  $$SavedDuasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dua =>
      $composableBuilder(column: $table.dua, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedDuasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedDuasTable,
          SavedDua,
          $$SavedDuasTableFilterComposer,
          $$SavedDuasTableOrderingComposer,
          $$SavedDuasTableAnnotationComposer,
          $$SavedDuasTableCreateCompanionBuilder,
          $$SavedDuasTableUpdateCompanionBuilder,
          (SavedDua, BaseReferences<_$AppDatabase, $SavedDuasTable, SavedDua>),
          SavedDua,
          PrefetchHooks Function()
        > {
  $$SavedDuasTableTableManager(_$AppDatabase db, $SavedDuasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedDuasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SavedDuasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedDuasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dua = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SavedDuasCompanion(dua: dua, savedAt: savedAt, rowid: rowid),
          createCompanionCallback: ({
            required String dua,
            required DateTime savedAt,
            Value<int> rowid = const Value.absent(),
          }) => SavedDuasCompanion.insert(dua: dua, savedAt: savedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedDuasTable, SavedDua>(table),
                  BaseReferences<_$AppDatabase, $SavedDuasTable, SavedDua>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedDuasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedDuasTable,
      SavedDua,
      $$SavedDuasTableFilterComposer,
      $$SavedDuasTableOrderingComposer,
      $$SavedDuasTableAnnotationComposer,
      $$SavedDuasTableCreateCompanionBuilder,
      $$SavedDuasTableUpdateCompanionBuilder,
      (SavedDua, BaseReferences<_$AppDatabase, $SavedDuasTable, SavedDua>),
      SavedDua,
      PrefetchHooks Function()
    >;
typedef $$QuranCategoriesTableCreateCompanionBuilder = QuranCategoriesCompanion Function({
  Value<int> id,
  Value<String?> name,
  required CategoryColor color,
  required int position,
});
typedef $$QuranCategoriesTableUpdateCompanionBuilder = QuranCategoriesCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<CategoryColor> color,
  Value<int> position,
});

class $$QuranCategoriesTableFilterComposer extends Composer<_$AppDatabase, $QuranCategoriesTable> {
  $$QuranCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CategoryColor, CategoryColor, String> get color =>
      $composableBuilder(
        column: $table.color,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$QuranCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranCategoriesTable> {
  $$QuranCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$QuranCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranCategoriesTable> {
  $$QuranCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryColor, String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$QuranCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranCategoriesTable,
          QuranCategory,
          $$QuranCategoriesTableFilterComposer,
          $$QuranCategoriesTableOrderingComposer,
          $$QuranCategoriesTableAnnotationComposer,
          $$QuranCategoriesTableCreateCompanionBuilder,
          $$QuranCategoriesTableUpdateCompanionBuilder,
          (QuranCategory, BaseReferences<_$AppDatabase, $QuranCategoriesTable, QuranCategory>),
          QuranCategory,
          PrefetchHooks Function()
        > {
  $$QuranCategoriesTableTableManager(_$AppDatabase db, $QuranCategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<CategoryColor> color = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) => QuranCategoriesCompanion(id: id, name: name, color: color, position: position),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required CategoryColor color,
                required int position,
              }) => QuranCategoriesCompanion.insert(
                id: id,
                name: name,
                color: color,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuranCategoriesTable, QuranCategory>(table),
                  BaseReferences<_$AppDatabase, $QuranCategoriesTable, QuranCategory>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuranCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranCategoriesTable,
      QuranCategory,
      $$QuranCategoriesTableFilterComposer,
      $$QuranCategoriesTableOrderingComposer,
      $$QuranCategoriesTableAnnotationComposer,
      $$QuranCategoriesTableCreateCompanionBuilder,
      $$QuranCategoriesTableUpdateCompanionBuilder,
      (QuranCategory, BaseReferences<_$AppDatabase, $QuranCategoriesTable, QuranCategory>),
      QuranCategory,
      PrefetchHooks Function()
    >;
typedef $$QuranBookmarksTableCreateCompanionBuilder = QuranBookmarksCompanion Function({
  Value<int> id,
  Value<int?> surah,
  Value<int?> ayah,
  required int page,
  Value<String?> name,
  required int category,
  required DateTime createdAt,
});
typedef $$QuranBookmarksTableUpdateCompanionBuilder = QuranBookmarksCompanion Function({
  Value<int> id,
  Value<int?> surah,
  Value<int?> ayah,
  Value<int> page,
  Value<String?> name,
  Value<int> category,
  Value<DateTime> createdAt,
});

class $$QuranBookmarksTableFilterComposer extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$QuranBookmarksTableOrderingComposer extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranBookmarksTable> {
  $$QuranBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuranBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranBookmarksTable,
          QuranBookmark,
          $$QuranBookmarksTableFilterComposer,
          $$QuranBookmarksTableOrderingComposer,
          $$QuranBookmarksTableAnnotationComposer,
          $$QuranBookmarksTableCreateCompanionBuilder,
          $$QuranBookmarksTableUpdateCompanionBuilder,
          (QuranBookmark, BaseReferences<_$AppDatabase, $QuranBookmarksTable, QuranBookmark>),
          QuranBookmark,
          PrefetchHooks Function()
        > {
  $$QuranBookmarksTableTableManager(_$AppDatabase db, $QuranBookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> surah = const Value.absent(),
                Value<int?> ayah = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuranBookmarksCompanion(
                id: id,
                surah: surah,
                ayah: ayah,
                page: page,
                name: name,
                category: category,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> surah = const Value.absent(),
                Value<int?> ayah = const Value.absent(),
                required int page,
                Value<String?> name = const Value.absent(),
                required int category,
                required DateTime createdAt,
              }) => QuranBookmarksCompanion.insert(
                id: id,
                surah: surah,
                ayah: ayah,
                page: page,
                name: name,
                category: category,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuranBookmarksTable, QuranBookmark>(table),
                  BaseReferences<_$AppDatabase, $QuranBookmarksTable, QuranBookmark>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuranBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranBookmarksTable,
      QuranBookmark,
      $$QuranBookmarksTableFilterComposer,
      $$QuranBookmarksTableOrderingComposer,
      $$QuranBookmarksTableAnnotationComposer,
      $$QuranBookmarksTableCreateCompanionBuilder,
      $$QuranBookmarksTableUpdateCompanionBuilder,
      (QuranBookmark, BaseReferences<_$AppDatabase, $QuranBookmarksTable, QuranBookmark>),
      QuranBookmark,
      PrefetchHooks Function()
    >;
typedef $$QuranNotesTableCreateCompanionBuilder = QuranNotesCompanion Function({
  required int surah,
  required int ayah,
  required String note,
  Value<bool> highlight,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$QuranNotesTableUpdateCompanionBuilder = QuranNotesCompanion Function({
  Value<int> surah,
  Value<int> ayah,
  Value<String> note,
  Value<bool> highlight,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$QuranNotesTableFilterComposer extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get highlight =>
      $composableBuilder(column: $table.highlight, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$QuranNotesTableOrderingComposer extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get highlight =>
      $composableBuilder(column: $table.highlight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranNotesTableAnnotationComposer extends Composer<_$AppDatabase, $QuranNotesTable> {
  $$QuranNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get highlight =>
      $composableBuilder(column: $table.highlight, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuranNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranNotesTable,
          QuranNote,
          $$QuranNotesTableFilterComposer,
          $$QuranNotesTableOrderingComposer,
          $$QuranNotesTableAnnotationComposer,
          $$QuranNotesTableCreateCompanionBuilder,
          $$QuranNotesTableUpdateCompanionBuilder,
          (QuranNote, BaseReferences<_$AppDatabase, $QuranNotesTable, QuranNote>),
          QuranNote,
          PrefetchHooks Function()
        > {
  $$QuranNotesTableTableManager(_$AppDatabase db, $QuranNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$QuranNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$QuranNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> surah = const Value.absent(),
                Value<int> ayah = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> highlight = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuranNotesCompanion(
                surah: surah,
                ayah: ayah,
                note: note,
                highlight: highlight,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int surah,
                required int ayah,
                required String note,
                Value<bool> highlight = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuranNotesCompanion.insert(
                surah: surah,
                ayah: ayah,
                note: note,
                highlight: highlight,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuranNotesTable, QuranNote>(table),
                  BaseReferences<_$AppDatabase, $QuranNotesTable, QuranNote>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuranNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranNotesTable,
      QuranNote,
      $$QuranNotesTableFilterComposer,
      $$QuranNotesTableOrderingComposer,
      $$QuranNotesTableAnnotationComposer,
      $$QuranNotesTableCreateCompanionBuilder,
      $$QuranNotesTableUpdateCompanionBuilder,
      (QuranNote, BaseReferences<_$AppDatabase, $QuranNotesTable, QuranNote>),
      QuranNote,
      PrefetchHooks Function()
    >;
typedef $$QuranSearchesTableCreateCompanionBuilder = QuranSearchesCompanion Function({
  required String query,
  required DateTime searchedAt,
  Value<int> rowid,
});
typedef $$QuranSearchesTableUpdateCompanionBuilder = QuranSearchesCompanion Function({
  Value<String> query,
  Value<DateTime> searchedAt,
  Value<int> rowid,
});

class $$QuranSearchesTableFilterComposer extends Composer<_$AppDatabase, $QuranSearchesTable> {
  $$QuranSearchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnFilters(column));
}

class $$QuranSearchesTableOrderingComposer extends Composer<_$AppDatabase, $QuranSearchesTable> {
  $$QuranSearchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranSearchesTableAnnotationComposer extends Composer<_$AppDatabase, $QuranSearchesTable> {
  $$QuranSearchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => column);
}

class $$QuranSearchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuranSearchesTable,
          QuranSearche,
          $$QuranSearchesTableFilterComposer,
          $$QuranSearchesTableOrderingComposer,
          $$QuranSearchesTableAnnotationComposer,
          $$QuranSearchesTableCreateCompanionBuilder,
          $$QuranSearchesTableUpdateCompanionBuilder,
          (QuranSearche, BaseReferences<_$AppDatabase, $QuranSearchesTable, QuranSearche>),
          QuranSearche,
          PrefetchHooks Function()
        > {
  $$QuranSearchesTableTableManager(_$AppDatabase db, $QuranSearchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$QuranSearchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranSearchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranSearchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> query = const Value.absent(),
            Value<DateTime> searchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => QuranSearchesCompanion(query: query, searchedAt: searchedAt, rowid: rowid),
          createCompanionCallback: ({
            required String query,
            required DateTime searchedAt,
            Value<int> rowid = const Value.absent(),
          }) => QuranSearchesCompanion.insert(query: query, searchedAt: searchedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuranSearchesTable, QuranSearche>(table),
                  BaseReferences<_$AppDatabase, $QuranSearchesTable, QuranSearche>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuranSearchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuranSearchesTable,
      QuranSearche,
      $$QuranSearchesTableFilterComposer,
      $$QuranSearchesTableOrderingComposer,
      $$QuranSearchesTableAnnotationComposer,
      $$QuranSearchesTableCreateCompanionBuilder,
      $$QuranSearchesTableUpdateCompanionBuilder,
      (QuranSearche, BaseReferences<_$AppDatabase, $QuranSearchesTable, QuranSearche>),
      QuranSearche,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$PrayerLogTableTableManager get prayerLog => $$PrayerLogTableTableManager(_db, _db.prayerLog);
  $$QadaEntriesTableTableManager get qadaEntries =>
      $$QadaEntriesTableTableManager(_db, _db.qadaEntries);
  $$AzkarCountsTableTableManager get azkarCounts =>
      $$AzkarCountsTableTableManager(_db, _db.azkarCounts);
  $$SavedDuasTableTableManager get savedDuas => $$SavedDuasTableTableManager(_db, _db.savedDuas);
  $$QuranCategoriesTableTableManager get quranCategories =>
      $$QuranCategoriesTableTableManager(_db, _db.quranCategories);
  $$QuranBookmarksTableTableManager get quranBookmarks =>
      $$QuranBookmarksTableTableManager(_db, _db.quranBookmarks);
  $$QuranNotesTableTableManager get quranNotes =>
      $$QuranNotesTableTableManager(_db, _db.quranNotes);
  $$QuranSearchesTableTableManager get quranSearches =>
      $$QuranSearchesTableTableManager(_db, _db.quranSearches);
}
