import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// clears the prayer log and qada only, after the dialog asks (FR-032)
class ResetRow extends ConsumerWidget {
  const ResetRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavRow(
      icon: BmIcon.ui(BmUiIcon.reset, size: SizeManager.iconList.r),
      title: StringsManager.resetJourney,
      onTap: () async {
        final confirmed = await showBmDialog(
          context,
          title: StringsManager.resetJourneyTitle,
          body: StringsManager.resetJourneyBody,
          action: StringsManager.reset,
        );
        if (!confirmed) return;
        await ref.read(databaseProvider).resetPrayerJourney();

        /// an undo from the prayer tab would bring a cleared row back
        hideToast();
      },
    );
  }
}
