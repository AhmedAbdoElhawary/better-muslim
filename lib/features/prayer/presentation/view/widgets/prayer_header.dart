import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the adhan, pin and sliders, the large title and "place · method", over the sky3 glow
class PrayerHeader extends StatelessWidget {
  const PrayerHeader({
    required this.onAdhan,
    required this.onPin,
    required this.onSliders,
    super.key,
  });
  final VoidCallback onAdhan;
  final VoidCallback onPin;
  final VoidCallback onSliders;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      bottom: false,
      child: TopPadding(
        padding: SpaceManager.s1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EndPadding(
              padding: SpaceManager.s2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _HeaderButton(
                    icon: BmIconName.adhan,
                    label: StringsManager.adhanAndReminders,
                    onTap: onAdhan,
                  ),
                  _HeaderButton(
                    icon: BmIconName.location,
                    label: StringsManager.location,
                    onTap: onPin,
                  ),
                  _HeaderButton(
                    icon: BmIconName.settings,
                    label: StringsManager.calculationMethod,
                    onTap: onSliders,
                  ),
                ],
              ),
            ),
            SymmetricPadding(
              horizontal: SpaceManager.s5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isArabic) const RSizedBox.vertical(SpaceManager.prayerTitleTop),
                  LargeTitle(
                    StringsManager.prayerTimes,
                    fontSize: isArabic ? FontSizeManager.titleAr : FontSizeManager.largeTitle,
                    height: isArabic ? LineHeightManager.titleAr : LineHeightManager.largeTitle,
                  ),
                  RSizedBox.vertical(
                    isArabic ? SpaceManager.prayerSubtitleTopAr : SpaceManager.prayerSubtitleTop,
                  ),
                  const LargeTitleSubtitle(child: _Subtitle()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final BmIconName icon;

  /// a StringsManager key for screen readers
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon(icon, size: SizeManager.icon.r, color: context.getColor(ThemeEnum.text)),
          ),
        ),
      ),
    );
  }
}

/// "Makkah · Umm al-Qura", the method the times really use, picked or by country
class _Subtitle extends ConsumerWidget {
  const _Subtitle();

  static const _separator = ' · ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      locationProvider.select(
        (location) => (name: location?.placeName, nameAr: location?.placeNameAr),
      ),
    );
    final method = ref.watch(todayTimesProvider.select((times) => times?.method));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = (isArabic ? place.nameAr : null) ?? place.name;
    if (name == null || method == null) {
      return const RegularText(StringsManager.noLocationYet, color: ThemeEnum.text2);
    }
    final subtitle = '$name$_separator${context.tr(method.nameKey)}';
    return RegularText(subtitle, translate: false, color: ThemeEnum.text2);
  }
}
