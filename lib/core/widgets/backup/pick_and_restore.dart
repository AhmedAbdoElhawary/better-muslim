import 'dart:io';

import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/backup/restore_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the phone's file picker, any type: a custom extension on ios needs a declared document type.
/// the tests replace it
final backupPickerProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final path = (await FilePicker.pickFile())?.path;
    return path == null ? null : File(path);
  },
);

/// the one restore for 4.10, more and the reset notice: pick, password, restore. true once it
/// restored (FR-031 to FR-033)
Future<bool> pickAndRestore(BuildContext context, {required bool confirm}) async {
  final file = await ProviderScope.containerOf(context, listen: false).read(backupPickerProvider)();
  if (file == null || !context.mounted) return false;
  final restored = await showBmSheet<bool>(
    context,
    title: const SheetTitle(
      StringsManager.restoreBackup,
      subtitle: StringsManager.restorePasswordNote,
    ),
    builder: (_) => RestoreSheet(file: file, confirm: confirm),
  );
  return restored ?? false;
}
