import 'dart:ui';

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/features/notifications/data/dua_after_adhan.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_tint.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/dua_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// "After the adhan", the dua's first line and its translation, read dua opens the rest
class AdhanDuaCard extends StatelessWidget {
  const AdhanDuaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    /// the whole card opens the dua, "read dua" alone is too small to tap
    return Semantics(
      button: true,
      label: context.tr(StringsManager.readDua),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showBmSheet<void>(context, builder: (_) => const DuaSheet()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusManager.lg.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AdhanColors.card,
                border: Border(top: BorderSide(color: AdhanColors.cardHighlight)),
              ),
              child: SymmetricPadding(
                vertical: SpaceManager.adhanCardV,
                horizontal: SpaceManager.adhanCardH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdhanTint(AdhanColors.cream, child: _CardTop()),
                    const RSizedBox.vertical(SpaceManager.adhanCardGap),
                    const Directionality(
                      textDirection: TextDirection.rtl,
                      child: RegularText(
                        DuaAfterAdhan.firstLine,
                        translate: false,
                        font: FontEnum.dua,
                        fontSize: FontSizeManager.adhanDua,
                        height: LineHeightManager.adhanDua,
                        color: null,
                      ),
                    ),
                    if (!isArabic) ...[
                      const RSizedBox.vertical(SpaceManager.adhanCardGap),
                      const AdhanTint(
                        AdhanColors.translation,
                        child: RegularText(
                          DuaAfterAdhan.firstTranslation,
                          translate: false,
                          height: LineHeightManager.body,
                          color: null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTop extends StatelessWidget {
  const _CardTop();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: RegularText(DuaAfterAdhan.titleKey, fontSize: FontSizeManager.label, color: null),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RegularText(StringsManager.readDua, fontSize: FontSizeManager.label, color: null),
            const RSizedBox.horizontal(SpaceManager.adhanReadDuaGap),
            Transform.flip(
              flipX: isRtl,
              child: BmIcon.ui(BmUiIcon.forward, size: SizeManager.iconChip.r),
            ),
          ],
        ),
      ],
    );
  }
}
