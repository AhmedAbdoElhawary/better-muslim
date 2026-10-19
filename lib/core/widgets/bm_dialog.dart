import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _shadowAlpha = .5;
const _actionAlpha = .16;

/// the components' destructive confirmation. true only when the action is tapped
Future<bool> showBmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.tr(StringsManager.cancel),
    barrierColor: context
        .getColor(ThemeEnum.scrim)
        .withValues(alpha: context.isThemeDark ? BmOpacity.scrimDark : BmOpacity.scrimLight),
    transitionDuration: reduceMotion ? BmMotion.micro : BmMotion.standard,
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: BmMotion.standardCurve),
      child: child,
    ),
    pageBuilder: (context, _, _) => _Dialog(title: title, body: body, action: action),
  );
  return confirmed ?? false;
}

class _Dialog extends StatelessWidget {
  const _Dialog({required this.title, required this.body, required this.action});

  /// StringsManager keys
  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SymmetricPadding(
        horizontal: SpaceManager.screen,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: SizeManager.dialog.r),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.raised),
                borderRadius: BorderRadius.circular(RadiusManager.dialog.r),
                boxShadow: [
                  BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
                  BoxShadow(
                    color: context.getColor(ThemeEnum.scrim).withValues(alpha: _shadowAlpha),
                    blurRadius: SizeManager.dialogShadowBlur.r,
                    spreadRadius: -SpaceManager.dialogShadowY.r,
                    offset: Offset(0, SpaceManager.dialogShadowY.r),
                  ),
                ],
              ),
              child: AllPadding(
                padding: SpaceManager.s6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: RegularText(
                        title,
                        font: FontEnum.display,
                        fontSize: FontSizeManager.sheetTitle,
                        height: LineHeightManager.dialogTitle,
                      ),
                    ),
                    const RSizedBox.vertical(SpaceManager.dialogBodyTop),
                    RegularText(
                      body,
                      fontSize: FontSizeManager.dialogBody,
                      height: LineHeightManager.dialogBody,
                      color: ThemeEnum.text2,
                    ),
                    const RSizedBox.vertical(SpaceManager.dialogActionsTop),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: SpaceManager.s2.r,
                      runSpacing: SpaceManager.s2.r,
                      children: [
                        _Action(StringsManager.cancel, onTap: () => Navigator.pop(context, false)),
                        _Action(
                          action,
                          destructive: true,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, {required this.onTap, this.destructive = false});

  /// a StringsManager key
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: destructive
                  ? context.getColor(ThemeEnum.error).withValues(alpha: _actionAlpha)
                  : null,
              borderRadius: BorderRadius.circular(RadiusManager.dialogAction.r),
            ),
            child: SymmetricPadding(
              horizontal: SpaceManager.s4,
              vertical: SpaceManager.s1,
              child: Center(
                widthFactor: 1,
                child: MediumText(label, color: destructive ? ThemeEnum.error : ThemeEnum.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
