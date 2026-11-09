import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
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
import 'package:better_muslim/features/quran/presentation/view/widgets/bookmark_picker.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/quran_tile.dart';
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
class ReaderSheet extends StatefulWidget {
  const ReaderSheet({
    required this.open,
    required this.onClose,
    required this.head,
    required this.body,
    this.grows = false,
    super.key,
  });

  final AnimationController open;
  final VoidCallback onClose;
  final Widget head;
  final Widget body;

  /// long tafsir needs 720 but the page should still show behind it at first
  final bool grows;

  @override
  State<ReaderSheet> createState() => _ReaderSheetState();
}

class _ReaderSheetState extends State<ReaderSheet> with SingleTickerProviderStateMixin {
  late final _grow = AnimationController.unbounded(vsync: this);
  late final _scroll = _SheetScroll(this);

  @override
  void initState() {
    super.initState();
    widget.open.addListener(_reset);
  }

  @override
  void didUpdateWidget(ReaderSheet old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    old.open.removeListener(_reset);
    widget.open.addListener(_reset);
  }

  @override
  void dispose() {
    widget.open.removeListener(_reset);
    _grow.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// closed, so the next ayah opens at 400 again with its text at the top
  void _reset() {
    if (widget.open.value > 0) return;
    _grow.value = 0;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// 720 never passes the status bar on a short phone
  double get _full => math.min(
    SizeManager.studySheetFull.r,
    MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top,
  );

  double get _small => math.min(SizeManager.studySheet.r, _full);

  /// between closed and 400, or between 400 and 720
  bool get _between => widget.open.value < 1 || _grow.value > 0 && _grow.value < 1;

  /// up takes the sheet to 720 first, down takes it to closed once the text is at its top
  bool _takes(double dy, {required bool atTop}) =>
      dy < 0 ? widget.open.value < 1 || _grow.value < 1 : atTop;

  void _drag(double dy) {
    final open = widget.open;
    if (!widget.grows) {
      open.stop();
      open.value = (open.value - dy / context.size!.height).clamp(0.0, 1.0);
      return;
    }
    open.stop();
    _grow.stop();
    if (dy < 0 && open.value < 1 || dy > 0 && _grow.value <= 0) {
      open.value = (open.value - dy / _small).clamp(0.0, 1.0);
    } else {
      _grow.value = (_grow.value - dy / (_full - _small)).clamp(0.0, 1.0);
    }
  }

  void _release(double velocity) {
    final open = widget.open;
    if (open.value < 1) {
      if (velocity > BmMotion.completeVelocity || open.value < 1 - BmMotion.completeShare) {
        widget.onClose();
      } else {
        final height = widget.grows ? _small : context.size!.height;
        springTo(context, open, 1, velocity: -velocity / height);
      }
      return;
    }
    if (!widget.grows) return;
    final full = velocity.abs() > BmMotion.completeVelocity ? velocity < 0 : _grow.value > .5;
    final target = full ? 1.0 : 0.0;
    if (_grow.value != target) BmHaptics.selection();
    springTo(context, _grow, target, velocity: -velocity / (_full - _small));
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final grows = widget.grows;
    final full = _full;
    final small = _small;
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
        constraints: grows
            ? BoxConstraints.tightFor(height: full)
            : BoxConstraints(minHeight: SizeManager.ayahSheet.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) => _drag(details.delta.dy),
              onVerticalDragEnd: (details) => _release(details.primaryVelocity ?? 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerticalPadding(padding: SpaceManager.s2, child: Grabber()),
                  widget.head,
                ],
              ),
            ),
            if (grows)
              Expanded(
                child: PrimaryScrollController(controller: _scroll, child: widget.body),
              )
            else
              Flexible(child: widget.body),
          ],
        ),
      ),
    );
    final open = widget.open;
    return AnimatedBuilder(
      animation: grows ? Listenable.merge([open, _grow]) : open,
      builder: (context, child) {
        /// laid out at 720, the part above 400 waits under the screen until it grows. a close
        /// from 720 slides all of it down
        final grown = (full - small) * _grow.value;
        return IgnorePointer(
          ignoring: open.value < .5,
          child: reduce
              ? CustomOpacity(
                  opacity: open.value.clamp(0.0, 1.0),
                  child: grows
                      ? Transform.translate(offset: Offset(0, full - small - grown), child: child)
                      : child,
                )
              /// below the screen it isn't painted, it would be with every frame of the page. not
              /// Offstage, the reader measures the sheet before it moves
              : Opacity(
                  opacity: open.value <= 0 ? 0 : 1,
                  child: grows
                      ? Transform.translate(
                          offset: Offset(0, full - (small + grown) * open.value),
                          child: child,
                        )
                      : FractionalTranslation(translation: Offset(0, 1 - open.value), child: child),
                ),
        );
      },

      /// so a slide only moves its layer, nothing in the sheet paints again
      child: RepaintBoundary(child: sheet),
    );
  }
}

/// the study text's drag moves the sheet first, like a sheet with detents in ios
class _SheetScroll extends ScrollController {
  _SheetScroll(this.sheet);

  final _ReaderSheetState sheet;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SheetPosition(sheet, physics: physics, context: context, oldPosition: oldPosition);
}

class _SheetPosition extends ScrollPositionWithSingleContext {
  _SheetPosition(this.sheet, {required super.physics, required super.context, super.oldPosition});

  final _ReaderSheetState sheet;

  /// the sheet moved in this drag, so its release snaps the sheet, not a fling of the text
  var _moved = false;

  @override
  void applyUserOffset(double delta) {
    /// down scrolls the text only to its top, the rest of the move goes to the sheet
    if (delta > 0 && pixels > minScrollExtent) {
      final text = math.min(delta, pixels - minScrollExtent);
      super.applyUserOffset(text);
      delta -= text;
      if (delta == 0) return;
    }
    if (!sheet._takes(delta, atTop: pixels <= minScrollExtent)) {
      super.applyUserOffset(delta);
      return;
    }
    _moved = true;
    sheet._drag(delta);
  }

  @override
  void goBallistic(double velocity) {
    final moved = _moved;
    _moved = false;
    if (!moved || !sheet._between) {
      super.goBallistic(velocity);
      return;
    }
    goIdle();
    sheet._release(-velocity);
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
    required this.onShare,
    super.key,
  });

  final AyahKey ayah;
  final AnimationController open;
  final VoidCallback onClose;
  final ValueChanged<StudyTab> onStudy;
  final VoidCallback onPlay;

  /// starts choosing ayahs to share with this one checked
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final shown = shownTranslation(context, ref);
    final translation = ref
        .watch(translationProvider((shown, ayah.surah)))
        .value
        ?.elementAtOrNull(ayah.ayah - 1);
    final arabic = ref.watch(ayahTextProvider(ayah)).value;
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final saved = ref.watch(ayahBookmarkProvider(ayah).select((bookmark) => bookmark?.color));
    final (written, highlighted) = ref.watch(
      noteProvider(ayah)
          .select((note) => (note?.text.isNotEmpty ?? false, note?.highlight ?? false)),
    );

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
        BmIcon(
          BmIconName.bookmark,
          filled: saved != null,
          color: saved == null ? null : context.getColor(saved.theme),
        ),
        StringsManager.bookmark,
        () => showBookmarkPicker(context, ayah: ayah),
      ),
      (
        BmIcon.ui(written ? BmUiIcon.note_filled : BmUiIcon.note),
        StringsManager.note,
        () => onStudy(StudyTab.notes),
      ),
      (BmIcon.ui(BmUiIcon.share), StringsManager.share, onShare),
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
                      Directionality(
                        textDirection: shown.arabic ? TextDirection.rtl : TextDirection.ltr,
                        child: RegularText(
                          translation ?? '',
                          translate: false,
                          fontSize: FontSizeManager.bodyLarge,
                          height: LineHeightManager.verseTranslation,
                          color: ThemeEnum.text,
                          maxLines: 4,
                        ),
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
                            shown.label,
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
                                highlight: highlighted && label == StringsManager.note,
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

/// 4.23, opens at 400 and grows to 720: back and forward move the ayah and its wash without closing
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
      grows: true,
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
