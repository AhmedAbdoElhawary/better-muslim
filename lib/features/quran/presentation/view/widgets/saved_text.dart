import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/category.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// "Today 14:10" on the day, the weekday in the six days before, the date after (4.29). in the
/// place's zone, the times on the prayer screens are
String savedWhen(BuildContext context, WidgetRef ref, DateTime at) {
  final digits = ref.watch(
    settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
  );
  final zone = ref.watch(locationProvider.select((location) => location?.zone));
  final phoneZone = ref.watch(phoneZoneProvider);
  final place = zone ?? (phoneZone == null ? tz.UTC : tz.getLocation(phoneZone));
  final local = tz.TZDateTime.from(at, place);
  final now = tz.TZDateTime.from(ref.watch(clockProvider)(), place);

  /// utc, so a dst change never makes a day 23 hours
  final days = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (days == 0) {
    return context.tr(StringsManager.todayAt, {'time': context.formatTime(local, digits)});
  }
  final language = Localizations.localeOf(context).languageCode;
  final format = days > 0 && days < 7 ? DateFormat('EEE', language) : DateFormat('d MMM', language);
  return context.formatDigits(format.format(local), digits);
}

/// "Al-Fatiha 1:3 · Page 1", or "Al-Kahf · Page 293" for a page
String savedReference(
  BuildContext context,
  WidgetRef ref,
  QuranAssets assets, {
  required AyahKey? ayah,
  required int page,
}) {
  final digits = ref.watch(
    settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
  );
  String number(int n) => context.formatDigits('$n', digits);
  final surah = savedSurahName(context, assets, ayah: ayah, page: page);
  if (ayah == null) return context.tr(StringsManager.pageRef, {'surah': surah, 'p': number(page)});
  return context.tr(StringsManager.bookmarkRef, {
    'surah': surah,
    's': number(ayah.surah),
    'a': number(ayah.ayah),
    'p': number(page),
  });
}

/// the ayah's surah, or the one the page starts in
String savedSurahName(
  BuildContext context,
  QuranAssets assets, {
  required AyahKey? ayah,
  required int page,
}) {
  final surah = assets.surah(ayah?.surah ?? assets.pageInfo(page).start.surah);
  return Localizations.localeOf(context).languageCode == 'ar' ? surah.ar : surah.en;
}

/// my name for it, or "Bookmarks" in the app's language for the default
String categoryName(BuildContext context, Category category) =>
    category.name ?? context.tr(StringsManager.bookmarks);
