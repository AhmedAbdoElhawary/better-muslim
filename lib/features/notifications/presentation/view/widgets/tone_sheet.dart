import 'dart:async';

import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/sound_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showToneSheet(BuildContext context, Prayer prayer) => showBmSheet(
  context,
  title: SheetTitle(
    StringsManager.toneSound,
    subtitle: StringsManager.forPrayer,
    subtitleArgs: {'prayer': context.tr(prayer.nameKey)},
  ),
  builder: (_) => _ToneSheet(prayer),
);

/// like the adhan sound sheet: a tap picks and plays, only save keeps it
class _ToneSheet extends ConsumerStatefulWidget {
  const _ToneSheet(this.prayer);
  final Prayer prayer;

  @override
  ConsumerState<_ToneSheet> createState() => _ToneSheetState();
}

class _ToneSheetState extends ConsumerState<_ToneSheet> {
  late PrayerTone _picked =
      ref.read(settingsProvider).value?.toneOf(widget.prayer) ?? PrayerTone.phone;
  late final ClipPlayer _player;
  late final AudioUseNotifier _use;
  late final StreamSubscription<void> _ended;
  PrayerTone? _playing;

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
  void _setPlaying(PrayerTone? tone) {
    setState(() => _playing = tone);
    tone == null ? _use.release(AudioUse.clip) : _use.claim(AudioUse.clip);
  }

  Future<void> _play(PrayerTone tone) async {
    BmHaptics.selection();
    setState(() => _picked = tone);
    final file = tone.file;
    if (file == null) {
      if (_playing != null) await _stop();

      /// the phone's own sound, or the one I set for this prayer in android's settings
      return SystemChannel.playTone(
        NotificationScheduler.channelId(widget.prayer, PrayerSound.tone, AdhanRecording.alafasy),
      );
    }
    _setPlaying(tone);
    await _player.stop();
    try {
      await _player.play('assets/audio/$file.m4a');
    } on PlayerException {
      /// no audio output (a simulator after the mac's output changed), the row goes back to play
      if (mounted && _playing == tone) _setPlaying(null);
    }
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
            for (final tone in PrayerTone.values)
              SoundRow(
                title: tone.nameKey,
                picked: tone == _picked,
                onTap: () => _play(tone),
                trailing: SoundPlayButton(
                  label: tone == _playing ? StringsManager.stop : StringsManager.play,
                  icon: tone == _playing ? BmUiIcon.stop : BmUiIcon.play,
                  onTap: () => tone == _playing ? _stop() : _play(tone),
                ),
              ),
            OnlyPadding(
              start: SpaceManager.s5,
              end: SpaceManager.s5,
              top: SpaceManager.s3,
              bottom: SpaceManager.s6,
              child: BmButton.primary(
                StringsManager.save,
                onPressed: () {
                  ref.read(databaseProvider).updateSettings(toneChoice(widget.prayer, _picked));
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
