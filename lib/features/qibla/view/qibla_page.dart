import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_bar.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_cards.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dial.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_hint.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_title.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// 4.05 turning and 4.06 aligned, pushed over the tab bar
class QiblaPage extends ConsumerWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(qiblaTrackerProvider, (previous, next) {
      if (previous == null) return;
      if (next.approaches > previous.approaches) BmHaptics.qiblaApproach();
      if (next.alignments > previous.alignments) {
        BmHaptics.qiblaAligned();
        BmSounds.aligned();
        SemanticsService.sendAnnouncement(
          View.of(context),
          context.tr(StringsManager.facingQibla),
          Directionality.of(context),
        );
      }
    });
    return Scaffold(
      backgroundColor: context.getColor(ThemeEnum.bg),
      body: const TitleGlow(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              QiblaBar(),

              /// text scale 2.0 makes the page taller than the phone, it scrolls instead of cutting
              Expanded(
                child: SingleChildScrollView(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        RSizedBox.vertical(SpaceManager.qiblaTitleTop),
                        QiblaTitle(),
                        RSizedBox.vertical(SpaceManager.qiblaDialTop),
                        QiblaDial(),
                        RSizedBox.vertical(SpaceManager.qiblaCardsTop),
                        HorizontalPadding(
                          padding: SpaceManager.qiblaCardsSide,
                          child: QiblaCards(),
                        ),
                        RSizedBox.vertical(SpaceManager.qiblaHintTop),
                        HorizontalPadding(padding: SpaceManager.qiblaHintSide, child: QiblaHint()),
                        RSizedBox.vertical(SpaceManager.screen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
