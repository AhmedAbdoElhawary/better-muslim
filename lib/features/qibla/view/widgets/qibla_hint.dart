import 'package:better_muslim/core/qibla/compass.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/location_choices.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// the designed hint, the figure 8 at low accuracy, or the way to a location
class QiblaHint extends ConsumerWidget {
  const QiblaHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qiblaStateProvider);
    final low = ref.watch(
      compassProvider.select((reading) => reading.value?.accuracy == CompassAccuracy.low),
    );
    return switch (state) {
      QiblaState.noLocation => const LocationChoices(),
      QiblaState.noCompass => const _Hint(StringsManager.noCompassHint),
      _ when low => const _Hint(StringsManager.calibrateHint),
      _ => const _Hint(StringsManager.holdFlat),
    };
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  /// a StringsManager key
  final String text;

  @override
  Widget build(BuildContext context) {
    return RegularText(
      text,
      height: LineHeightManager.qiblaHint,
      color: ThemeEnum.text2,
      textAlign: TextAlign.center,
    );
  }
}
