import 'dart:async';

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showRecordingSheet(BuildContext context, Prayer prayer) => showBmSheet(
  context,
  title: SheetTitle(
    StringsManager.adhanSound,
    subtitle: StringsManager.forPrayer,
    subtitleArgs: {'prayer': context.tr(prayer.nameKey)},
  ),
  builder: (_) => _RecordingSheet(prayer),
);

/// the components' "Adhan sound" sheet: a tap picks and plays, only save keeps it (FR-027)
class _RecordingSheet extends ConsumerStatefulWidget {
  const _RecordingSheet(this.prayer);
  final Prayer prayer;

  @override
  ConsumerState<_RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends ConsumerState<_RecordingSheet> {
  late AdhanRecording _picked =
      ref.read(settingsProvider).value?.recordingOf(widget.prayer) ?? AdhanRecording.alafasy;
  late final ClipPlayer _player;
  late final StreamSubscription<void> _ended;
  AdhanRecording? _playing;

  @override
  void initState() {
    super.initState();
    _player = ref.read(clipPlayerProvider);
    _ended = _player.ended.listen((_) => setState(() => _playing = null));
  }

  @override
  void dispose() {
    _ended.cancel();
    _player.stop();
    super.dispose();
  }

  Future<void> _play(AdhanRecording recording) async {
    BmHaptics.selection();
    setState(() {
      _picked = recording;
      _playing = recording;
    });
    await _player.stop();

    /// fajr always previews and plays the recording's fajr variant
    await _player.play(recording.fullAsset(widget.prayer));
  }

  /// downloaded on the first tap, then it picks and plays like the others
  Future<void> _pick(AdhanRecording recording) async {
    if (ref.read(adhanDownloadProvider(recording)).ready) return _play(recording);
    BmHaptics.selection();
    try {
      await ref.read(adhanDownloadProvider(recording).notifier).download();
    } on DownloadException catch (error) {
      if (!mounted || error.failure == DownloadFailure.cancelled) return;
      showToast(
        context,
        error.failure == DownloadFailure.offline
            ? StringsManager.needsInternetOnce
            : StringsManager.downloadFailed,
        icon: BmIconName.adhan,
      );
      return;
    }
    if (mounted) await _play(recording);
  }

  Future<void> _stop() async {
    setState(() => _playing = null);
    await _player.stop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final recording in AdhanRecording.values)
              _RecordingRow(
                recording,
                length: recording.lengthOf(widget.prayer),
                picked: recording == _picked,
                playing: recording == _playing,
                onTap: () => _pick(recording),
                onPlay: () => recording == _playing ? _stop() : _pick(recording),
              ),
            OnlyPadding(
              start: SpaceManager.s5,
              end: SpaceManager.s5,
              top: SpaceManager.s3,
              bottom: SpaceManager.s6,
              child: BmButton.primary(
                StringsManager.save,
                onPressed: () {
                  ref
                      .read(databaseProvider)
                      .updateSettings(recordingChoice(widget.prayer, _picked));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingRow extends ConsumerWidget {
  const _RecordingRow(
    this.recording, {
    required this.length,
    required this.picked,
    required this.playing,
    required this.onTap,
    required this.onPlay,
  });

  final AdhanRecording recording;
  final String length;
  final bool picked;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Semantics(
      button: true,
      selected: picked,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.pickerRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.s6,
            vertical: SpaceManager.s1,
            child: Row(
              children: [
                _Radio(picked),
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RegularText(recording.nameKey, fontSize: FontSizeManager.body),
                      const RSizedBox.vertical(SpaceManager.rowLineGap),
                      RegularText(
                        StringsManager.fullAdhanLength,
                        args: {'length': context.formatDigits(length, digits)},
                        fontSize: FontSizeManager.rowSubtitle,
                        color: ThemeEnum.text2,
                      ),
                    ],
                  ),
                ),
                _PlayButton(recording, playing: playing, onTap: onPlay),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio(this.picked);
  final bool picked;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.radio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.getColor(picked ? ThemeEnum.primary : ThemeEnum.outlineStrong),
            width: (picked ? SizeManager.radioRing : SizeManager.radioRingOff).r,
          ),
        ),
        child: picked
            ? Center(
                child: RSizedBox.square(
                  dimension: SizeManager.radioDot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.getColor(ThemeEnum.primary),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// play, or download first with its progress, a tap while downloading stops it
class _PlayButton extends ConsumerWidget {
  const _PlayButton(this.recording, {required this.playing, required this.onTap});
  final AdhanRecording recording;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(adhanDownloadProvider(recording));
    final label = status.downloading
        ? StringsManager.cancel
        : !status.ready
        ? StringsManager.download
        : playing
        ? StringsManager.stop
        : StringsManager.play;
    return Semantics(
      button: true,
      label: context.tr(label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: status.downloading
            ? ref.read(adhanDownloadProvider(recording).notifier).cancel
            : onTap,
        child: RSizedBox.square(
          dimension: SizeManager.playButton,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.getColor(ThemeEnum.variant),
            ),
            child: Center(
              child: status.downloading
                  ? BmStarLoader(size: SizeManager.loaderInline, progress: status.progress)
                  : BmIcon.ui(
                      !status.ready
                          ? BmUiIcon.download
                          : playing
                          ? BmUiIcon.stop
                          : BmUiIcon.play,
                      size: SizeManager.iconList.r,
                      color: context.getColor(ThemeEnum.text),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
