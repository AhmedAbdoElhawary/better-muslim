import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/bookmark_actions.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/quran_tile.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/study_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the gentle spring from where it is and how fast it moves, a 150 ms linear move with reduce
/// motion. the reader's card, sheets and lift all move with it
void springTo(
  BuildContext context,
  AnimationController controller,
  double target, {
  double? velocity,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.animateTo(target, duration: BmMotion.micro, curve: Curves.linear);
  } else {
    controller.animateWith(
      SpringSimulation(BmMotion.gentle, controller.value, target, velocity ?? controller.velocity),
    );
  }
}

/// K.sheet of _gen/kit.js over the page, moved by the reader's spring: 0 below the screen, 1 at its
/// detent. a drag on its head follows the finger, a flick or a pull past the share closes it.
/// with reduce motion it stays in place and fades
class ReaderSheet extends StatelessWidget {
  const ReaderSheet({
    required this.open,
    required this.onClose,
    required this.head,
    required this.body,
    this.height,
    super.key,
  });

  final AnimationController open;
  final VoidCallback onClose;
  final Widget head;
  final Widget body;

  /// the large detent's, the medium one is as tall as its content
  final double? height;

  void _drag(BuildContext context, DragUpdateDetails details) {
    open.stop();
    open.value = (open.value - details.delta.dy / context.size!.height).clamp(0.0, 1.0);
  }

  void _release(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > BmMotion.completeVelocity || open.value < 1 - BmMotion.completeShare) {
      onClose();
    } else {
      springTo(context, open, 1, velocity: -velocity / context.size!.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final height = this.height;
    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.raised),
        borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusManager.xl.r)),
        boxShadow: [
          BoxShadow(color: context.getColor(ThemeEnum.outline), offset: const Offset(0, -1)),
          BoxShadow(
            color: context.getColor(ThemeEnum.scrim).withValues(alpha: .45),
            blurRadius: SizeManager.sheetShadowBlur.r,
            offset: Offset(0, SizeManager.sheetShadowY.r),
            spreadRadius: SizeManager.sheetShadowSpread.r,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: height == null
            ? BoxConstraints(minHeight: SizeManager.ayahSheet.r)
            : BoxConstraints.tightFor(height: height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) => _drag(context, details),
              onVerticalDragEnd: (details) => _release(context, details),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerticalPadding(padding: SpaceManager.s2, child: Grabber()),
                  head,
                ],
              ),
            ),
            if (height == null) Flexible(child: body) else Expanded(child: body),
          ],
        ),
      ),
    );
    return AnimatedBuilder(
      animation: open,
      builder: (context, child) => IgnorePointer(
        ignoring: open.value < .5,
        child: reduce
            ? CustomOpacity(opacity: open.value.clamp(0.0, 1.0), child: child)
            : FractionalTranslation(translation: Offset(0, 1 - open.value), child: child),
      ),
      child: sheet,
    );
  }
}

/// sheetHead of _gen/quran.js
class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, required this.subtitle, required this.trailing});

  final Widget title;
  final Widget subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return OnlyPadding(
      top: SpaceManager.sheetHeadTop,
      start: SpaceManager.sheetHeadStart,
      end: SpaceManager.sheetHeadEnd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const RSizedBox.vertical(SpaceManager.quranHeaderGap), subtitle],
            ),
          ),
          const RSizedBox.horizontal(SpaceManager.sheetHeadGap),
          trailing,
        ],
      ),
    );
  }
}

/// iconBtn of _gen/quran.js, a 36 pt circle in a 44 pt target
class RoundButton extends StatelessWidget {
  const RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.flip = false,
    super.key,
  });

  final BmUiIcon icon;

  /// a StringsManager key
  final String label;
  final VoidCallback? onTap;

  /// an arrow points the way the language reads
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: context.tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: RSizedBox.square(
              dimension: SizeManager.sheetIconButton,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.getColor(ThemeEnum.variant),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Transform.flip(
                    flipX: flip && rtl,
                    child: BmIcon.ui(
                      icon,
                      size: SizeManager.sheetIcon.r,
                      color: context.getColor(onTap == null ? ThemeEnum.text3 : ThemeEnum.text2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Al-Fatiha · Ayah 5" in the app's language and digits
class _AyahTitle extends ConsumerWidget {
  const _AyahTitle(this.ayah);

  final AyahKey ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SemiBoldText(
      StringsManager.quranAyahN,
      maxLines: 2,
      args: {
        'surah': surah == null ? '' : (isArabic ? surah.ar : surah.en),
        'n': context.formatDigits('${ayah.ayah}', digits),
      },
    );
  }
}

/// "Juz 1 · Page 1", and the surah's place on the medium detent
class _AyahPlace extends ConsumerWidget {
  const _AyahPlace(this.ayah, {this.place = false});

  final AyahKey ayah;
  final bool place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (assets == null) return const SizedBox.shrink();
    final page = assets.pageOf(ayah);
    final juz = context.formatDigits('${assets.pageInfo(page).juz}', digits);
    final number = context.formatDigits('$page', digits);
    return RegularText(
      place ? StringsManager.juzPagePlace : StringsManager.juzPage,
      fontSize: FontSizeManager.rowSubtitle,
      color: ThemeEnum.text2,
      args: place
          ? {
              'j': juz,
              'p': number,
              'place': context.tr(
                assets.surah(ayah.surah).medinan ? StringsManager.medinan : StringsManager.meccan,
              ),
            }
          : {'juz': juz, 'page': number},
    );
  }
}

/// 4.22, the medium detent: the ayah's translation and what I can do with it. word by word and
/// memorize wait for 7b
class AyahSheet extends ConsumerWidget {
  const AyahSheet({
    required this.ayah,
    required this.open,
    required this.onClose,
    required this.onStudy,
    required this.onPlay,
    super.key,
  });

  final AyahKey ayah;
  final AnimationController open;
  final VoidCallback onClose;
  final ValueChanged<StudyTab> onStudy;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final text = ref.watch(surahTextProvider(ayah.surah)).value;

    /// in arabic the translation slot is al-muyassar (FR-020)
    final translation = isArabic ? text?.tafsir[ayah.ayah - 1] : text?.translation[ayah.ayah - 1];
    final arabic = ref.watch(ayahTextProvider(ayah)).value;
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final saved = ref.watch(ayahBookmarkProvider(ayah).select((bookmark) => bookmark != null));

    void copy() {
      if (arabic == null || translation == null || surah == null) return;
      final reference = ayah.reference(isArabic ? surah.ar : surah.en);
      Clipboard.setData(ClipboardData(text: '$arabic\n\n$translation\n\n$reference'));
      showToast(context, StringsManager.copied, icon: BmIconName.quran);
    }

    final actions = [
      (BmIcon.ui(BmUiIcon.play), StringsManager.playFromHere, onPlay),
      (BmIcon.ui(BmUiIcon.tafsir), StringsManager.tafsir, () => onStudy(StudyTab.tafsir)),
      (
        BmIcon(BmIconName.bookmark, filled: saved),
        StringsManager.bookmark,
        () => toggleAyahBookmark(context, ref, ayah),
      ),
      (BmIcon.ui(BmUiIcon.note), StringsManager.note, () => onStudy(StudyTab.notes)),
      (BmIcon.ui(BmUiIcon.share), StringsManager.share, () => showAyahShare(context, [ayah])),
      (BmIcon.ui(BmUiIcon.copy), StringsManager.copy, copy),
    ];
    return ReaderSheet(
      open: open,
      onClose: onClose,
      head: _SheetHead(
        title: _AyahTitle(ayah),
        subtitle: _AyahPlace(ayah, place: true),
        trailing: RoundButton(icon: BmUiIcon.close, label: StringsManager.close, onTap: onClose),
      ),
      body: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnlyPadding(
                top: SpaceManager.ayahTranslationTop,
                start: SpaceManager.ayahTranslationSide,
                end: SpaceManager.ayahTranslationSide,
                child: BmSwitcher(
                  child: Column(
                    key: ValueKey(ayah),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// the whole translation is one tap away on the large detent
                      RegularText(
                        translation ?? '',
                        translate: false,
                        fontSize: FontSizeManager.bodyLarge,
                        height: LineHeightManager.verseTranslation,
                        color: ThemeEnum.text,
                        maxLines: 4,
                      ),
                      const RSizedBox.vertical(SpaceManager.ayahCreditGap),
                      Row(
                        children: [
                          BmIcon.ui(
                            BmUiIcon.translate,
                            size: SizeManager.ayahCreditIcon.r,
                            color: context.getColor(ThemeEnum.text3),
                          ),
                          const RSizedBox.horizontal(SpaceManager.ayahCreditGap),
                          RegularText(
                            isArabic
                                ? StringsManager.alMuyassar
                                : StringsManager.sahihInternational,
                            fontSize: FontSizeManager.label,
                            color: ThemeEnum.text3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              OnlyPadding(
                top: SpaceManager.ayahActionsTop,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Column(
                  children: [
                    for (final (r, row) in [actions.sublist(0, 3), actions.sublist(3)].indexed) ...[
                      if (r > 0) const RSizedBox.vertical(SpaceManager.ayahActionGap),
                      Row(
                        children: [
                          for (final (i, (icon, label, onTap)) in row.indexed) ...[
                            if (i > 0) const RSizedBox.horizontal(SpaceManager.ayahActionGap),
                            Expanded(
                              child: QuranTile(
                                icon: icon,
                                label: label,
                                onTap: onTap,
                                height: SizeManager.ayahAction,
                                radius: RadiusManager.row,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

/// 4.23, the large detent: back and forward move the ayah and its wash without closing
class StudySheet extends ConsumerWidget {
  const StudySheet({
    required this.ayah,
    required this.open,
    required this.tab,
    required this.onTab,
    required this.onMove,
    required this.onClose,
    super.key,
  });

  final AyahKey ayah;
  final AnimationController open;
  final StudyTab tab;
  final ValueChanged<StudyTab> onTab;
  final ValueChanged<AyahKey> onMove;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final previous = assets?.previous(ayah);
    final next = assets?.next(ayah);
    return ReaderSheet(
      open: open,
      onClose: onClose,
      height: MediaQuery.sizeOf(context).height - SizeManager.largeSheetTop.r,
      head: _SheetHead(
        title: _AyahTitle(ayah),
        subtitle: _AyahPlace(ayah),
        trailing: Row(
          children: [
            RoundButton(
              icon: BmUiIcon.back,
              label: StringsManager.previousAyah,
              flip: true,
              onTap: previous == null ? null : () => onMove(previous),
            ),
            RoundButton(
              icon: BmUiIcon.forward,
              label: StringsManager.nextAyah,
              flip: true,
              onTap: next == null ? null : () => onMove(next),
            ),
            RoundButton(icon: BmUiIcon.close, label: StringsManager.close, onTap: onClose),
          ],
        ),
      ),
      body: StudyTabs(ayah: ayah, tab: tab, onTab: onTab),
    );
  }
}
