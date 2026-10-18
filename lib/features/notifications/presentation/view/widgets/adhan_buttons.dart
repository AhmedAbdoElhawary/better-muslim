import 'dart:ui';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_tint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// mark prayed and stop adhan (4.03)
class AdhanButtons extends StatelessWidget {
  const AdhanButtons({required this.prayer, required this.day, super.key});

  final Prayer prayer;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MarkPrayed(prayer: prayer, day: day),
        ),
        const RSizedBox.horizontal(SpaceManager.adhanButtonGap),
        const Expanded(child: _StopAdhan()),
      ],
    );
  }
}

/// logs the prayer and leaves the adhan playing, then shows "Prayed" (FR-031)
class _MarkPrayed extends ConsumerWidget {
  const _MarkPrayed({required this.prayer, required this.day});

  final Prayer prayer;
  final DateTime day;

  Future<void> _mark(WidgetRef ref) async {
    BmHaptics.markPrayed();
    await ref.read(databaseProvider).markPrayed(day, prayer);

    /// the shade drops its own mark prayed, the log already has it
    await ref.read(adhanChannelProvider).markPrayedAction(alertId(day, prayer, AlertKind.adhan));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayed = ref.watch(prayedProvider(day).select((log) => log.contains(prayer)));
    return Semantics(
      button: true,
      enabled: !prayed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: prayed ? null : () => _mark(ref),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadiusManager.md.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AdhanColors.glass,
                borderRadius: BorderRadius.circular(RadiusManager.md.r),
                border: Border.all(color: AdhanColors.glassBorder),
              ),
              child: _ButtonBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BmIcon.ui(BmUiIcon.check, size: SizeManager.iconChevron.r),
                    const RSizedBox.horizontal(SpaceManager.adhanButtonIconGap),
                    Flexible(
                      child: MediumText(
                        prayed ? StringsManager.prayed : StringsManager.markPrayed,
                        fontSize: FontSizeManager.button,
                        color: null,
                        textAlign: TextAlign.center,
                      ),
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

class _StopAdhan extends ConsumerWidget {
  const _StopAdhan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(adhanPlayerProvider).stop();
          Navigator.of(context).pop();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AdhanColors.primary,
            borderRadius: BorderRadius.circular(RadiusManager.md.r),
          ),
          child: const AdhanTint(
            AdhanColors.onPrimary,
            child: _ButtonBox(
              child: SemiBoldText(
                StringsManager.stopAdhan,
                fontSize: FontSizeManager.button,
                color: null,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 52 high, and taller when large text needs it
class _ButtonBox extends StatelessWidget {
  const _ButtonBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.buttonLarge.r),
      child: Center(child: child),
    );
  }
}
