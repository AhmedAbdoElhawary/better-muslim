import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/step_button.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.31, every page choice in one sheet, kept in settings. tajweed colors wait for 7b
Future<void> showDisplaySheet(BuildContext context) =>
    showBmSheet(context, applyBlur: false, builder: (_) => const _DisplaySheet());

/// the translation layout's size steps around 4.07's sizes
const quranSizeSteps = (min: -2, max: 3);

/// above this the row's label goes over its control, like the prayer rows stack
const _stackAt = 1.4;

class _DisplaySheet extends ConsumerWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final (color, layout, turn, keepOn) = ref.watch(
      settingsProvider.select((settings) {
        final value = settings.value;
        return (
          value?.pageColor ?? PageColor.followSky,
          value?.quranLayout ?? QuranLayout.mushaf,
          value?.pageTurn ?? PageTurn.book,
          value?.keepScreenOn ?? false,
        );
      }),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitle(StringsManager.display, subtitle: StringsManager.appliesToEveryPage),
              const OnlyPadding(
                top: SpaceManager.s2,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: RegularText(
                  StringsManager.pageSection,
                  fontSize: FontSizeManager.sectionLabel,
                  letterSpacing: LetterSpacingManager.sectionLabel,
                  color: ThemeEnum.text3,
                ),
              ),
              OnlyPadding(
                top: SpaceManager.displaySwatchesTop,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, page) in _pageColors.indexed) ...[
                      if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
                      Expanded(
                        child: _PageSwatch(
                          page,
                          selected: page == color,
                          onTap: () => db.updateSettings(SettingsCompanion(pageColor: Value(page))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              OnlyPadding(
                top: SpaceManager.displayRowsTop,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ChoiceRow(
                      label: StringsManager.layout,
                      child: Segmented<QuranLayout>(
                        values: QuranLayout.values,
                        selected: layout,
                        labelOf: (layout) => switch (layout) {
                          QuranLayout.mushaf => StringsManager.mushaf,
                          QuranLayout.translation => StringsManager.translation,
                          QuranLayout.both => StringsManager.both,
                        },
                        onChanged: (layout) =>
                            db.updateSettings(SettingsCompanion(quranLayout: Value(layout))),
                      ),
                    ),
                    const RSizedBox.vertical(SpaceManager.s3),
                    _ChoiceRow(
                      label: StringsManager.pageTurn,
                      child: Segmented<PageTurn>(
                        values: PageTurn.values,
                        selected: turn,
                        labelOf: (turn) => switch (turn) {
                          PageTurn.book => StringsManager.book,
                          PageTurn.slide => StringsManager.slide,
                        },
                        onChanged: (turn) =>
                            db.updateSettings(SettingsCompanion(pageTurn: Value(turn))),
                      ),
                    ),
                  ],
                ),
              ),
              OnlyPadding(
                top: SpaceManager.s4,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: GroupedSection(
                  children: [
                    if (layout != QuranLayout.mushaf) ...[
                      const _SizeRow(arabic: true),
                      const _SizeRow(arabic: false),
                    ],
                    NavRow(
                      title: StringsManager.keepScreenOn,
                      toggled: keepOn,
                      onTap: () =>
                          db.updateSettings(SettingsCompanion(keepScreenOn: Value(!keepOn))),
                    ),
                    const NavRow(title: StringsManager.mushaf, value: StringsManager.madinahHafs),

                    /// in arabic the translation slot is al-muyassar (FR-020)
                    NavRow(
                      title: StringsManager.translation,
                      value: isArabic
                          ? StringsManager.alMuyassar
                          : StringsManager.sahihInternational,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the design's order, follow sky last
const _pageColors = [PageColor.paper, PageColor.cream, PageColor.night, PageColor.followSky];

/// a label in a fixed column, then its control
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.label, required this.child});

  /// a StringsManager key
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = RegularText(label, fontSize: FontSizeManager.secondary);
    if (MediaQuery.textScalerOf(context).scale(1) > _stackAt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [text, const RSizedBox.vertical(SpaceManager.s2), child],
      );
    }
    return Row(
      children: [
        RSizedBox(width: SizeManager.displayLabel, child: text),
        const RSizedBox.horizontal(SpaceManager.s3),
        Expanded(child: child),
      ],
    );
  }
}

/// the page's own color over its name, ringed in primary when picked. follow sky is half paper
/// and half night
class _PageSwatch extends StatelessWidget {
  const _PageSwatch(this.page, {required this.selected, required this.onTap});

  final PageColor page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusManager.displaySwatch.r);
    final label = switch (page) {
      PageColor.followSky => StringsManager.followSky,
      PageColor.paper => StringsManager.paper,
      PageColor.cream => StringsManager.cream,
      PageColor.night => StringsManager.night,
    };
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;
            BmHaptics.selection();
            onTap();
          },
          child: Column(
            children: [
              AnimatedDecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,

                  /// flutter paints each shadow over the one before, css the other way round
                  boxShadow: [
                    if (selected) ...[
                      BoxShadow(
                        color: context.getColor(ThemeEnum.primary),
                        spreadRadius: SizeManager.displayRing.r,
                      ),
                      BoxShadow(
                        color: context.getColor(ThemeEnum.raised),
                        spreadRadius: SizeManager.displayRingGap.r,
                      ),
                    ],
                    BoxShadow(
                      color: context.getColor(ThemeEnum.outline),
                      spreadRadius: SizeManager.divider.r,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: RSizedBox.square(
                    dimension: SizeManager.displaySwatch,
                    child: page == PageColor.followSky
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _PageFill(PageColor.paper)),
                              Expanded(child: _PageFill(PageColor.night)),
                            ],
                          )
                        : _PageFill(page),
                  ),
                ),
              ),
              const RSizedBox.vertical(SpaceManager.shareSwatchLabelGap),
              if (selected)
                SemiBoldText(label, fontSize: FontSizeManager.label, textAlign: TextAlign.center)
              else
                RegularText(
                  label,
                  fontSize: FontSizeManager.label,
                  color: ThemeEnum.text2,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the page color under its own palette in the app's theme, whatever the reader shows now
class _PageFill extends ConsumerWidget {
  const _PageFill(this.page);

  final PageColor page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.page(page, ref.watch(themeIdProvider)),
      child: Builder(builder: (context) => ColoredBox(color: context.getColor(ThemeEnum.page))),
    );
  }
}

/// the translation layout's arabic or translation size, its point size between the steps
class _SizeRow extends ConsumerWidget {
  const _SizeRow({required this.arabic});

  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final step = ref.watch(
      settingsProvider.select(
        (settings) =>
            (arabic ? settings.value?.quranArabicSize : settings.value?.quranTranslationSize) ?? 0,
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final size = arabic
        ? FontSizeManager.quranAr + step * FontSizeManager.arabicStep
        : FontSizeManager.verseTranslation + step * FontSizeManager.translationStep;
    void change(int by) => db.updateSettings(
      arabic
          ? SettingsCompanion(quranArabicSize: Value(step + by))
          : SettingsCompanion(quranTranslationSize: Value(step + by)),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
      child: OnlyPadding(
        start: SpaceManager.listRowStart,
        end: SpaceManager.s1,
        child: Row(
          children: [
            Expanded(
              child: RegularText(
                arabic ? StringsManager.arabicSize : StringsManager.translationSize,
                fontSize: FontSizeManager.body,
              ),
            ),
            StepButton(
              icon: BmUiIcon.minus,
              label: StringsManager.smaller,
              enabled: step > quranSizeSteps.min,
              onStep: () => change(-1),
            ),
            RegularText(
              context.formatDigits('${size.round()}', digits),
              translate: false,
              fontSize: FontSizeManager.secondary,
              color: ThemeEnum.text2,
              tabularFigures: true,
            ),
            StepButton(
              icon: BmUiIcon.plus,
              label: StringsManager.larger,
              enabled: step < quranSizeSteps.max,
              onStep: () => change(1),
            ),
          ],
        ),
      ),
    );
  }
}
