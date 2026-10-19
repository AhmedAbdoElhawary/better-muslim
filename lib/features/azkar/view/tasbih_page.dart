import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:better_muslim/features/azkar/view/widgets/bead_strip.dart';
import 'package:better_muslim/features/azkar/view/widgets/dhikr_chips.dart';
import 'package:better_muslim/features/azkar/view/widgets/dhikr_text.dart';
import 'package:better_muslim/features/azkar/view/widgets/tasbih_counter.dart';
import 'package:better_muslim/features/azkar/view_model/tasbih_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.08, inside the azkar tab. the lower area counts, the chips, the dhikr and the bar never do
class TasbihPage extends ConsumerStatefulWidget {
  const TasbihPage({super.key});

  @override
  ConsumerState<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends ConsumerState<TasbihPage> {
  /// only the strip listens to it, so a tap rebuilds the beads and the counter alone
  final _taps = ValueNotifier(0);

  @override
  void dispose() {
    _taps.dispose();
    super.dispose();
  }

  void _tap() {
    final before = ref.read(tasbihControllerProvider);
    if (before == null) return;
    ref.read(tasbihControllerProvider.notifier).tap();
    BmHaptics.bead();
    BmSounds.bead();
    _taps.value++;
    if (!before.done && before.tap().done) {
      BmHaptics.setComplete();
      BmSounds.complete();
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.tr(StringsManager.setComplete),
        Directionality.of(context),
      );
    }
  }

  void _reset() {
    final controller = ref.read(tasbihControllerProvider.notifier);
    final before = controller.reset();
    if (before == null) return;
    showToast(
      context,
      StringsManager.countReset,
      icon: BmIconName.tasbih,
      onUndo: () => controller.restore(before),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _TasbihBar(onReset: _reset),
                  const RSizedBox.vertical(SpaceManager.tasbihChipsTop),
                  const DhikrChips(),
                  const RSizedBox.vertical(SpaceManager.tasbihDhikrTop),
                  const DhikrText(),
                  const RSizedBox.vertical(SpaceManager.tasbihAreaTop),
                ],
              ),
            ),

            /// the rest of the screen is the tap target, at text scale 2.0 the page scrolls instead
            SliverFillRemaining(
              hasScrollBody: false,
              child: _CountArea(taps: _taps, onTap: _tap),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasbihBar extends StatelessWidget {
  const _TasbihBar({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.appBar.r),
      child: HorizontalPadding(
        padding: SpaceManager.s2,
        child: Row(
          children: [
            const BarBackButton(),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SemiBoldText(StringsManager.tasbih, textAlign: TextAlign.center),
                  RSizedBox.vertical(SpaceManager.barTitleGap),
                  RegularText(
                    StringsManager.afterPrayer,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.text2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: context.tr(StringsManager.resetCount),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onReset,
                child: RSizedBox.square(
                  dimension: SizeManager.hit,
                  child: Center(
                    child: BmIcon.ui(
                      BmUiIcon.reset,
                      size: SizeManager.icon.r,
                      color: context.getColor(ThemeEnum.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountArea extends ConsumerWidget {
  const _CountArea({required this.taps, required this.onTap});
  final ValueNotifier<int> taps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasbihControllerProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (state == null) return const SizedBox.shrink();
    final dhikr = tasbihDhikr[state.dhikr];
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final count = context.formatDigits('${state.count}', digits);
    final target = context.formatDigits('${state.target}', digits);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: context.tr(StringsManager.tasbihA11y, {
        'dhikr': isArabic ? dhikr.arabicName : dhikr.name,
        'count': count,
        'target': target,
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            TasbihCounter(
              count: state.count,
              target: state.target,
              label: count,
              targetLabel: target,
            ),
            const RSizedBox.vertical(SpaceManager.tasbihStripGap),
            ValueListenableBuilder(
              valueListenable: taps,
              builder: (context, taps, _) => BeadStrip(taps: taps),
            ),
            const RSizedBox.vertical(SpaceManager.tasbihHintGap),
            const RegularText(
              StringsManager.tapAnywhere,
              color: ThemeEnum.text2,
              textAlign: TextAlign.center,
            ),
            const RSizedBox.vertical(SpaceManager.screen),
          ],
        ),
      ),
    );
  }
}
