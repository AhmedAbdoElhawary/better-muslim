import 'package:flutter/widgets.dart';

/// material window size classes, screens switch layout on this instead of checking widths themselves
enum WindowSize { compact, medium, expanded }

extension WindowSizeExtension on BuildContext {
  WindowSize get windowSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    return WindowSize.expanded;
  }

  /// above it the countdown and the prayer rows stack
  bool get isLargeText => MediaQuery.textScalerOf(this).scale(1) > 1.4;
}
