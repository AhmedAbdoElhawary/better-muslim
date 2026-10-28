import 'dart:io';

import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/backup/restore.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the picked file's password, then the restore. pops true once this phone has the backup's data
class RestoreSheet extends ConsumerStatefulWidget {
  const RestoreSheet({required this.file, required this.confirm, super.key});

  final File file;

  /// from more there is data to lose, so a dialog asks first (FR-032)
  final bool confirm;

  @override
  ConsumerState<RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends ConsumerState<RestoreSheet> {
  var _password = '';
  var _busy = false;
  BackupError? _error;

  /// a file that isn't a backup, or one this app can't read, says so before any password. a
  /// backup is small, read when the sheet opens
  late final _header = checkBackup(
    widget.file.readAsBytesSync(),
    schemaVersion: ref.read(databaseProvider).schemaVersion,
  );

  bool get _canRestore => !_busy && _header == null && _password.isNotEmpty;

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final db = ref.read(databaseProvider);
    final (backup, error) = await readBackup(
      widget.file,
      _password,
      schemaVersion: db.schemaVersion,
    );
    if (backup == null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
      return;
    }
    try {
      final go =
          !widget.confirm ||
          (mounted &&
              await showBmDialog(
                context,
                title: StringsManager.restoreTitle,
                body: StringsManager.restoreBody,
                action: StringsManager.restore,
              ));
      if (go) await restore(db, backup);
      if (mounted) Navigator.of(context).pop(go);
    } finally {
      await closeBackup(backup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _header ?? _error;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitle(
                StringsManager.restoreBackup,
                subtitle: StringsManager.restorePasswordNote,
              ),
              HorizontalPadding(
                padding: SpaceManager.s5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RSizedBox.vertical(SpaceManager.s2),
                    BmTextField(
                      label: StringsManager.password,
                      obscure: true,
                      enabled: !_busy && _header == null,
                      error: error?.key,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => setState(() {
                        _password = value;
                        _error = null;
                      }),
                      onSubmitted: (_) => _canRestore ? _restore() : null,
                    ),
                    const RSizedBox.vertical(SpaceManager.s5),
                    BmButton.primary(
                      StringsManager.restore,
                      busy: !_canRestore,
                      onPressed: _restore,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
