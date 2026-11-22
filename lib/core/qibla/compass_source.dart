import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final compassSourceProvider = Provider<CompassSource>((ref) => const CompassSource());

/// degrees from magnetic north, accuracy in degrees or −1 when unknown
typedef RawHeading = ({double magnetic, double accuracy});

enum CompassAccuracy {
  high(StringsManager.accuracyHigh),
  medium(StringsManager.accuracyMedium),
  low(StringsManager.accuracyLow);

  const CompassAccuracy(this.key);

  /// a StringsManager key
  final String key;
}

/// degrees from true north, smoothed
typedef CompassReading = ({double heading, CompassAccuracy accuracy});

/// one scale for both phones (R9), unknown counts as low
CompassAccuracy compassAccuracyOf(double degrees) {
  if (degrees < 0) return CompassAccuracy.low;
  if (degrees <= 15) return CompassAccuracy.high;
  if (degrees <= 30) return CompassAccuracy.medium;
  return CompassAccuracy.low;
}

/// the phone's compass (contracts/compass-channel.md). listening starts the sensor, cancelling
/// stops it. null = no compass
class CompassSource {
  const CompassSource();

  static const _channel = EventChannel('better_muslim/compass');

  Stream<RawHeading?> readings() {
    /// a missing plugin is reported as a flutter error, not on the stream, so it can't be caught
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return Stream.value(null);
    }
    return _channel.receiveBroadcastStream().map((event) {
      if (event is! Map) return null;
      return (
        magnetic: (event['heading'] as num).toDouble(),
        accuracy: (event['accuracy'] as num).toDouble(),
      );
    });
  }
}
