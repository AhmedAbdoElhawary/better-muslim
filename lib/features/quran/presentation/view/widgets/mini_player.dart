import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_text.dart' show bmStackedLayoutTextScale;
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/motion/loader_gate.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// "1.0×", "1.25×"
String speedLabel(BuildContext context, double speed, Digits digits) => context.formatDigits(
  speed == speed.roundToDouble() ? speed.toStringAsFixed(1) : '$speed',
  digits,
);

/// the playing surah and ayah in the app's language and digits, the bismillah reads as ayah 1
class PlayingTitle extends ConsumerWidget {
  const PlayingTitle({this.fontSize = FontSizeManager.miniPlayerTitle, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayah = ref.watch(playingAyahProvider);
    final surah = ayah == null ? null : ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return MediumText(
      StringsManager.quranAyahN,
      fontSize: fontSize,
      maxLines: 1,
      args: {
        'surah': surah == null ? '' : (isArabic ? surah.ar : surah.en),
        'n': context.formatDigits('${ayah == null ? '' : readAyah(ayah).ayah}', digits),
      },
    );
  }
}

/// rises from below when a recitation starts and over the dock when the controls show (FR-025).
/// media controls stay left to right in arabic (FR-029)
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({required this.card, this.activeDy = 0, required this.onOpen, super.key});

  /// the page's card spring, the dock is up at 1
  final Animation<double> card;
  final VoidCallback onOpen;
  final double activeDy;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      recitationStateProvider.select((state) => state.value?.active ?? false),
    );
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    /// its own layer, the card's spring and its rise only move it
    final player = RepaintBoundary(
      child: IgnorePointer(
        ignoring: !active,
        child: OnlyPadding(
          start: SpaceManager.miniPlayerSide,
          end: SpaceManager.miniPlayerSide,
          bottom: SpaceManager.miniPlayerBottom,
          child: _Player(onOpen: onOpen),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: card,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          -card.value.clamp(0.0, 1.0) *
              (SizeManager.dock.r + bottom - SpaceManager.miniPlayerBottom.r),
        ),
        child: child,
      ),
      child: reduce
          ? AnimatedOpacity(opacity: active ? 1 : 0, duration: BmMotion.micro, child: player)
          : AnimatedSlide(
              offset: Offset(0, active ? activeDy : 3),
              duration: BmMotion.standard,
              curve: active ? BmMotion.decelerate : BmMotion.accelerate,
              child: player,
            ),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(recitationStateProvider.select((state) => state.value?.speed ?? 1));
    final reciter = ref.watch(
      recitationStateProvider.select((state) => state.value?.reciter ?? Reciter.alafasy),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final recitation = ref.watch(recitationProvider);
    final direction = Directionality.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusManager.miniPlayer.r),
        boxShadow: [
          BoxShadow(
            color: context.getColor(ThemeEnum.scrim).withValues(alpha: .4),
            blurRadius: SizeManager.miniPlayerShadowBlur.r,
            offset: Offset(0, SizeManager.miniPlayerShadowY.r),
            spreadRadius: SizeManager.miniPlayerShadowSpread.r,
          ),
        ],
      ),
      child: ReaderGlass(
        radius: RadiusManager.miniPlayer,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: SizeManager.ayahAction.r),
          child: OnlyPadding(
            start: SpaceManager.miniPlayerStart,
            end: SpaceManager.miniPlayerEnd,
            top: SpaceManager.s1,
            bottom: SpaceManager.s1,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  const PlayButton(),
                  const RSizedBox.horizontal(SpaceManager.s3),
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onOpen,
                        child: Directionality(
                          textDirection: direction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PlayingTitle(),
                              if (MediaQuery.textScalerOf(context).scale(1) <=
                                  bmStackedLayoutTextScale) ...[
                                const RSizedBox.vertical(SpaceManager.miniPlayerLineGap),
                                RegularText(
                                  StringsManager.reciterRate,
                                  fontSize: FontSizeManager.label,
                                  color: ThemeEnum.text2,
                                  maxLines: 1,
                                  args: {
                                    'reciter': context.tr(reciter.short),
                                    'rate': speedLabel(context, speed, digits),
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _IconButton(
                    icon: BmUiIcon.next,
                    label: StringsManager.nextAyah,
                    onTap: () {
                      ref.read(followingProvider.notifier).set(true);
                      recitation.next();
                    },
                  ),
                  _IconButton(
                    icon: BmUiIcon.close,
                    label: StringsManager.stop,
                    onTap: recitation.stop,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// the primary circle, play or pause, the 16 pt star in it while a file loads
class PlayButton extends ConsumerWidget {
  const PlayButton({
    this.size = SizeManager.hit,
    this.icon = SizeManager.miniPlayerIcon,
    super.key,
  });

  final double size;
  final double icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      recitationStateProvider.select((state) => state.value?.status ?? RecitationStatus.idle),
    );
    final recitation = ref.watch(recitationProvider);
    final playing = status == RecitationStatus.playing;
    final color = context.getColor(ThemeEnum.onPrimary);
    return Semantics(
      button: true,
      label: context.tr(playing ? StringsManager.pause : StringsManager.play),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: playing ? recitation.pause : recitation.resume,
        child: RSizedBox.square(
          dimension: size,
          child: BmLoaderGate(
            loading: status == RecitationStatus.loading,
            loader: const Center(child: BmStarLoader(size: SizeManager.loaderSmall)),
            child: Center(
              child: BmIcon.ui(
                playing ? BmUiIcon.pause : BmUiIcon.play,
                size: icon.r,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.label, required this.onTap});

  final BmUiIcon icon;

  /// a StringsManager key
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(child: BmIcon.ui(icon, color: context.getColor(ThemeEnum.text))),
        ),
      ),
    );
  }
}
