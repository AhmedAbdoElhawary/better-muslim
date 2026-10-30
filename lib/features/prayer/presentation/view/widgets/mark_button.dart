import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/state_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Motion 07: the "Mark" pill turns into the "Prayed" chip on a snappy spring and the check
/// draws in, with the haptic once it is full. "Prayed" is a toggle, a tap undoes it
class MarkButton extends ConsumerStatefulWidget {
  const MarkButton({required this.prayed, required this.onTap, super.key});
  final bool prayed;
  final VoidCallback onTap;

  @override
  ConsumerState<MarkButton> createState() => _MarkButtonState();
}

class _MarkButtonState extends ConsumerState<MarkButton> with TickerProviderStateMixin {
  /// the check starts 100 ms into the spring and draws for 220 ms
  static const _checkDelay = Duration(milliseconds: 100);
  static const _from = .78;

  late final _scale = AnimationController.unbounded(vsync: this, value: 1);
  late final _check =
      AnimationController(vsync: this, duration: _checkDelay + BmMotion.checkStroke, value: 1)
        ..addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          BmHaptics.markPrayed();
          BmSounds.prayed();
        });

  late final _checkProgress = CurvedAnimation(
    parent: _check,
    curve: Interval(
      _checkDelay.inMilliseconds / (_checkDelay + BmMotion.checkStroke).inMilliseconds,
      1,
      curve: BmMotion.standardCurve,
    ),
  );

  bool get _reduceMotion =>
      context.reduceMotion(ref.read(settingsProvider).value?.reduceMotion ?? false);

  @override
  void didUpdateWidget(MarkButton old) {
    super.didUpdateWidget(old);
    if (old.prayed || !widget.prayed) return;
    if (_reduceMotion) {
      /// meaning stays: the check is there and the haptic still fires
      BmHaptics.markPrayed();
      BmSounds.prayed();
      return;
    }
    _scale.animateWith(SpringSimulation(BmMotion.snappy, _from, 1, 0));
    _check.forward(from: 0);
  }

  @override
  void dispose() {
    _checkProgress.dispose();
    _scale.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = context.reduceMotion(
      ref.watch(settingsProvider.select((settings) => settings.value?.reduceMotion ?? false)),
    );
    return Semantics(
      button: true,
      checked: widget.prayed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r, minWidth: SizeManager.hit.r),
          child: Center(
            widthFactor: 1,
            child: AnimatedSwitcher(
              duration: reduceMotion ? BmMotion.micro : Duration.zero,
              child: widget.prayed
                  ? ScaleTransition(
                      key: const ValueKey(true),
                      scale: _scale,
                      child: StateChip(
                        StringsManager.prayed,
                        check: true,
                        checkProgress: _checkProgress,
                      ),
                    )
                  : const _MarkPill(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPill extends StatelessWidget {
  const _MarkPill();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.markChip.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.primary),
          borderRadius: BorderRadius.circular(RadiusManager.pill.r),
        ),
        child: OnlyPadding(
          start: SpaceManager.markStart,
          end: SpaceManager.s3,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckMark(size: SizeManager.iconInline, color: context.getColor(ThemeEnum.onPrimary)),
              const RSizedBox.horizontal(SpaceManager.s1),
              const MediumText(
                StringsManager.mark,
                fontSize: FontSizeManager.caption,
                color: ThemeEnum.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
