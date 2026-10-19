import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showMethodSheet(BuildContext context) =>
    showBmSheet(context, builder: (_) => const _MethodSheet());

/// "By country" first, then the 11 methods, then the asr calculation. a pick is kept when the
/// location changes, "By country" clears it (FR-023, FR-024)
class _MethodSheet extends ConsumerWidget {
  const _MethodSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(
      settingsProvider.select(
        (settings) => (method: settings.value?.method, asr: settings.value?.asrMethod),
      ),
    );
    final country = ref.watch(locationProvider.select((location) => location?.countryCode));
    final db = ref.read(databaseProvider);
    void pick(SettingsCompanion values) => db.updateSettings(values);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetTitle(StringsManager.calculationMethod),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: REdgeInsets.only(bottom: SpaceManager.s6),
              children: [
                PickerRow(
                  title: StringsManager.byCountry,
                  subtitle: StringsManager.chosenForCountry,
                  value: PrayerMethod.forCountry(country).nameKey,
                  selected: picked.method == null,
                  onTap: () => pick(const SettingsCompanion(method: Value(null))),
                ),
                for (final method in PrayerMethod.values)
                  PickerRow(
                    title: method.nameKey,
                    selected: picked.method == method,
                    onTap: () => pick(SettingsCompanion(method: Value(method))),
                  ),
                const _Section(StringsManager.asrCalculation),
                PickerRow(
                  title: StringsManager.byCountry,
                  subtitle: StringsManager.chosenForCountry,
                  value: AsrMethod.forCountry(country).nameKey,
                  selected: picked.asr == null,
                  onTap: () => pick(const SettingsCompanion(asrMethod: Value(null))),
                ),
                for (final asr in AsrMethod.values)
                  PickerRow(
                    title: asr.nameKey,
                    selected: picked.asr == asr,
                    onTap: () => pick(SettingsCompanion(asrMethod: Value(asr))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// the more screen's section label, uppercase in english
class _Section extends StatelessWidget {
  const _Section(this.title);

  /// a StringsManager key
  final String title;

  @override
  Widget build(BuildContext context) {
    return OnlyPadding(
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      top: SpaceManager.s5,
      bottom: SpaceManager.s2,
      child: RegularText(
        context.tr(title).toUpperCase(),
        translate: false,
        fontSize: FontSizeManager.sectionLabel,
        letterSpacing: LetterSpacingManager.sectionLabel,
        color: ThemeEnum.text3,
      ),
    );
  }
}
