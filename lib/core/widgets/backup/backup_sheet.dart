import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

/// the shortest password a backup takes (FR-029)
const minPasswordLength = 6;

Future<void> showBackupSheet(BuildContext context) =>
    showBmSheet(context, builder: (_) => const _BackupSheet());

/// a password twice, then the file to the phone's share sheet (FR-029)
class _BackupSheet extends ConsumerStatefulWidget {
  const _BackupSheet();

  @override
  ConsumerState<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<_BackupSheet> {
  var _password = '';
  var _confirm = '';
  var _busy = false;

  bool get _long => _password.length >= minPasswordLength;
  bool get _ready => _long && _password == _confirm;

  Future<void> _save() async {
    setState(() => _busy = true);
    final file = await writeBackup(
      ref.read(databaseProvider),
      _password,
      now: ref.read(clockProvider)(),
    );
    try {
      await ref.read(shareProvider)(ShareParams(files: [XFile(file.path)]));
    } finally {
      /// the share sheet has its own copy by then, the backup isn't kept on this phone
      if (file.existsSync()) file.deleteSync();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );

    /// the line shows once the confirm field is reached, not on the first letter
    final short = _confirm.isNotEmpty && _password.isNotEmpty && !_long;
    final differ = _long && _confirm.length >= _password.length && _confirm != _password;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetTitle(StringsManager.backUp),
              HorizontalPadding(
                padding: SpaceManager.s5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BmTextField(
                      label: StringsManager.password,
                      obscure: true,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      error: short ? StringsManager.passwordTooShort : null,
                      errorArgs: {'count': context.formatDigits('$minPasswordLength', digits)},
                      onChanged: (value) => setState(() => _password = value),
                    ),
                    const RSizedBox.vertical(SpaceManager.s3),
                    BmTextField(
                      label: StringsManager.confirmPassword,
                      obscure: true,
                      enabled: !_busy,
                      textInputAction: TextInputAction.done,
                      error: differ ? StringsManager.passwordsDontMatch : null,
                      onChanged: (value) => setState(() => _confirm = value),
                      onSubmitted: (_) => _ready && !_busy ? _save() : null,
                    ),
                    const RSizedBox.vertical(SpaceManager.s3),
                    const RegularText(
                      StringsManager.passwordNote,
                      fontSize: FontSizeManager.cardNote,
                      height: LineHeightManager.caption,
                      color: ThemeEnum.text2,
                    ),
                    const RSizedBox.vertical(SpaceManager.s5),
                    BmButton.primary(
                      StringsManager.saveBackup,
                      busy: _busy || !_ready,
                      onPressed: _save,
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
