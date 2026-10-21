import 'dart:ui';

import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the glass pill on the sky. its hit area is 44 tall around the 32 pt drawing
class LocationPill extends ConsumerWidget {
  const LocationPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      locationProvider.select(
        (location) => (name: location?.placeName, nameAr: location?.placeNameAr),
      ),
    );
    final bright = ref.watch(skyBrightProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = (isArabic ? place.nameAr : null) ?? place.name;
    final color = bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showLocationSheet(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            widthFactor: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusManager.pill.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.getColor(ThemeEnum.glass),
                    border: Border(
                      top: BorderSide(color: context.getColor(ThemeEnum.glassHighlight)),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.locationPill.r),
                    child: OnlyPadding(
                      start: SpaceManager.locationPillStart,
                      end: SpaceManager.locationPillEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BmIcon(
                            BmIconName.location,
                            size: SizeManager.locationPillIcon.r,
                            color: context.getColor(color),
                          ),
                          const RSizedBox.horizontal(SpaceManager.s1),
                          Flexible(
                            child: BmSwitcher(
                              child: name == null
                                  ? RegularText(
                                      StringsManager.noLocationYet,
                                      key: const ValueKey(null),
                                      color: color,
                                      maxLines: 1,
                                    )
                                  : RegularText(
                                      name,
                                      key: ValueKey(name),
                                      translate: false,
                                      color: color,
                                      maxLines: 1,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
