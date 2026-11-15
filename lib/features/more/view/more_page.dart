import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/method_sheet.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/more/view/widgets/about_section.dart';
import 'package:better_muslim/features/more/view/widgets/adjustment_sheet.dart';
import 'package:better_muslim/features/more/view/widgets/contact_section.dart';
import 'package:better_muslim/features/more/view/widgets/language_sheet.dart';
import 'package:better_muslim/features/more/view/widgets/mode_sheet.dart';
import 'package:better_muslim/features/more/view/widgets/more_tiles.dart';
import 'package:better_muslim/features/more/view/widgets/reset_row.dart';
import 'package:better_muslim/features/more/view/widgets/text_size_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// every setting, with no account (4.09). each section reads only what it shows
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDev = ref.watch(flavorProvider.select((config) => config.flavor.isDev));
    return Scaffold(
      body: TitleGlow(
        child: LargeTitleScrollView(
          title: StringsManager.more,
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(
              child: OnlyPadding(
                top: SpaceManager.moreTilesTop,
                start: SpaceManager.screen,
                end: SpaceManager.screen,
                bottom: SpaceManager.s6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MoreTiles(),
                    const RSizedBox.vertical(SpaceManager.moreSectionsTop),
                    const _PrayerSection(),
                    const RSizedBox.vertical(SpaceManager.sectionGap),
                    const _AppearanceSection(),
                    const RSizedBox.vertical(SpaceManager.sectionGap),
                    const _SoundSection(),
                    const RSizedBox.vertical(SpaceManager.sectionGap),
                    GroupedSection(
                      label: StringsManager.sectionYourData,
                      children: [
                        NavRow(
                          icon: BmIcon.ui(BmUiIcon.download, size: SizeManager.iconList.r),
                          title: StringsManager.downloads,
                          heroTag: Routes.downloads,
                          onTap: () => context.push(Routes.downloads),
                        ),
                        const _CrashReportsRow(),
                        const ResetRow(),
                      ],
                    ),
                    const RSizedBox.vertical(SpaceManager.sectionGap),
                    const ContactSection(),
                    const AboutSection(),
                    if (isDev) ...const [
                      _DevRow('Notifications (dev)', Routes.devNotifications),
                      _DevRow('Tajweed (dev)', Routes.devTajweed),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// the large title over the sky3 glow, with 4.09's empty 44 pt button row above it
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: TopPadding(
        padding: SpaceManager.s1,
        child: SymmetricPadding(
          horizontal: SpaceManager.s5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RSizedBox.vertical(SizeManager.hit + SpaceManager.moreTitleTop),
              LargeTitle(
                StringsManager.more,
                fontSize: FontSizeManager.largeTitle,
                height: LineHeightManager.largeTitle,
              ),
              RSizedBox.vertical(SpaceManager.moreSubtitleTop),
              LargeTitleSubtitle(
                child: RegularText(StringsManager.storedOnDevice, color: ThemeEnum.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerSection extends ConsumerWidget {
  const _PrayerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(settingsProvider.select((settings) => settings.value?.method));
    final country = ref.watch(locationProvider.select((location) => location?.countryCode));
    final minutes = ref.watch(
      settingsProvider.select((settings) => settings.value?.reminderMinutes ?? 10),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return GroupedSection(
      label: StringsManager.sectionPrayer,
      children: [
        NavRow(
          icon: BmIcon(BmIconName.settings, size: SizeManager.iconList.r),
          title: StringsManager.calculationMethod,
          value: (picked ?? PrayerMethod.forCountry(country)).nameKey,
          onTap: () => showMethodSheet(context),
        ),
        NavRow(
          icon: BmIcon(BmIconName.adhan, size: SizeManager.iconList.r),
          title: StringsManager.adhanAndReminders,
          value: minutes == 0 ? StringsManager.reminderOff : StringsManager.minBefore,
          args: {'minutes': context.formatDigits('$minutes', digits)},
          heroTag: Routes.adhanSettings,
          onTap: () => context.push(Routes.adhanSettings),
        ),
        NavRow(
          startFlex: 4,
          endFlex: 3,
          icon: BmIcon(BmIconName.hijri, size: SizeManager.iconList.r),
          title: StringsManager.hijriDateAdjustment,
          value: context.adjustment(
            ref.watch(settingsProvider.select((settings) => settings.value?.hijriAdjust ?? 0)),
            digits,
          ),
          translateValue: false,
          onTap: () => showAdjustmentSheet(context),
        ),
        const _LocationRow(),
      ],
    );
  }
}

class _LocationRow extends ConsumerWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      locationProvider.select(
        (location) => location == null
            ? null
            : (name: location.placeName, nameAr: location.placeNameAr, mode: location.mode),
      ),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = place == null ? null : (isArabic ? place.nameAr : null) ?? place.name;
    return NavRow(
      icon: BmIcon(BmIconName.location, size: SizeManager.iconList.r),
      title: StringsManager.location,
      value: name == null
          ? StringsManager.noLocationYet
          : place?.mode == LocationMode.manual
          ? StringsManager.manualSuffix
          : StringsManager.autoSuffix,
      args: {'city': ?name},
      onTap: () => showLocationSheet(context),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeIdProvider);
    final mode = ref.watch(
      settingsProvider.select((settings) => settings.value?.themeMode ?? BmThemeMode.followPhone),
    );
    final reduceMotion = ref.watch(
      settingsProvider.select((settings) => settings.value?.reduceMotion ?? false),
    );
    final topGlow = ref.watch(topGlowProvider);
    final language = ref.watch(
      settingsProvider.select((settings) => settings.value?.language ?? Language.phone),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final textSize = ref.watch(
      settingsProvider.select((settings) => settings.value?.textSize ?? TextSize.standard),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final db = ref.read(databaseProvider);
    return GroupedSection(
      label: StringsManager.sectionAppearance,
      children: [
        NavRow(
          icon: BmIcon.ui(BmUiIcon.language, size: SizeManager.iconList.r),
          title: StringsManager.language,
          value: language.nameKey,
          onTap: () => showLanguageSheet(context),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.palette, size: SizeManager.iconList.r),
          title: StringsManager.theme,
          value: theme.nameKey,
          heroTag: Routes.theme,
          onTap: () => context.push(Routes.theme),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.theme_mode, size: SizeManager.iconList.r),
          title: StringsManager.lightAndDark,
          value: mode.nameKey,
          onTap: () => showModeSheet(context),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.text_size, size: SizeManager.iconList.r),
          title: StringsManager.textSize,
          value: textSize.nameKey,
          onTap: () => showTextSizeSheet(context),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.motion, size: SizeManager.iconList.r),
          title: StringsManager.reduceMotion,
          toggled: reduceMotion,
          onTap: () => db.updateSettings(SettingsCompanion(reduceMotion: Value(!reduceMotion))),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.sun, size: SizeManager.iconList.r),
          title: StringsManager.topGlow,
          toggled: topGlow,
          onTap: () => db.updateSettings(SettingsCompanion(topGlow: Value(!topGlow))),
        ),
        if (isArabic)
          NavRow(
            icon: BmIcon.ui(BmUiIcon.text_size, size: SizeManager.iconList.r),
            title: StringsManager.easternDigits,
            toggled: digits == Digits.eastern,
            onTap: () => db.updateSettings(
              SettingsCompanion(
                digits: Value(digits == Digits.eastern ? Digits.western : Digits.eastern),
              ),
            ),
          ),
      ],
    );
  }
}

class _SoundSection extends ConsumerWidget {
  const _SoundSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haptics = ref.watch(
      settingsProvider.select((settings) => settings.value?.haptics ?? true),
    );
    // final uiSounds = ref.watch(
    //   settingsProvider.select((settings) => settings.value?.uiSounds ?? false),
    // );
    final db = ref.read(databaseProvider);
    return GroupedSection(
      label: StringsManager.sectionSoundTouch,
      children: [
        NavRow(
          icon: BmIcon.ui(BmUiIcon.haptics, size: SizeManager.iconList.r),
          title: StringsManager.haptics,
          toggled: haptics,
          onTap: () => db.updateSettings(SettingsCompanion(haptics: Value(!haptics))),
        ),
        // NavRow(
        //   icon: BmIcon.ui(BmUiIcon.sound, size: SizeManager.iconList.r),
        //   title: StringsManager.uiSounds,
        //   toggled: uiSounds,
        //   onTap: () => db.updateSettings(SettingsCompanion(uiSounds: Value(!uiSounds))),
        // ),
      ],
    );
  }
}

class _CrashReportsRow extends ConsumerWidget {
  const _CrashReportsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      settingsProvider.select((settings) => settings.value?.crashReports ?? true),
    );
    return NavRow(
      icon: BmIcon.ui(BmUiIcon.lock, size: SizeManager.iconList.r),
      title: StringsManager.crashReports,
      toggled: on,
      onTap: () =>
          ref.read(databaseProvider).updateSettings(SettingsCompanion(crashReports: Value(!on))),
    );
  }
}

/// dev builds only, below everything else (FR-004)
class _DevRow extends StatelessWidget {
  const _DevRow(this.label, this.route);

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: HorizontalPadding(
            padding: SpaceManager.s4,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: RegularText(
                label,
                translate: false,
                fontSize: FontSizeManager.body,
                color: ThemeEnum.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
