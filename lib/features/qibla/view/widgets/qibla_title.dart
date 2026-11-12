import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/qibla/model/qibla_tracker.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the instruction and the subtitle. aligned fades in over the turning text (MOTION d_align)
class QiblaTitle extends ConsumerWidget {
  const QiblaTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aligned = ref.watch(qiblaAlignedProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : BmMotion.standard,
      switchInCurve: BmMotion.standardCurve,
      switchOutCurve: BmMotion.standardCurve,
      child: aligned
          ? const _Lines(
              key: ValueKey(QiblaPhase.aligned),
              title: _Title(StringsManager.facingQibla, color: ThemeEnum.onAccentContainer),
              subtitle: _Subtitle(StringsManager.holdSteady),
            )
          : const _Lines(
              key: ValueKey(QiblaPhase.turning),
              title: _Instruction(),
              subtitle: _PlaceLine(),
            ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.title, required this.subtitle, super.key});

  final Widget title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [title, const RSizedBox.vertical(SpaceManager.qiblaTitleGap), subtitle],
    );
  }
}

class _Instruction extends ConsumerWidget {
  const _Instruction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qiblaStateProvider);
    final degrees = ref.watch(turnDegreesProvider);
    final right = ref.watch(qiblaDiffProvider.select((diff) => diff == null || diff >= 0));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return switch (state) {
      QiblaState.noLocation => const _Title(StringsManager.noLocationYet),
      QiblaState.noCompass => const _Title(StringsManager.noCompass),

      /// keeps the title's height, so the dial doesn't jump when the first reading comes (R11)
      QiblaState.waiting => const Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _Title(StringsManager.qibla),
      ),
      QiblaState.ready => _Title(
        right ? StringsManager.turnRight : StringsManager.turnLeft,
        args: {'deg': context.formatDigits('${degrees ?? 0}', digits)},
      ),
    };
  }
}

class _PlaceLine extends ConsumerWidget {
  const _PlaceLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noLocation = ref.watch(qiblaStateProvider) == QiblaState.noLocation;
    final place = ref.watch(
      qiblaPlaceProvider.select((place) => (name: place.value?.name, nameAr: place.value?.nameAr)),
    );
    final bearing = ref.watch(qiblaTargetProvider.select((target) => target?.bearing.round()));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (noLocation) return const _Subtitle(StringsManager.qiblaNeedsLocation);
    if (bearing == null) return const _Subtitle('', translate: false);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return _Subtitle(
      StringsManager.qiblaFrom,
      args: {
        'city': (isArabic ? place.nameAr : null) ?? place.name ?? '',
        'deg': context.formatDigits('${bearing % 360}', digits),
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.color = ThemeEnum.text, this.args = const {}});

  final String text;
  final ThemeEnum color;
  final Map<String, String> args;

  @override
  Widget build(BuildContext context) {
    return RegularText(
      text,
      font: FontEnum.display,
      fontSize: FontSizeManager.qiblaTitle,
      height: LineHeightManager.qiblaTitle,
      color: color,
      args: args,
      textAlign: TextAlign.center,
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text, {this.args = const {}, this.translate = true});

  final String text;
  final Map<String, String> args;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    return RegularText(
      text,
      fontSize: FontSizeManager.secondary,
      color: ThemeEnum.text2,
      args: args,
      translate: translate,
      textAlign: TextAlign.center,
    );
  }
}
