import 'package:better_muslim/core/resources/design/bm_text.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('font managers match the BmText roles', () {
    final roles = <(String, TextStyle, double, double?)>[
      ('hero', BmText.hero, FontSizeManager.hero, LineHeightManager.hero),
      ('adhanTitle', BmText.adhanTitle, FontSizeManager.adhanTitle, LineHeightManager.adhanTitle),
      ('largeTitle', BmText.largeTitle, FontSizeManager.largeTitle, LineHeightManager.largeTitle),
      (
        'onboardingTitle',
        BmText.onboardingTitle,
        FontSizeManager.onboardingTitle,
        LineHeightManager.onboardingTitle,
      ),
      ('cardTitle', BmText.cardTitle, FontSizeManager.cardTitle, LineHeightManager.cardTitle),
      ('qiblaTitle', BmText.qiblaTitle, FontSizeManager.qiblaTitle, LineHeightManager.qiblaTitle),
      ('monthTitle', BmText.monthTitle, FontSizeManager.monthTitle, LineHeightManager.monthTitle),
      ('prayerName', BmText.prayerName, FontSizeManager.prayerName, LineHeightManager.prayerName),
      (
        'prayerNameMinor',
        BmText.prayerNameMinor,
        FontSizeManager.prayerNameMinor,
        LineHeightManager.prayerNameMinor,
      ),
      (
        'notifPrayerName',
        BmText.notifPrayerName,
        FontSizeManager.notifPrayerName,
        LineHeightManager.notifPrayerName,
      ),
      ('counter', BmText.counter, FontSizeManager.counter, LineHeightManager.counter),
      ('wordmark', BmText.wordmark, FontSizeManager.wordmark, LineHeightManager.wordmark),
      ('countdown', BmText.countdown, FontSizeManager.countdown, null),
      ('title', BmText.title, FontSizeManager.title, null),
      ('bodyLarge', BmText.bodyLarge, FontSizeManager.bodyLarge, LineHeightManager.bodyLarge),
      ('body', BmText.body, FontSizeManager.body, LineHeightManager.body),
      ('bodyStrong', BmText.bodyStrong, FontSizeManager.bodyStrong, LineHeightManager.bodyStrong),
      ('button', BmText.button, FontSizeManager.button, null),
      ('time', BmText.time, FontSizeManager.time, null),
      ('timeSmall', BmText.timeSmall, FontSizeManager.timeSmall, null),
      ('secondary', BmText.secondary, FontSizeManager.secondary, LineHeightManager.secondary),
      ('caption', BmText.caption, FontSizeManager.caption, LineHeightManager.caption),
      ('label', BmText.label, FontSizeManager.label, LineHeightManager.label),
      (
        'labelStrong',
        BmText.labelStrong,
        FontSizeManager.labelStrong,
        LineHeightManager.labelStrong,
      ),
      ('overline', BmText.overline, FontSizeManager.overline, null),
      ('sectionLabel', BmText.sectionLabel, FontSizeManager.sectionLabel, null),
      ('tabLabel', BmText.tabLabel, FontSizeManager.tabLabel, null),
      ('tabLabelSelected', BmText.tabLabelSelected, FontSizeManager.tabLabelSelected, null),
      ('chip', BmText.chip, FontSizeManager.chip, null),
      ('heroAr', BmText.heroAr, FontSizeManager.heroAr, LineHeightManager.heroAr),
      ('titleAr', BmText.titleAr, FontSizeManager.titleAr, LineHeightManager.titleAr),
      (
        'prayerNameAr',
        BmText.prayerNameAr,
        FontSizeManager.prayerNameAr,
        LineHeightManager.prayerNameAr,
      ),
      ('accentAr', BmText.accentAr, FontSizeManager.accentAr, LineHeightManager.accentAr),
      ('adhanAr', BmText.adhanAr, FontSizeManager.adhanAr, LineHeightManager.adhanAr),
      ('bodyAr', BmText.bodyAr, FontSizeManager.bodyAr, LineHeightManager.bodyAr),
      ('captionAr', BmText.captionAr, FontSizeManager.captionAr, LineHeightManager.captionAr),
      ('duaAr', BmText.duaAr, FontSizeManager.duaAr, LineHeightManager.duaAr),
      ('dhikrAr', BmText.dhikrAr, FontSizeManager.dhikrAr, LineHeightManager.dhikrAr),
      ('quranAr', BmText.quranAr, FontSizeManager.quranAr, LineHeightManager.quranAr),
    ];
    for (final (name, style, size, height) in roles) {
      expect(size, style.fontSize, reason: '$name font size');
      expect(height, style.height, reason: '$name line height');
    }
    expect(LetterSpacingManager.wordmark, BmText.wordmark.letterSpacing);
    expect(LetterSpacingManager.overline, BmText.overline.letterSpacing);
    expect(LetterSpacingManager.sectionLabel, BmText.sectionLabel.letterSpacing);
  });
}
