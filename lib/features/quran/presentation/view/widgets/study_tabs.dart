import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/note_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the large sheet's panes (4.23), words waits for 7b
enum StudyTab {
  tafsir(StringsManager.tafsir),
  translation(StringsManager.translation),
  notes(StringsManager.notes);

  const StudyTab(this.label);

  final String label;
}

/// the tafsir chips, the two samples are keys of samples.json
enum _Tafsir {
  muyassar(StringsManager.alMuyassar),
  ibnKathir(StringsManager.ibnKathir, sample: 'ibnKathir'),
  saadi(StringsManager.asSadi, sample: 'saadi');

  const _Tafsir(this.label, {this.sample});

  final String label;
  final String? sample;
}

/// 4.23 under its header: the ayah on its page color, then Tafsir, Translation and Notes
class StudyTabs extends StatefulWidget {
  const StudyTabs({required this.ayah, required this.tab, required this.onTab, super.key});

  final AyahKey ayah;
  final StudyTab tab;
  final ValueChanged<StudyTab> onTab;

  @override
  State<StudyTabs> createState() => _StudyTabsState();
}

class _StudyTabsState extends State<StudyTabs> {
  /// the pane comes in from the side of the tab it moves toward
  AxisDirection _from = AxisDirection.down;
  _Tafsir _tafsir = _Tafsir.muyassar;

  @override
  void didUpdateWidget(StudyTabs old) {
    super.didUpdateWidget(old);
    if (old.tab == widget.tab) return;
    _from = widget.tab.index > old.tab.index ? AxisDirection.right : AxisDirection.left;
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.ayah;
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnlyPadding(
                top: SpaceManager.studyCardTop,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: _AyahCard(ayah),
              ),
              OnlyPadding(
                top: SpaceManager.studyTabsTop,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Segmented(
                  values: StudyTab.values,
                  selected: widget.tab,
                  labelOf: (tab) => tab.label,
                  onChanged: widget.onTab,
                ),
              ),
              BmSwitcher(
                from: _from,
                child: KeyedSubtree(
                  key: ValueKey((widget.tab, ayah)),
                  child: switch (widget.tab) {
                    StudyTab.tafsir => _TafsirPane(
                      ayah: ayah,
                      tafsir: _tafsir,
                      onTafsir: (tafsir) => setState(() => _tafsir = tafsir),
                    ),
                    StudyTab.translation => _TranslationPane(ayah),
                    StudyTab.notes => _NotesPane(ayah),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the ayah as the mushaf prints it, its end marker from the font
class _AyahCard extends ConsumerWidget {
  const _AyahCard(this.ayah);

  final AyahKey ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(ayahTextProvider(ayah)).value ?? '';
    final number = formatDigitsIn('${ayah.ayah}', language: 'ar', digits: Digits.eastern);

    /// the font draws the end of ayah sign around the number after it
    final line = '$text \u06DD$number';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.page),
        borderRadius: BorderRadius.circular(RadiusManager.row.r),
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: OnlyPadding(
        top: SpaceManager.studyCardPadTop,
        bottom: SpaceManager.studyCardPadBottom,
        start: SpaceManager.studyCardSide,
        end: SpaceManager.studyCardSide,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RegularText(
            line,
            translate: false,
            font: FontEnum.quran,
            fontSize: FontSizeManager.quranStudy,
            height: LineHeightManager.quranStudy,
            color: ThemeEnum.ink,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TafsirPane extends ConsumerWidget {
  const _TafsirPane({required this.ayah, required this.tafsir, required this.onTafsir});

  final AyahKey ayah;
  final _Tafsir tafsir;
  final ValueChanged<_Tafsir> onTafsir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = tafsir.sample;
    final text = sample == null
        ? ref.watch(surahTextProvider(ayah.surah)).value?.tafsir[ayah.ayah - 1] ?? ''
        : ref.watch(quranSamplesProvider).value?[sample]?['$ayah'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: REdgeInsetsDirectional.only(
            top: SpaceManager.s4,
            start: SpaceManager.s4,
            end: SpaceManager.s4,
          ),
          child: Row(
            children: [
              for (final (i, chip) in _Tafsir.values.indexed) ...[
                if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
                _Chip(chip.label, selected: chip == tafsir, onTap: () => onTafsir(chip)),
              ],
            ],
          ),
        ),
        OnlyPadding(
          top: SpaceManager.tafsirTextTop,
          start: SpaceManager.tafsirTextSide,
          end: SpaceManager.tafsirTextSide,
          child: text == null
              ? const RegularText(StringsManager.comingSoon, color: ThemeEnum.text2)
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: RegularText(
                    text,
                    translate: false,
                    font: FontEnum.dua,
                    fontSize: FontSizeManager.tafsir,
                    height: LineHeightManager.tafsir,
                    color: ThemeEnum.text,
                  ),
                ),
        ),
        if (tafsir == _Tafsir.muyassar)
          const OnlyPadding(
            top: SpaceManager.tafsirCreditTop,
            start: SpaceManager.tafsirTextSide,
            end: SpaceManager.tafsirTextSide,
            child: RegularText(
              StringsManager.muyassarCredit,
              fontSize: FontSizeManager.label,
              color: ThemeEnum.text3,
            ),
          ),
      ],
    );
  }
}

/// K.chip of _gen/kit.js
class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.selected, required this.onTap});

  /// a StringsManager key
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.getColor(ThemeEnum.primary);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            child: Container(
              constraints: BoxConstraints(minHeight: SizeManager.tafsirChip.r),
              padding: REdgeInsets.symmetric(horizontal: SpaceManager.duaChipSide),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.getColor(
                  selected ? ThemeEnum.primaryContainer : ThemeEnum.transparent,
                ),
                borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                border: Border.all(
                  color: selected
                      ? primary.withValues(alpha: .5)
                      : context.getColor(ThemeEnum.outline),
                ),
              ),
              child: selected
                  ? SemiBoldText(
                      label,
                      fontSize: FontSizeManager.tafsirChip,
                      color: ThemeEnum.onPrimaryContainer,
                    )
                  : RegularText(
                      label,
                      fontSize: FontSizeManager.tafsirChip,
                      color: ThemeEnum.text2,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// notesPane of _gen/quran.js, one note per ayah so Add note shows only without one
class _NotesPane extends ConsumerWidget {
  const _NotesPane(this.ayah);

  final AyahKey ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteProvider(ayah));
    return OnlyPadding(
      top: SpaceManager.s4,
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      child: note == null
          ? BmButton.secondary(
              StringsManager.addNote,
              onPressed: () => showNoteEditor(context, ayah),
            )
          : NoteCard(
              note,
              showAyah: false,
              radius: RadiusManager.row,
              onTap: () => showNoteEditor(context, ayah),
            ),
    );
  }
}

/// the slot's source is marked in primary: sahih international, al-muyassar in arabic
class _TranslationPane extends ConsumerWidget {
  const _TranslationPane(this.ayah);

  final AyahKey ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(surahTextProvider(ayah.surah)).value;
    final sample = ref.watch(quranSamplesProvider).value?['clearQuran']?['$ayah'];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cards = [
      (
        StringsManager.sahihInternational,
        text?.translation[ayah.ayah - 1] ?? '',
        TextDirection.ltr,
      ),
      (StringsManager.clearQuran, sample, TextDirection.ltr),
      (StringsManager.muyassarSummary, text?.tafsir[ayah.ayah - 1] ?? '', TextDirection.rtl),
    ];
    return OnlyPadding(
      top: SpaceManager.s4,
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (name, text, direction)) in cards.indexed) ...[
            if (i > 0) const RSizedBox.vertical(SpaceManager.studyCardGap),
            _TranslationCard(
              name: name,
              text: text,
              direction: direction,
              slot: i == (isArabic ? 2 : 0),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.name,
    required this.text,
    required this.direction,
    required this.slot,
  });

  /// a StringsManager key
  final String name;

  /// null shows coming soon
  final String? text;
  final TextDirection direction;
  final bool slot;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    final color = slot ? ThemeEnum.text : ThemeEnum.text2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.surface),
        borderRadius: BorderRadius.circular(RadiusManager.row.r),
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: SymmetricPadding(
        horizontal: SpaceManager.studyCardSide,
        vertical: SpaceManager.studyCardV,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SemiBoldText(
              name,
              fontSize: FontSizeManager.labelStrong,
              color: slot ? ThemeEnum.primary : ThemeEnum.text3,
            ),
            const RSizedBox.vertical(SpaceManager.studyCardLineGap),
            if (text == null)
              RegularText(StringsManager.comingSoon, fontSize: FontSizeManager.body, color: color)
            else
              Directionality(
                textDirection: direction,
                child: RegularText(
                  text,
                  translate: false,
                  fontSize: FontSizeManager.body,
                  height: LineHeightManager.verseTranslation,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
