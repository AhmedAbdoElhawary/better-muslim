import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/backup/backup_sheet.dart';
import 'package:better_muslim/core/widgets/backup/pick_and_restore.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the app's own backup file, the only way the data moves to a new phone (FR-028)
class BackupRow extends StatelessWidget {
  const BackupRow({super.key});

  @override
  Widget build(BuildContext context) {
    return NavRow(
      icon: BmIcon.ui(BmUiIcon.lock, size: SizeManager.iconList.r),
      title: StringsManager.backUp,
      onTap: () => showBackupSheet(context),
    );
  }
}

/// the dialog asks first here, this phone has data to lose (FR-032)
class RestoreRow extends StatelessWidget {
  const RestoreRow({super.key});

  @override
  Widget build(BuildContext context) {
    return NavRow(
      icon: BmIcon.ui(BmUiIcon.repeat, size: SizeManager.iconList.r),
      title: StringsManager.restoreBackup,
      onTap: () async {
        if (await pickAndRestore(context, confirm: true) && context.mounted) {
          showToast(context, StringsManager.backupRestored);
        }
      },
    );
  }
}
