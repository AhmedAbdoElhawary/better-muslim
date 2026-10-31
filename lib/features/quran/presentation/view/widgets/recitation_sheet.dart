import 'package:better_muslim/core/database/app_database.dart';
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
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/motion/oil_drop.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/data/recitation_files.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a StringsManager key and its args
typedef _Label = (String, Map<String, String>);

/// 4.25: the reciter, where it is, the controls and the four choices. speed, repeat and pause are
/// saved, range and sleep last for the session
class RecitationSheet extends ConsumerWidget {
  const RecitationSheet({required this.open, required this.onClose, super.key});

  final AnimationController open;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(
      settingsProvider.select((settings) => settings.value?.reciter ?? Reciter.alafasy),
    );
    final surah = ref.watch(recitationStateProvider.select((state) => state.value?.from?.surah));
    final ready =
        ref.watch(recitationStateProvider.select((state) => state.value?.surahReady ?? false)) ||
        (surah != null &&
            ref.watch(
              surahDownloadProvider((reciter, surah)).select((download) => download.ready),
            ));
    return ReaderSheet(
      open: open,
      onClose: onClose,
      head: OnlyPadding(
        top: SpaceManager.sheetHeadTop,
        start: SpaceManager.sheetHeadStart,
        end: SpaceManager.sheetHeadEnd,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                hint: context.tr(StringsManager.reciter),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _Choices._pick(
                    context,
                    title: StringsManager.reciter,
                    choices: Reciter.values,
                    selected: reciter,
                    label: (reciter) => (reciter.label, const {}),
                    digits: (args) => args,
                    onPick: (reciter) => ref
                        .read(databaseProvider)
                        .updateSettings(SettingsCompanion(reciter: Value(reciter))),
                  ),
                  child: Row(
                    children: [
                      _Avatar(reciter),
                      const RSizedBox.horizontal(SpaceManager.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SemiBoldText(
                              reciter.label,
                              fontSize: FontSizeManager.bodyLarge,
                              maxLines: 2,
                            ),
                            const RSizedBox.vertical(SpaceManager.quranHeaderGap),
                            RegularText(
                              ready
                                  ? StringsManager.murattalDownloaded
                                  : StringsManager.murattalHafs,
                              fontSize: FontSizeManager.rowSubtitle,
                              color: ThemeEnum.text2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _Download(),
            RoundButton(icon: BmUiIcon.chevron_down, label: StringsManager.close, onTap: onClose),
          ],
        ),
      ),

      /// at large text the four rows pass the screen
      body: const SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: BottomPadding(
            padding: SpaceManager.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_Progress(), _Controls(), _Choices()],
            ),
          ),
        ),
      ),
    );
  }
}

/// the playing surah in the chosen voice, kept for offline. a lost connection keeps what came in
class _Download extends ConsumerWidget {
  const _Download();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(
      settingsProvider.select((settings) => settings.value?.reciter ?? Reciter.alafasy),
    );
    final surah = ref.watch(recitationStateProvider.select((state) => state.value?.from?.surah));
    if (surah == null) return const SizedBox.shrink();
    final download = ref.watch(surahDownloadProvider((reciter, surah)));
    if (download.downloading) {
      return Semantics(
        label: context.tr(StringsManager.downloading),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmOilDrop(size: SizeManager.oilDropSmall, progress: download.progress),
          ),
        ),
      );
    }
    if (download.ready) {
      return const RoundButton(
        icon: BmUiIcon.check,
        label: StringsManager.surahDownloaded,
        onTap: null,
      );
    }
    return RoundButton(
      icon: BmUiIcon.download,
      label: StringsManager.downloadSurah,
      onTap: () async {
        try {
          await ref.read(surahDownloadProvider((reciter, surah)).notifier).download();
        } on RecitationException catch (error) {
          if (!context.mounted) return;
          showToast(
            context,
            error.failure == RecitationFailure.offline
                ? StringsManager.recitationOffline
                : StringsManager.downloadFailed,
            icon: BmIconName.listen,
          );
        }
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.reciter);

  final Reciter reciter;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.reciterAvatar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.primaryContainer),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: RegularText(
            reciter.initials,
            font: FontEnum.display,
            fontSize: FontSizeManager.reciterInitials,
            color: ThemeEnum.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// "Al-Fatiha · Ayah 3 of 7", the ayah's time and how far into the range it is. a drag along it
/// shows the ayah under the finger and goes there on release (ADR 0001)
class _Progress extends ConsumerStatefulWidget {
  const _Progress();

  @override
  ConsumerState<_Progress> createState() => _ProgressState();
}

class _ProgressState extends ConsumerState<_Progress> {
  /// the ayah under the finger while dragging
  int? _drag;
  double _width = 1;

  static String _time(Duration time) =>
      '${time.inMinutes}:${'${time.inSeconds % 60}'.padLeft(2, '0')}';

  void _dragTo(double dx, AyahKey? from, AyahKey? to) {
    if (from == null || to == null) return;
    final x = (dx - SpaceManager.s5.r) / _width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final ayah = dragAyah(rtl ? 1 - x : x, from: from, to: to);
    if (ayah == _drag) return;
    BmHaptics.selection();
    setState(() => _drag = ayah);
  }

  void _release(AyahKey? from) {
    final ayah = _drag;
    setState(() => _drag = null);
    if (ayah == null || from == null) return;
    ref.read(followingProvider.notifier).set(true);
    ref.read(recitationProvider).seekToAyah(AyahKey(from.surah, ayah));
  }

  @override
  Widget build(BuildContext context) {
    final ayah = ref.watch(playingAyahProvider);
    final (position, duration, from, to) = ref.watch(
      recitationStateProvider.select(
        (state) => (
          state.value?.position ?? Duration.zero,
          state.value?.duration ?? Duration.zero,
          state.value?.from,
          state.value?.to,
        ),
      ),
    );
    final surah = ayah == null ? null : ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final n = ayah == null ? 0 : readAyah(ayah).ayah;
    final total = surah?.ayahs ?? 1;
    final where = surah == null
        ? ''
        : '${isArabic ? surah.ar : surah.en} · ${context.tr(StringsManager.ayahOf, {'n': '$n', 'total': '$total'})}';
    final drag = _drag;
    final shown = drag == null || from == null ? ayah : AyahKey(from.surah, drag);
    final fraction = shown == null || from == null || to == null
        ? 0.0
        : rangeProgress(shown, from: from, to: to);

    /// the whole block takes the drag, the bar alone is under the 44 pt a target needs
    return Semantics(
      label: context.tr(StringsManager.recitationBar),
      value: context.formatDigits(where, digits),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) => _dragTo(details.localPosition.dx, from, to),
        onHorizontalDragUpdate: (details) => _dragTo(details.localPosition.dx, from, to),
        onHorizontalDragEnd: (_) => _release(from),
        onHorizontalDragCancel: () => setState(() => _drag = null),
        child: OnlyPadding(
          top: SpaceManager.recitationProgressTop,
          start: SpaceManager.s5,
          end: SpaceManager.s5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RegularText(
                      context.formatDigits(where, digits),
                      translate: false,
                      fontSize: FontSizeManager.rowSubtitle,
                      color: ThemeEnum.text2,
                      maxLines: 1,
                    ),
                  ),
                  const RSizedBox.horizontal(SpaceManager.s2),
                  RegularText(
                    context.formatDigits('${_time(position)} / ${_time(duration)}', digits),
                    translate: false,
                    fontSize: FontSizeManager.rowSubtitle,
                    color: ThemeEnum.text2,
                    tabularFigures: true,
                  ),
                ],
              ),
              const RSizedBox.vertical(SpaceManager.s2),
              LayoutBuilder(
                builder: (context, constraints) {
                  _width = constraints.maxWidth;
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusManager.recitationBar.r),
                        child: RSizedBox(
                          height: SizeManager.recitationBar,
                          child: ColoredBox(
                            color: context.getColor(ThemeEnum.variant),
                            child: AnimatedFractionallySizedBox(
                              duration: MediaQuery.disableAnimationsOf(context) || drag != null
                                  ? Duration.zero
                                  : BmMotion.standard,
                              curve: BmMotion.standardCurve,
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: fraction,
                              child: ColoredBox(color: context.getColor(ThemeEnum.primary)),
                            ),
                          ),
                        ),
                      ),
                      if (drag != null)
                        Positioned(
                          left: (rtl ? 1 - fraction : fraction) * _width,
                          bottom: SizeManager.recitationBar.r + SpaceManager.s2.r,
                          child: FractionalTranslation(
                            translation: const Offset(-.5, 0),
                            child: _AyahBubble(drag, digits: digits),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ayah 45" over the finger while the bar is dragged
class _AyahBubble extends StatelessWidget {
  const _AyahBubble(this.ayah, {required this.digits});

  final int ayah;
  final Digits digits;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.primary),
        borderRadius: BorderRadius.circular(RadiusManager.pill.r),
      ),
      child: SymmetricPadding(
        horizontal: SpaceManager.s2,
        vertical: SpaceManager.s1,
        child: SemiBoldText(
          StringsManager.ayahNumber,
          args: {'n': context.formatDigits('$ayah', digits)},
          fontSize: FontSizeManager.rowSubtitle,
          color: ThemeEnum.onPrimary,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// repeat, previous, -10, play or pause, +10, next and the speed, left to right in arabic too
/// (FR-029)
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (repeat, speed) = ref.watch(
      settingsProvider.select(
        (settings) => (settings.value?.reciteRepeat ?? 1, settings.value?.reciteSpeed ?? 1.0),
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final recitation = ref.watch(recitationProvider);
    final db = ref.watch(databaseProvider);
    T after<T>(List<T> choices, T value) => choices[(choices.indexOf(value) + 1) % choices.length];
    void move(Future<void> Function() to) {
      ref.read(followingProvider.notifier).set(true);
      to();
    }

    return OnlyPadding(
      top: SpaceManager.recitationControlsTop,
      start: SpaceManager.recitationControlsSide,
      end: SpaceManager.recitationControlsSide,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Control(
              label: StringsManager.repeatEachAyah,
              onTap: () => db.updateSettings(
                SettingsCompanion(reciteRepeat: Value(after(reciteRepeats, repeat))),
              ),
              child: _RepeatIcon(repeat: repeat, digits: digits),
            ),
            _Control(
              label: StringsManager.previousAyah,
              onTap: () => move(recitation.previous),
              child: BmIcon.ui(
                BmUiIcon.prev,
                size: SizeManager.recitationIcon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
            _Control(
              label: StringsManager.back10,
              onTap: () => move(() => recitation.seekBy(const Duration(seconds: -10))),
              child: BmIcon.ui(
                BmUiIcon.back_10,
                size: SizeManager.recitationIcon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
            const PlayButton(size: SizeManager.recitationPlay, icon: SizeManager.recitationIcon),
            _Control(
              label: StringsManager.forward10,
              onTap: () => move(() => recitation.seekBy(const Duration(seconds: 10))),
              child: BmIcon.ui(
                BmUiIcon.forward_10,
                size: SizeManager.recitationIcon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
            _Control(
              label: StringsManager.nextAyah,
              onTap: () => move(recitation.next),
              child: BmIcon.ui(
                BmUiIcon.next,
                size: SizeManager.recitationIcon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
            _Control(
              label: StringsManager.speed,
              onTap: () => db.updateSettings(
                SettingsCompanion(reciteSpeed: Value(after(reciteSpeeds, speed))),
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: SizeManager.recitationRateMaxTextScale,
                child: SemiBoldText(
                  StringsManager.rate,
                  args: {'rate': speedLabel(context, speed, digits)},
                  fontSize: FontSizeManager.secondary,
                  tabularFigures: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// a 44 pt target, the speed and repeat step through their choices with the selection haptic
class _Control extends StatelessWidget {
  const _Control({required this.label, required this.onTap, required this.child});

  /// a StringsManager key
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          BmHaptics.selection();
          onTap();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: SizeManager.hit.r, minHeight: SizeManager.hit.r),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// the repeat icon in primary with its "3×" badge, no badge when off
class _RepeatIcon extends StatelessWidget {
  const _RepeatIcon({required this.repeat, required this.digits});

  final int repeat;
  final Digits digits;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BmIcon.ui(
          BmUiIcon.repeat,
          size: SizeManager.recitationRepeatIcon.r,
          color: context.getColor(repeat > 1 ? ThemeEnum.primary : ThemeEnum.text2),
        ),
        if (repeat > 1)
          PositionedDirectional(
            end: SpaceManager.repeatBadgeEnd.r,
            top: SpaceManager.repeatBadgeTop.r,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.primary),
                borderRadius: BorderRadius.circular(RadiusManager.repeatBadge.r),
              ),
              child: SymmetricPadding(
                horizontal: SpaceManager.repeatBadgeH,
                vertical: SpaceManager.repeatBadgeV,
                child: SemiBoldText(
                  context.formatDigits('$repeat×', digits),
                  translate: false,
                  fontSize: FontSizeManager.repeatBadge,
                  color: ThemeEnum.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Choices extends ConsumerWidget {
  const _Choices();

  static _Label _repeat(int times) =>
      times == 1 ? (StringsManager.off, const {}) : (StringsManager.nTimes, {'n': '$times'});

  static _Label _pause(int seconds) =>
      seconds == 0 ? (StringsManager.off, const {}) : (StringsManager.nSeconds, {'n': '$seconds'});

  static _Label _sleep(SleepTimer timer) => switch (timer) {
    SleepTimer(endOfSurah: true) => (StringsManager.endOfSurah, const {}),
    SleepTimer(:final after?) => (StringsManager.nMinutes, {'n': '${after.inMinutes}'}),
    _ => (StringsManager.off, const {}),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (repeat, pause) = ref.watch(
      settingsProvider.select(
        (settings) => (settings.value?.reciteRepeat ?? 1, settings.value?.recitePause ?? 0),
      ),
    );
    final (from, to, sleep) = ref.watch(
      recitationStateProvider.select(
        (state) => (state.value?.from, state.value?.to, state.value?.sleep),
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final db = ref.read(databaseProvider);
    Map<String, String> digitsOf(Map<String, String> args) => {
      for (final MapEntry(:key, :value) in args.entries) key: context.formatDigits(value, digits),
    };
    NavRow row(Widget icon, String title, _Label value, VoidCallback onTap) =>
        NavRow(icon: icon, title: title, value: value.$1, args: digitsOf(value.$2), onTap: onTap);
    final sleepLabel = _sleep(sleep ?? const SleepTimer.off());
    return OnlyPadding(
      top: SpaceManager.s4,
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      child: GroupedSection(
        children: [
          row(
            BmIcon.ui(BmUiIcon.repeat),
            StringsManager.repeatEachAyah,
            _repeat(repeat),
            () => _pick(
              context,
              title: StringsManager.repeatEachAyah,
              choices: reciteRepeats,
              selected: repeat,
              label: (times) => _repeat(times),
              digits: digitsOf,
              onPick: (times) => db.updateSettings(SettingsCompanion(reciteRepeat: Value(times))),
            ),
          ),
          row(
            BmIcon.ui(BmUiIcon.spread),
            StringsManager.range,
            (StringsManager.ayahRange, {'from': '${from?.ayah ?? ''}', 'to': '${to?.ayah ?? ''}'}),
            () {
              if (from != null && to != null) _range(context, ref, from, to);
            },
          ),
          row(
            BmIcon.ui(BmUiIcon.timer),
            StringsManager.pauseBetweenAyahs,
            _pause(pause),
            () => _pick(
              context,
              title: StringsManager.pauseBetweenAyahs,
              choices: recitePauses,
              selected: pause,
              label: (seconds) => _pause(seconds),
              digits: digitsOf,
              onPick: (seconds) =>
                  db.updateSettings(SettingsCompanion(recitePause: Value(seconds))),
            ),
          ),
          row(
            BmIcon(BmIconName.night),
            StringsManager.sleepTimer,
            sleepLabel,
            () => _pick(
              context,
              title: StringsManager.sleepTimer,
              choices: SleepTimer.choices,
              selected: sleep ?? const SleepTimer.off(),
              label: _sleep,
              digits: digitsOf,
              onPick: ref.read(recitationProvider).setSleep,
            ),
          ),
        ],
      ),
    );
  }

  /// the sheet goes over the root navigator, it keeps the page's palette
  static Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> choices,
    required T selected,
    required _Label Function(T choice) label,
    required Map<String, String> Function(Map<String, String> args) digits,
    required ValueChanged<T> onPick,
  }) {
    final theme = Theme.of(context);
    return showBmSheet(
      context,
      builder: (_) => Theme(
        data: theme,
        child: _ChoiceSheet<T>(
          title: title,
          choices: choices,
          selected: selected,
          label: (choice) => (label(choice).$1, digits(label(choice).$2)),
          onPick: onPick,
        ),
      ),
    );
  }

  static Future<void> _range(BuildContext context, WidgetRef ref, AyahKey from, AyahKey to) {
    final theme = Theme.of(context);
    return showBmSheet(
      context,
      builder: (_) => Theme(
        data: theme,
        child: _RangeSheet(from: from, to: to),
      ),
    );
  }
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.choices,
    required this.selected,
    required this.label,
    required this.onPick,
    super.key,
  });

  /// a StringsManager key
  final String title;
  final List<T> choices;
  final T selected;
  final _Label Function(T choice) label;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(title),
              for (final choice in choices)
                PickerRow(
                  title: label(choice).$1,
                  args: label(choice).$2,
                  selected: choice == selected,
                  onTap: () {
                    onPick(choice);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// from ayah to ayah in the playing surah, it plays again from the new start
class _RangeSheet extends ConsumerStatefulWidget {
  const _RangeSheet({required this.from, required this.to});

  final AyahKey from;
  final AyahKey to;

  @override
  ConsumerState<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends ConsumerState<_RangeSheet> {
  late var _values = RangeValues(widget.from.ayah.toDouble(), widget.to.ayah.toDouble());

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(quranAssetsProvider).value?.surah(widget.from.surah).ayahs ?? 1;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final (from, to) = (_values.start.round(), _values.end.round());
    return SafeArea(
      top: false,
      child: BottomPadding(
        padding: SpaceManager.s6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(
              StringsManager.range,
              subtitle: StringsManager.ayahRange,
              subtitleArgs: {
                'from': context.formatDigits('$from', digits),
                'to': context.formatDigits('$to', digits),
              },
            ),
            if (total > 1)
              HorizontalPadding(
                padding: SpaceManager.s2,
                child: RangeSlider(
                  values: _values,
                  min: 1,
                  max: total.toDouble(),
                  divisions: total - 1,
                  activeColor: context.getColor(ThemeEnum.primary),
                  inactiveColor: context.getColor(ThemeEnum.variant),
                  onChanged: (values) {
                    if (values.start.round() != from || values.end.round() != to) {
                      BmHaptics.selection();
                    }
                    setState(() => _values = values);
                  },
                  onChangeEnd: (values) => playFrom(
                    context,
                    ref,
                    AyahKey(widget.from.surah, values.start.round()),
                    to: AyahKey(widget.from.surah, values.end.round()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
