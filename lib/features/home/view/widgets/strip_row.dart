import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/features/home/view/widgets/strip_cell.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// a strip cell laid out as a full width row, for text too large for five columns
class StripRow extends ConsumerWidget {
  const StripRow(this.index, {super.key});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(stripProvider.select((cells) => cells[index]));
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(Routes.prayerAt(ref.read(prayerDayProvider), cell.prayer)),
        child: AnimatedDecoratedBox(
          decoration: StripCell.decoration(context, cell),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.hit.r),
            child: SymmetricPadding(
              horizontal: SpaceManager.s3,
              vertical: SpaceManager.s2,
              child: Row(
                children: [
                  Expanded(
                    child: cell.current
                        ? SemiBoldText(
                            cell.prayer.nameKey,
                            fontSize: FontSizeManager.label,
                            color: cell.now ? ThemeEnum.onPrimaryContainer : ThemeEnum.primary,
                          )
                        : RegularText(
                            cell.prayer.nameKey,
                            fontSize: FontSizeManager.label,
                            color: ThemeEnum.text2,
                          ),
                  ),
                  const RSizedBox.horizontal(SpaceManager.s3),
                  StripTime(cell: cell),
                  const RSizedBox.horizontal(SpaceManager.s2),
                  RSizedBox.square(
                    dimension: SizeManager.stripMarkSlot,
                    child: Center(child: StripMark(cell: cell)),
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
