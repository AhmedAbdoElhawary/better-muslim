import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';

/// where a tapped notification opens (FR-019)
sealed class TapTarget {
  const TapTarget();
}

/// the full adhan would still be playing, so it goes on from there
class AdhanTarget extends TapTarget {
  const AdhanTarget(this.prayer, this.day, this.from);

  final Prayer prayer;
  final DateTime day;
  final Duration from;
}

class PrayerTarget extends TapTarget {
  const PrayerTarget(this.day, this.prayer);

  final DateTime day;
  final Prayer prayer;
}

/// a nudge opens its set where i stopped
class AzkarTarget extends TapTarget {
  const AzkarTarget(this.set);

  final AzkarSet set;
}

/// a reminder, or a payload from before an update, just opens the app
class NoTarget extends TapTarget {
  const NoTarget();
}

TapTarget tapTarget(String payload, DateTime now, Duration length) {
  final alert = alertFromPayload(payload);
  if (alert == null || alert.kind == AlertKind.reminder) return const NoTarget();
  if (alert.kind == AlertKind.azkar) return AzkarTarget(azkarSetOf(alert.prayer));
  final elapsed = now.difference(alert.at);
  if (alert.sound == PrayerSound.adhan && elapsed < length) {
    return AdhanTarget(alert.prayer, alert.day, elapsed.isNegative ? Duration.zero : elapsed);
  }
  return PrayerTarget(alert.day, alert.prayer);
}
