import 'dart:async';

import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/azkar/model/set_state.dart';
import 'package:better_muslim/features/azkar/view/widgets/zikr_card.dart';
import 'package:better_muslim/features/azkar/view_model/set_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a morning or evening set, one card at a time. no png, built from the components' azkar card
class AzkarSetPage extends ConsumerWidget {
  const AzkarSetPage(this.set, {super.key});
  final AzkarSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(setControllerProvider(set).select((state) => state != null));
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            CompactAppBar(set.titleKey, heroTag: Routes.azkarSet(set)),
            Expanded(child: BmSwitcher(child: loaded ? _Cards(set) : const SizedBox.shrink())),
          ],
        ),
      ),
    );
  }
}

class _Cards extends ConsumerStatefulWidget {
  const _Cards(this.set);
  final AzkarSet set;

  @override
  ConsumerState<_Cards> createState() => _CardsState();
}

class _CardsState extends ConsumerState<_Cards> with SingleTickerProviderStateMixin {
  late final _pages = PageController(
    initialPage: ref.read(setControllerProvider(widget.set))!.index,
  );

  /// with reduce motion the next card fades in where it is instead of sliding
  late final _fade = AnimationController(vsync: this, duration: BmMotion.micro, value: 1);

  /// a done card moves on by itself after the completion moment (FR-024)
  Timer? _advance;

  @override
  void dispose() {
    _advance?.cancel();
    _pages.dispose();
    _fade.dispose();
    super.dispose();
  }

  void moveNext() {
    final index = ref.read(setControllerProvider(widget.set))!.index;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
      _fade.forward(from: 0);
    } else {
      _pages.animateToPage(index, duration: BmMotion.standard, curve: BmMotion.standardCurve);
    }
  }

  void _tap() {
    _advance?.cancel();
    final controller = ref.read(setControllerProvider(widget.set).notifier);
    switch (controller.tap()) {
      case SetTap.counted:
        BmHaptics.bead();
        BmSounds.bead();
      case SetTap.done:
        BmHaptics.setComplete();
        BmSounds.complete();
        _advance = Timer(BmMotion.completionPause, _tap);
      case SetTap.setDone:
        BmHaptics.setComplete();
        BmSounds.complete();
      case SetTap.moved:
        moveNext();
      case SetTap.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(setControllerProvider(widget.set).notifier);
    final state = ref.watch(setControllerProvider(widget.set))!;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final items = controller.items;
    final complete = state.allDone(items);
    return FadeTransition(
      opacity: _fade,
      child: PageView.builder(
        controller: _pages,
        itemCount: items.length,
        onPageChanged: (index) {
          _advance?.cancel();
          controller.moveTo(index);
        },
        itemBuilder: (context, index) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: SingleChildScrollView(
            padding: REdgeInsets.all(SpaceManager.screen),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  ZikrCard(
                    zikr: items[index],
                    setKey: widget.set.titleKey,
                    index: index,
                    total: items.length,
                    count: state.countOf(items[index]),
                    digits: digits,
                    complete: complete,
                  ),
                  const RSizedBox.vertical(SpaceManager.s4),
                  const RegularText(
                    StringsManager.tapAnywhere,
                    color: ThemeEnum.text2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
