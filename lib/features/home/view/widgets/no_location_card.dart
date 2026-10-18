import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/features/home/view/widgets/home_card.dart';
import 'package:better_muslim/features/home/view/widgets/location_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// in place of the next-prayer card while there is no location, with the sheet's two choices
class NoLocationCard extends StatelessWidget {
  const NoLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: AllPadding(
        padding: SpaceManager.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RegularText(StringsManager.noLocationBody),
            const RSizedBox.vertical(SpaceManager.s4),
            BmButton.primary(
              StringsManager.useMyLocation,
              onPressed: () => showLocationSheet(context, useMyLocation: true),
            ),
            const RSizedBox.vertical(SpaceManager.s3),
            BmButton.secondary(
              StringsManager.chooseCity,
              onPressed: () => showLocationSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
