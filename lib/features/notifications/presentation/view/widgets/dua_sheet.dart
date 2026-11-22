import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/dua_text.dart';
import 'package:better_muslim/features/notifications/data/dua_after_adhan.dart';
import 'package:material_ui/material_ui.dart';

/// the full dua after the adhan, laid out like a 4.14 dua card. arabic shows only the arabic and
/// its source (FR-032)
class DuaSheet extends StatelessWidget {
  const DuaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: SymmetricPadding(
          horizontal: SpaceManager.duaCardH,
          vertical: SpaceManager.card,
          child: DuaText(
            title: DuaAfterAdhan.titleKey,
            source: isArabic ? DuaAfterAdhan.sourceAr : DuaAfterAdhan.sourceEn,
            arabic: DuaAfterAdhan.arabic,
            transliteration: DuaAfterAdhan.transliteration,
            translation: DuaAfterAdhan.translation,
          ),
        ),
      ),
    );
  }
}
