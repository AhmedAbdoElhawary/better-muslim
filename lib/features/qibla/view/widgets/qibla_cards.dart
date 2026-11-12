import 'package:better_muslim/core/qibla/compass.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dot.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

const _dash = '—';

/// the distance to the kaaba and the compass accuracy, side by side
class QiblaCards extends StatelessWidget {
  const QiblaCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Card(value: _Distance(), note: StringsManager.toTheKaaba),
          ),
          RSizedBox.horizontal(SpaceManager.qiblaCardGap),
          Expanded(
            child: _Card(value: _Accuracy(), note: StringsManager.compassAccuracy),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.value, required this.note});

  final Widget value;

  /// a StringsManager key
  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.surface),
        borderRadius: BorderRadius.circular(RadiusManager.lg.r),
        border: Border.all(color: context.getColor(ThemeEnum.outline)),
      ),
      child: SymmetricPadding(
        horizontal: SpaceManager.qiblaCardH,
        vertical: SpaceManager.qiblaCardV,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            value,
            const RSizedBox.vertical(SpaceManager.qiblaCardLineGap),
            RegularText(note, fontSize: FontSizeManager.cardNote, color: ThemeEnum.text2),
          ],
        ),
      ),
    );
  }
}

class _Distance extends ConsumerWidget {
  const _Distance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final km = ref.watch(qiblaTargetProvider.select((target) => target?.distanceKm));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (km == null) return const _Value(_dash, translate: false);
    final (:key, :value) = formatDistance(
      km,
      language: Localizations.localeOf(context).languageCode,
      digits: digits,
    );
    return _Value(key, args: {'distance': value});
  }
}

class _Accuracy extends ConsumerWidget {
  const _Accuracy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:loaded, :accuracy) = ref.watch(
      compassProvider.select(
        (reading) => (loaded: reading.hasValue, accuracy: reading.value?.accuracy),
      ),
    );
    if (!loaded) return const _Value(_dash, translate: false);
    if (accuracy == null) return const _Value(StringsManager.accuracyNone);
    return Row(
      children: [
        QiblaDot(
          size: SizeManager.accuracyDot,
          color: switch (accuracy) {
            CompassAccuracy.high => ThemeEnum.success,
            CompassAccuracy.medium => ThemeEnum.warning,
            CompassAccuracy.low => ThemeEnum.error,
          },
        ),
        const RSizedBox.horizontal(SpaceManager.accuracyDotGap),
        Flexible(child: _Value(accuracy.key)),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.args = const {}, this.translate = true});

  final String text;
  final Map<String, String> args;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    return MediumText(
      text,
      fontSize: FontSizeManager.qiblaValue,
      args: args,
      translate: translate,
      tabularFigures: true,
    );
  }
}
