import 'dart:async';
import 'dart:math';

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' "With action" toast, 4 s or until undo. it goes in the app's outermost overlay,
/// so it stays above every route, sheet and dialog, and above the tab bar when the shell shows it
void showToast(
  BuildContext context,
  String key, {
  Map<String, String> args = const {},
  VoidCallback? onUndo,

  /// the button's StringsManager key, try again on a failed download
  String action = StringsManager.undo,
  BmIconName icon = BmIconName.prayer,
}) {
  hideToast();
  final inShell = context.findAncestorWidgetOfExactType<AppShell>() != null;
  final bar = inShell ? AppShell.navBar.currentContext?.size?.height : null;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Placed(
      bar: bar,
      child: _Toast(
        text: key,
        args: args,
        icon: icon,
        action: action,
        onUndo: onUndo,
        onGone: () {
          if (_shown == entry) hideToast();
        },
      ),
    ),
  );
  _shown = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
}

/// the undo of a cleared row would bring it back, so a reset takes the toast away first
void hideToast() {
  _shown
    ?..remove()
    ..dispose();
  _shown = null;
}

OverlayEntry? _shown;

const _duration = Duration(seconds: 4);

/// above the tab bar inside the shell, above the keyboard or the home indicator elsewhere
class _Placed extends StatelessWidget {
  const _Placed({required this.bar, required this.child});

  /// the tab bar's height when the toast came from inside the shell
  final double? bar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = max(
      MediaQuery.viewInsetsOf(context).bottom,
      bar ?? MediaQuery.paddingOf(context).bottom,
    );
    return PositionedDirectional(
      start: SpaceManager.screen.r,
      end: SpaceManager.screen.r,
      bottom: bottom + SpaceManager.s2.r,
      child: child,
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.text,
    required this.args,
    required this.icon,
    required this.action,
    required this.onGone,
    this.onUndo,
  });
  final String text;
  final Map<String, String> args;
  final BmIconName icon;
  final String action;
  final VoidCallback onGone;
  final VoidCallback? onUndo;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: BmMotion.standard,
    reverseDuration: BmMotion.micro,
  )..forward();

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_duration, _leave);
  }

  void _leave() {
    _timer.cancel();
    _controller.reverse().whenComplete(() {
      if (mounted) widget.onGone();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onUndo = widget.onUndo;
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
              BmIcon(
                widget.icon,
                size: SizeManager.iconList.r,
                color: context.getColor(ThemeEnum.bg),
              ),
              const RSizedBox.horizontal(SpaceManager.s3),
              Expanded(
                child: RegularText(
                  widget.text,
                  args: widget.args,
                  fontSize: FontSizeManager.secondary,
                  color: ThemeEnum.bg,
                ),
              ),
              if (onUndo != null)
                _UndoButton(
                  label: widget.action,
                  onTap: () {
                    _leave();
                    onUndo();
                  },
                ),
            ],
          ),
        ),
      ),
    );
    final shown = Semantics(
      liveRegion: true,
      container: true,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _leave, child: toast),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return Material(
        child: FadeTransition(opacity: _controller, child: shown),
      );
    }
    final rise = CurvedAnimation(parent: _controller, curve: BmMotion.decelerate);
    return Material(
      child: FadeTransition(
        opacity: _controller,
        child: AnimatedBuilder(
          animation: rise,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, BmMotion.shift.r * (1 - rise.value)),
            child: child,
          ),
          child: shown,
        ),
      ),
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
