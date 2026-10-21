import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' "With action" toast, 4 s or until undo. the shell's scaffold is the root one,
/// so it sits above the tab bar and stays through a tab switch (R8)
void showToast(
  BuildContext context,
  String key, {
  Map<String, String> args = const {},
  VoidCallback? onUndo,

  /// the button's StringsManager key, try again on a failed download
  String action = StringsManager.undo,
  BmIconName icon = BmIconName.prayer,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: _duration,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: REdgeInsets.symmetric(horizontal: SpaceManager.screen, vertical: SpaceManager.s2),

        /// the toast draws its own box, so it can slide up inside the bar's fade
        backgroundColor: context.getColor(ThemeEnum.transparent),
        clipBehavior: Clip.none,
        content: _Toast(text: key, args: args, icon: icon, action: action, onUndo: onUndo),
      ),
    );
}

const _duration = Duration(seconds: 4);

class _Toast extends StatelessWidget {
  const _Toast({
    required this.text,
    required this.args,
    required this.icon,
    required this.action,
    this.onUndo,
  });
  final String text;
  final Map<String, String> args;
  final BmIconName icon;
  final String action;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final onUndo = this.onUndo;
    final toast = DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.text),
        borderRadius: BorderRadius.circular(RadiusManager.md.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.toast.r),
        child: OnlyPadding(
          start: SpaceManager.s4,
          end: SpaceManager.s2,
          child: Row(
            children: [
              BmIcon(icon, size: SizeManager.iconList.r, color: context.getColor(ThemeEnum.bg)),
              const RSizedBox.horizontal(SpaceManager.s3),
              Expanded(
                child: RegularText(
                  text,
                  args: args,
                  fontSize: FontSizeManager.secondary,
                  color: ThemeEnum.bg,
                ),
              ),
              if (onUndo != null)
                _UndoButton(
                  label: action,
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onUndo();
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return toast;
    return TweenAnimationBuilder(
      tween: Tween(begin: BmMotion.shift.r, end: 0.0),
      duration: BmMotion.standard,
      curve: BmMotion.decelerate,
      builder: (context, shift, child) =>
          Transform.translate(offset: Offset(0, shift), child: child),
      child: toast,
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r, minWidth: SizeManager.hit.r),
          child: HorizontalPadding(
            padding: SpaceManager.s3,
            child: Center(
              widthFactor: 1,
              child: SemiBoldText(
                label,
                fontSize: FontSizeManager.secondary,
                color: ThemeEnum.toastAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
