import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/features/quran/presentation/providers/tafsir_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// K.chip of _gen/kit.js, the study tabs' and the share sheet's text picks. a tafsir not on the
/// phone yet carries a download mark, then its progress
class TafsirChip extends StatelessWidget {
  const TafsirChip(
    this.label, {
    required this.selected,
    required this.onTap,
    this.status = (ready: true, downloading: false, progress: null),
    super.key,
  });

  /// a StringsManager key
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TafsirStatus status;

  @override
  Widget build(BuildContext context) {
    final primary = context.getColor(ThemeEnum.primary);
    final color = selected ? ThemeEnum.onPrimaryContainer : ThemeEnum.text2;
    return Semantics(
      button: true,
      selected: selected,
      hint: status.ready ? null : context.tr(StringsManager.download),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          BmHaptics.selection();
          onTap();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            child: Container(
              constraints: BoxConstraints(minHeight: SizeManager.tafsirChip.r),
              padding: REdgeInsets.symmetric(horizontal: SpaceManager.duaChipSide),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.getColor(
                  selected ? ThemeEnum.primaryContainer : ThemeEnum.transparent,
                ),
                borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                border: Border.all(
                  color: selected
                      ? primary.withValues(alpha: .5)
                      : context.getColor(ThemeEnum.outline),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    SemiBoldText(label, fontSize: FontSizeManager.tafsirChip, color: color)
                  else
                    RegularText(label, fontSize: FontSizeManager.tafsirChip, color: color),
                  if (status.downloading) ...[
                    const RSizedBox.horizontal(SpaceManager.s1),
                    BmStarLoader(size: SizeManager.loaderSmall, progress: status.progress),
                  ] else if (!status.ready) ...[
                    const RSizedBox.horizontal(SpaceManager.s1),
                    BmIcon.ui(
                      BmUiIcon.download,
                      size: SizeManager.iconChip.r,
                      color: context.getColor(color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
