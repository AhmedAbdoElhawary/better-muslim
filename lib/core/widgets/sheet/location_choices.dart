import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the sheet's two ways in, wherever there is no location yet (home, qibla)
class LocationChoices extends StatelessWidget {
  const LocationChoices({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BmButton.primary(
          StringsManager.useMyLocation,
          onPressed: () => showLocationSheet(context, useMyLocation: true),
        ),
        const RSizedBox.vertical(SpaceManager.s3),
        BmButton.secondary(StringsManager.chooseCity, onPressed: () => showLocationSheet(context)),
      ],
    );
  }
}
