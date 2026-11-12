import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/location_choices.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// in place of the next-prayer card while there is no location, with the sheet's two choices
class NoLocationCard extends StatelessWidget {
  const NoLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: AllPadding(
        padding: SpaceManager.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegularText(StringsManager.noLocationBody),
            RSizedBox.vertical(SpaceManager.s4),
            LocationChoices(),
          ],
        ),
      ),
    );
  }
}
