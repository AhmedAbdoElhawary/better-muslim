import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/dua_text.dart';
import 'package:better_muslim/core/widgets/rolling_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' azkar card. quran text never moves, the count tap only changes the numbers
class ZikrCard extends StatelessWidget {
  const ZikrCard({
    required this.zikr,
    required this.setKey,
    required this.index,
    required this.total,
    required this.count,
    required this.digits,
    this.complete = false,
    super.key,
  });
  final Zikr zikr;

  /// the set's title key, for "{set} · {index} of {total}"
  final String setKey;
  final int index;
  final int total;
  final int count;
  final Digits digits;

  /// every card of the set is done, the header says so
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final done = count >= zikr.count;
    String digitsOf(int value) => context.formatDigits('$value', digits);
    final progress = '${digitsOf(count)} / ${digitsOf(zikr.count)}';
    return MergeSemantics(
      child: Semantics(
        value:
            '${digitsOf(count)} ${context.tr(StringsManager.ofTarget, {'target': digitsOf(zikr.count)})}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.raised),
            borderRadius: BorderRadius.circular(RadiusManager.lg.r),
            boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
          ),
          child: SymmetricPadding(
            vertical: SpaceManager.zikrCardV,
            horizontal: SpaceManager.s5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BmSwitcher(
                        child: complete
                            ? const RegularText(
                                StringsManager.setComplete,
                                key: ValueKey(true),
                                fontSize: FontSizeManager.label,
                                color: ThemeEnum.primary,
                              )
                            : RegularText(
                                StringsManager.setCardHeader,
                                key: const ValueKey(false),
                                args: {
                                  'set': context.tr(setKey),
                                  'index': digitsOf(index + 1),
                                  'total': digitsOf(total),
                                },
                                fontSize: FontSizeManager.label,
                                color: ThemeEnum.text2,
                              ),
                      ),
                    ),
                    BmSwitcher(
                      child: done
                          ? EndPadding(
                              padding: SpaceManager.s1,
                              child: BmIcon.ui(
                                BmUiIcon.check,
                                size: SizeManager.iconInline.r,
                                color: context.getColor(ThemeEnum.primary),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: RollingDigit(
                        progress,
                        child: MediumText(
                          progress,
                          translate: false,
                          fontSize: FontSizeManager.caption,
                          color: ThemeEnum.primary,
                          tabularFigures: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const RSizedBox.vertical(SpaceManager.s3),
                DuaText.zikr(
                  arabic: zikr.arabic,
                  transliteration: zikr.transliteration,
                  translation: zikr.translation,
                  quran: zikr.quran,
                ),
                const RSizedBox.vertical(SpaceManager.s3),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.getColor(ThemeEnum.outline))),
                  ),
                  child: TopPadding(
                    padding: SpaceManager.zikrFooterTop,
                    child: Row(
                      children: [
                        Expanded(
                          child: RegularText(
                            sourceLine(zikr.source, zikr.grading, language),
                            translate: false,
                            fontSize: FontSizeManager.label,
                            color: ThemeEnum.text2,
                          ),
                        ),
                        const RSizedBox.horizontal(SpaceManager.s3),
                        _ZikrBar(count / zikr.count),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikrBar extends StatelessWidget {
  const _ZikrBar(this.share);
  final double share;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusManager.zikrBar.r);
    return Container(
      width: SizeManager.zikrBarW.r,
      height: SizeManager.zikrBarH.r,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(color: context.getColor(ThemeEnum.variant), borderRadius: radius),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: share),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.standard,
        curve: BmMotion.standardCurve,
        builder: (context, share, _) => FractionallySizedBox(
          widthFactor: share,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.getColor(ThemeEnum.primary),
              borderRadius: radius,
            ),
          ),
        ),
      ),
    );
  }
}
