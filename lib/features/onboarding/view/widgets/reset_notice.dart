import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/backup/pick_and_restore.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// the saved data couldn't be opened and the app started fresh (milestone 2 FR-024). told once,
/// whatever the answer (FR-036)
Future<void> showResetNotice(BuildContext context) async {
  final db = ProviderScope.containerOf(context, listen: false).read(databaseProvider);
  final restore = await showBmDialog(
    context,
    title: StringsManager.resetNoticeTitle,
    body: StringsManager.resetNoticeBody,
    action: StringsManager.restoreBackup,
    cancel: StringsManager.startFresh,
    destructive: false,
  );
  await db.updateSettings(const SettingsCompanion(storeResetPending: Value(false)));
  if (!restore || !context.mounted) return;
  if (await pickAndRestore(context, confirm: false) && context.mounted) {
    context.push(Routes.onboardingLocation);
  }
}
