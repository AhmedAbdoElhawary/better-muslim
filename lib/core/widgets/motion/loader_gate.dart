import 'dart:async';

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:flutter/material.dart';

/// a quick wait shows nothing, a slow one the loader, and a shown loader stays at least
/// loaderMinimum so it never flashes. one loader on screen at a time
class BmLoaderGate extends StatefulWidget {
  const BmLoaderGate({
    required this.loading,
    required this.child,
    this.loader = const Center(child: BmStarLoader()),
    super.key,
  });

  final bool loading;
  final Widget child;
  final Widget loader;

  /// how many gates show their loader now
  @visibleForTesting
  static int showing = 0;

  @override
  State<BmLoaderGate> createState() => _BmLoaderGateState();
}

class _BmLoaderGateState extends State<BmLoaderGate> {
  Timer? _delay;
  Timer? _minimum;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.loading) _wait();
  }

  @override
  void didUpdateWidget(BmLoaderGate old) {
    super.didUpdateWidget(old);
    if (widget.loading && !old.loading) {
      _wait();
    } else if (!widget.loading && !_shown) {
      _delay?.cancel();
    } else if (!widget.loading && !(_minimum?.isActive ?? false)) {
      _hide();
    }
  }

  void _wait() {
    if (_shown) return;
    _delay?.cancel();
    _delay = Timer(BmMotion.loaderDelay, () {
      if (BmLoaderGate.showing > 0) return;
      BmLoaderGate.showing++;
      _minimum = Timer(BmMotion.loaderMinimum, () {
        if (!widget.loading) setState(_hide);
      });
      setState(() => _shown = true);
    });
  }

  void _hide() {
    if (!_shown) return;
    _minimum?.cancel();
    _shown = false;
    BmLoaderGate.showing--;
  }

  @override
  void dispose() {
    _delay?.cancel();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shown) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.surface),
          shape: BoxShape.circle,
        ),
        child: widget.loader,
      );
    }
    return widget.loading
        ? const SizedBox.shrink()
        : DecoratedBox(
            decoration: BoxDecoration(
              color: context.getColor(ThemeEnum.primary),
              shape: BoxShape.circle,
            ),
            child: widget.child,
          );
  }
}
