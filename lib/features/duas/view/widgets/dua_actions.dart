import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_share.dart';
import 'package:better_muslim/features/duas/view_model/dua_player.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// listen, save and share under every dua card, listen only once the dua has its clip or ayahs
class DuaActions extends ConsumerWidget {
  const DuaActions({required this.dua, super.key});
  final Dua dua;

  void _toggleSave(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final savedAt = ref.read(savedAtProvider).value?[dua.id];
    if (savedAt == null) {
      db.saveDua(dua.id);
      return;
    }
    db.unsaveDua(dua.id);
    showToast(
      context,
      StringsManager.removedFromSaved,
      icon: BmIconName.bookmark,

      /// the old date, so it goes back to its place in saved
      onUndo: () => db.saveDua(dua.id, at: savedAt),
    );
  }

  Future<void> _onTapPlay(BuildContext context, WidgetRef ref) async {
    final isPlayed = await ref.read(duaPlayerProvider.notifier).toggle(dua);
    if (!isPlayed && context.mounted) {
      showToast(
        context,
        StringsManager.duaFailed,
        icon: BmIconName.listen,
        action: StringsManager.tryAgain,
        onUndo: () => _onTapPlay(context, ref),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(duaPlayerProvider.select((id) => id == dua.id));
    final saved = ref.watch(isSavedProvider(dua.id));
    return Row(
      children: [
        /// a listen with no clip behind it would only say it failed
        if (dua.listenable) ...[
          _Action(
            icon: playing ? BmIcon.ui(BmUiIcon.stop) : BmIcon(BmIconName.listen),
            label: playing ? StringsManager.stop : StringsManager.listen,
            onTap: () => _onTapPlay(context, ref),
          ),
          const RSizedBox.horizontal(SpaceManager.s1),
        ],
        _Action(
          icon: BmIcon(BmIconName.bookmark, filled: saved),
          label: saved ? StringsManager.saved : StringsManager.save,
          color: saved ? ThemeEnum.primary : ThemeEnum.text2,
          onTap: () => _toggleSave(context, ref),
        ),
        const RSizedBox.horizontal(SpaceManager.s1),
        _Action(
          icon: BmIcon.ui(BmUiIcon.share),
          label: StringsManager.share,
          onTap: () => showShareSheet(
            context,
            content: DuaShare(dua),
            ornaments: const [...ShareOrnament.patterns, ShareOrnament.arch],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = ThemeEnum.text2,
  });

  /// tinted here, so the call site passes no size or color
  final BmIcon icon;
  final String label;
  final VoidCallback onTap;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.duaAction.r),
            child: IconTheme(
              data: IconThemeData(color: context.getColor(color), size: SizeManager.iconChevron.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RSizedBox.square(dimension: SizeManager.iconChevron, child: icon),
                  const RSizedBox.horizontal(SpaceManager.duaActionGap),
                  Flexible(child: RegularText(label, color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
