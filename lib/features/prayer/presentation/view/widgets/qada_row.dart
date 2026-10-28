import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:better_muslim/features/prayer/presentation/providers/qada.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/add_older_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// one prayer of the qada list: how many are left, "Made one up" and +
class QadaRow extends ConsumerWidget {
  const QadaRow(this.prayer, {this.divider = true, super.key});
  final Prayer prayer;
  final bool divider;

  Future<void> _madeOneUp(BuildContext context, WidgetRef ref) async {
    final qada = ref.read(qadaRepositoryProvider);
    final id = await qada.makeUpOldest(prayer);
    if (id == null || !context.mounted) return;
    showToast(
      context,
      StringsManager.prayerMadeUp,
      args: {'prayer': context.tr(prayer.nameKey)},
      onUndo: () => qada.undoMadeUp(id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = ref.watch(qadaOpenCountsProvider.select((counts) => counts.value?[prayer] ?? 0));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline)))
            : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.linkRow.r),
        child: OnlyPadding(
          start: SpaceManager.s4,
          end: SpaceManager.s1,
          top: SpaceManager.s2,
          bottom: SpaceManager.s2,
          child: Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegularText(
                        prayer.nameKey,
                        font: FontEnum.display,
                        fontSize: FontSizeManager.prayerNameMinor,
                      ),
                      const RSizedBox.vertical(SpaceManager.rowLineGap),
                      BmSwitcher(
                        child: RegularText(
                          StringsManager.qadaLeft,
                          key: ValueKey(left),
                          args: {'count': context.formatDigits('$left', digits)},
                          color: ThemeEnum.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _MadeOneUp(enabled: left > 0, onTap: () => _madeOneUp(context, ref)),
              Semantics(
                button: true,
                label: context.tr(StringsManager.addOlderQada),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showAddOlderSheet(context, prayer),
                  child: RSizedBox.square(
                    dimension: SizeManager.hit,
                    child: Center(
                      child: BmIcon.ui(
                        BmUiIcon.plus,
                        size: SizeManager.icon.r,
                        color: context.getColor(ThemeEnum.text2),
                      ),
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

/// an outline pill, dimmed and not tappable with nothing left
class _MadeOneUp extends StatelessWidget {
  const _MadeOneUp({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            widthFactor: 1,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : BmOpacity.disabled,
              duration: BmMotion.micro,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: SizeManager.markChip.r),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                    border: Border.all(color: context.getColor(ThemeEnum.outlineStrong)),
                  ),
                  child: const SymmetricPadding(
                    horizontal: SpaceManager.s3,
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: MediumText(
                        StringsManager.madeOneUp,
                        fontSize: FontSizeManager.caption,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
