import 'dart:async';

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/oil_drop.dart';
import 'package:flutter/material.dart';

/// a quick wait shows nothing, a slow one the loader, and a shown loader stays until its ripple
/// ends so it never flashes. one loader on screen at a time
class BmLoaderGate extends StatefulWidget {
  const BmLoaderGate({
    required this.loading,
    required this.child,
    this.loader = const Center(child: BmOilDrop()),
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
  Timer? _cycles;
  int _cycleCount = 0;
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
    }
  }

  void _wait() {
    if (_shown) return;
    _delay?.cancel();
    _delay = Timer(BmMotion.loaderDelay, () {
      if (BmLoaderGate.showing > 0) return;
      BmLoaderGate.showing++;
      _cycleCount = 0;
      _cycles = Timer.periodic(BmMotion.oilCycle, (_) => _cycleEnded());
      setState(() => _shown = true);
    });
  }

  void _cycleEnded() {
    _cycleCount++;
    if (widget.loading || BmMotion.oilCycle * _cycleCount < BmMotion.loaderMinimum) return;
    _hide();
    setState(() {});
  }

  void _hide() {
    if (!_shown) return;
    _cycles?.cancel();
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
    if (_shown) return widget.loader;
    return widget.loading ? const SizedBox.shrink() : widget.child;
  }
}
