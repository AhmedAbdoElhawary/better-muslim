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
    defaultValue: const Constant('qiyamEmerald'),
  ).withConverter<BmThemeId>($SettingsTable.$convertertheme);
  @override
  late final GeneratedColumnWithTypeConverter<BmThemeMode, String> themeMode =
      GeneratedColumn<String>(
        'theme_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('followSky'),
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
  static const VerificationMeta _storeResetPendingMeta = const VerificationMeta(
    'storeResetPending',
  );
  @override
  late final GeneratedColumn<bool> storeResetPending = GeneratedColumn<bool>(
    'store_reset_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("store_reset_pending" IN (0, 1))',
    ),
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
    storeResetPending,
    firstUse,
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
    if (data.containsKey('store_reset_pending')) {
      context.handle(
        _storeResetPendingMeta,
        storeResetPending.isAcceptableOrUnknown(
          data['store_reset_pending']!,
          _storeResetPendingMeta,
        ),
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
      storeResetPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}store_reset_pending'],
      )!,
      firstUse: $SettingsTable.$converterfirstUsen.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}first_use']),
      ),
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

  /// set by a store reset, cleared once the user has been told (milestone 10)
  final bool storeResetPending;

  /// the strip's earliest week. the v2 migration fills it with the upgrade date
  final DateTime? firstUse;
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
    required this.storeResetPending,
    this.firstUse,
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
    map['store_reset_pending'] = Variable<bool>(storeResetPending);
    if (!nullToAbsent || firstUse != null) {
      map['first_use'] = Variable<String>($SettingsTable.$converterfirstUsen.toSql(firstUse));
    }
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
      storeResetPending: Value(storeResetPending),
      firstUse: firstUse == null && nullToAbsent ? const Value.absent() : Value(firstUse),
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
      storeResetPending: serializer.fromJson<bool>(json['storeResetPending']),
      firstUse: serializer.fromJson<DateTime?>(json['firstUse']),
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
      'storeResetPending': serializer.toJson<bool>(storeResetPending),
      'firstUse': serializer.toJson<DateTime?>(firstUse),
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
    bool? storeResetPending,
    Value<DateTime?> firstUse = const Value.absent(),
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
    storeResetPending: storeResetPending ?? this.storeResetPending,
    firstUse: firstUse.present ? firstUse.value : this.firstUse,
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
      storeResetPending: data.storeResetPending.present
          ? data.storeResetPending.value
          : this.storeResetPending,
      firstUse: data.firstUse.present ? data.firstUse.value : this.firstUse,
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
          ..write('storeResetPending: $storeResetPending, ')
          ..write('firstUse: $firstUse')
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
    storeResetPending,
    firstUse,
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
          other.storeResetPending == this.storeResetPending &&
          other.firstUse == this.firstUse);
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
  final Value<bool> storeResetPending;
  final Value<DateTime?> firstUse;
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
    this.storeResetPending = const Value.absent(),
    this.firstUse = const Value.absent(),
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
    this.storeResetPending = const Value.absent(),
    this.firstUse = const Value.absent(),
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
    Expression<bool>? storeResetPending,
    Expression<String>? firstUse,
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
      if (storeResetPending != null) 'store_reset_pending': storeResetPending,
      if (firstUse != null) 'first_use': firstUse,
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
    Value<bool>? storeResetPending,
    Value<DateTime?>? firstUse,
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
      storeResetPending: storeResetPending ?? this.storeResetPending,
      firstUse: firstUse ?? this.firstUse,
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
    if (storeResetPending.present) {
      map['store_reset_pending'] = Variable<bool>(storeResetPending.value);
    }
    if (firstUse.present) {
      map['first_use'] = Variable<String>($SettingsTable.$converterfirstUsen.toSql(firstUse.value));
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
          ..write('storeResetPending: $storeResetPending, ')
          ..write('firstUse: $firstUse')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PrayerLogTable prayerLog = $PrayerLogTable(this);
  late final $QadaEntriesTable qadaEntries = $QadaEntriesTable(this);
  late final Index qadaDay = Index(
    'qada_day',
    'CREATE UNIQUE INDEX qada_day ON qada_entries (missed_on, prayer)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [settings, prayerLog, qadaEntries, qadaDay];
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
  Value<bool> storeResetPending,
  Value<DateTime?> firstUse,
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
  Value<bool> storeResetPending,
  Value<DateTime?> firstUse,
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

  ColumnFilters<bool> get storeResetPending => $composableBuilder(
    column: $table.storeResetPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get firstUse => $composableBuilder(
    column: $table.firstUse,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
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

  ColumnOrderings<bool> get storeResetPending => $composableBuilder(
    column: $table.storeResetPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstUse =>
      $composableBuilder(column: $table.firstUse, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<bool> get storeResetPending =>
      $composableBuilder(column: $table.storeResetPending, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get firstUse =>
      $composableBuilder(column: $table.firstUse, builder: (column) => column);
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
                Value<bool> storeResetPending = const Value.absent(),
                Value<DateTime?> firstUse = const Value.absent(),
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
                storeResetPending: storeResetPending,
                firstUse: firstUse,
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
                Value<bool> storeResetPending = const Value.absent(),
                Value<DateTime?> firstUse = const Value.absent(),
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
                storeResetPending: storeResetPending,
                firstUse: firstUse,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$PrayerLogTableTableManager get prayerLog => $$PrayerLogTableTableManager(_db, _db.prayerLog);
  $$QadaEntriesTableTableManager get qadaEntries =>
      $$QadaEntriesTableTableManager(_db, _db.qadaEntries);
}
