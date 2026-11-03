import 'dart:async';

import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/sound_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRecordingSheet(BuildContext context, Prayer prayer) => showBmSheet(
  context,
  title: SheetTitle(
    StringsManager.adhanSound,
    subtitle: StringsManager.forPrayer,
    subtitleArgs: {'prayer': context.tr(prayer.nameKey)},
  ),
  builder: (_) => _RecordingSheet(prayer),
);

/// the components' "Adhan sound" sheet: full or takbir, a tap picks and plays, only save keeps it
/// (FR-027)
class _RecordingSheet extends ConsumerStatefulWidget {
  const _RecordingSheet(this.prayer);
  final Prayer prayer;

  @override
  ConsumerState<_RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends ConsumerState<_RecordingSheet> {
  late AdhanRecording _picked =
      ref.read(settingsProvider).value?.recordingOf(widget.prayer) ?? AdhanRecording.alafasy;
  late AdhanLength _length =
      ref.read(settingsProvider).value?.adhanLengthOf(widget.prayer) ?? AdhanLength.full;
  late final ClipPlayer _player;
  late final AudioUseNotifier _use;
  late final StreamSubscription<void> _ended;
  AdhanRecording? _playing;

  @override
  void initState() {
    super.initState();
    _player = ref.read(clipPlayerProvider);
    _use = ref.read(audioUseProvider.notifier);
    _ended = _player.ended.listen((_) => _setPlaying(null));
    ref.listenManual(audioUseProvider, (_, use) {
      if (_playing != null && (use == AudioUse.recitation || use == AudioUse.adhan)) _stop();
    });
  }

  @override
  void dispose() {
    _ended.cancel();
    _player.stop();

    /// riverpod lets no widget change a provider while the tree builds
    if (_playing != null) Future(() => _use.release(AudioUse.clip));
    super.dispose();
  }

  /// the quran pauses while a preview plays and comes back after
  void _setPlaying(AdhanRecording? recording) {
    setState(() => _playing = recording);
    recording == null ? _use.release(AudioUse.clip) : _use.claim(AudioUse.clip);
  }

  Future<void> _play(AdhanRecording recording) async {
    BmHaptics.selection();
    setState(() => _picked = recording);
    _setPlaying(recording);
    await _player.stop();

    /// fajr always previews and plays the recording's fajr variant
    await _player.play(
      recording.fullAsset(widget.prayer),
      end: _length == AdhanLength.takbir ? recording.clipLengthOf(widget.prayer) : null,
    );
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
    _setPlaying(null);
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
            SymmetricPadding(
              horizontal: SpaceManager.s5,
              vertical: SpaceManager.s2,
              child: Segmented(
                values: AdhanLength.values,
                selected: _length,
                labelOf: (length) => length.nameKey,
                onChanged: (length) {
                  if (_playing != null) _stop();
                  setState(() => _length = length);
                },
              ),
            ),
            for (final recording in AdhanRecording.values)
              _RecordingRow(
                recording,
                takbir: _length == AdhanLength.takbir,
                length: _length == AdhanLength.takbir
                    ? recording.clipLabelOf(widget.prayer)
                    : recording.lengthOf(widget.prayer),
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
                      .updateSettings(recordingChoice(widget.prayer, _picked, _length));
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
    required this.takbir,
    required this.length,
    required this.picked,
    required this.playing,
    required this.onTap,
    required this.onPlay,
  });

  final AdhanRecording recording;
  final bool takbir;
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
    return SoundRow(
      title: recording.nameKey,
      subtitle: takbir ? StringsManager.takbirLength : StringsManager.fullAdhanLength,
      subtitleArgs: {'length': context.formatDigits(length, digits)},
      picked: picked,
      onTap: onTap,
      trailing: _PlayButton(recording, playing: playing, onTap: onPlay),
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
    return SoundPlayButton(
      label: label,
      icon: !status.ready
          ? BmUiIcon.download
          : playing
          ? BmUiIcon.stop
          : BmUiIcon.play,
      onTap: status.downloading
          ? ref.read(adhanDownloadProvider(recording).notifier).cancel
          : onTap,
      child: status.downloading
          ? BmStarLoader(size: SizeManager.loaderInline, progress: status.progress)
          : null,
    );
  }
}
