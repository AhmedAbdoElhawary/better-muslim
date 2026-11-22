import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/sound_picker.dart';
import 'package:material_ui/material_ui.dart';

/// the adhan sound sheet's round play button, for the tone of a notification channel
class ToneButton extends StatelessWidget {
  const ToneButton(this.channel, {super.key});
  final String channel;

  @override
  Widget build(BuildContext context) {
    return SoundPlayButton(
      label: StringsManager.play,
      onTap: () {
        BmHaptics.selection();
        SystemChannel.playTone(channel);
      },
    );
  }
}
