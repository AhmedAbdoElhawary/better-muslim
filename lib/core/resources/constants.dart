import 'package:flutter/foundation.dart';

/// one switch to force release-only behaviour on in a debug run
// TODO(ahmed): keep both on the real kReleaseMode / kDebugMode when you tag, a literal ships prod without Sentry or sends debug runs to prod Sentry.
const bool kCustomReleaseMode = kReleaseMode;
const bool kCustomDebugMode = kDebugMode;
