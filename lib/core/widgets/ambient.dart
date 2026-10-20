import 'package:better_muslim/core/resources/design/bm_motion.dart';

/// an alternate loop of [half] ms each way on the breathe curve, 0..1. home's sky and the welcome
/// drift, twinkle and breathe on it
double ambientBreathe(double ms, double half) {
  final phase = ms % (2 * half) / half;
  return BmMotion.breathe.transform(phase <= 1 ? phase : 2 - phase);
}
