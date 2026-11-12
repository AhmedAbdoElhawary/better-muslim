import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/azkar.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:better_muslim/features/azkar/view_model/tasbih_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the current dhikr in arabic, then in english its name and meaning, crossfading (FR-026)
class DhikrText extends ConsumerWidget {
  const DhikrText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tasbihControllerProvider.select((state) => state?.dhikr ?? 0));
    final dhikr = tasbihDhikr[index];
    final font = ref.watch(azkarFontProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BmSwitcher(
      child: Column(
        key: ValueKey(index),
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: RegularText(
              dhikr.arabic,
              translate: false,
              font: font,
              fontSize: FontSizeManager.dhikrAr,
              height: LineHeightManager.dhikrAr,
              textAlign: TextAlign.center,
            ),
          ),
          if (!isArabic) ...[
            const RSizedBox.vertical(SpaceManager.dhikrLineGap),
            MediumText(
              dhikr.name,
              translate: false,
              fontSize: FontSizeManager.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const RSizedBox.vertical(SpaceManager.dhikrLineGap * 2),
            RegularText(
              dhikr.meaning,
              translate: false,
              fontSize: FontSizeManager.dhikrMeaning,
              color: ThemeEnum.text2,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
