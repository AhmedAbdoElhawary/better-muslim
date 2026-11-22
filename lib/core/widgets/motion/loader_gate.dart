import 'dart:async';

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:material_ui/material_ui.dart';

/// a quick wait keeps the child, a slow one shows the loader, and a shown loader stays at least
/// loaderMinimum so it never flashes. the two crossfade
class BmLoaderGate extends StatefulWidget {
  const BmLoaderGate({
    required this.loading,
    required this.child,
    this.loader = const Center(child: BmStarLoader()),
    this.instant = false,
    super.key,
  });

  final bool loading;
  final Widget child;
  final Widget loader;

  /// a first load has nothing worth keeping on screen, so the loader shows at once
  final bool instant;

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
    if (widget.loading && (!old.loading || widget.instant)) {
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
    if (widget.instant) return _show();
    _delay = Timer(BmMotion.loaderDelay, () => setState(_show));
  }

  void _show() {
    _delay?.cancel();
    _minimum = Timer(BmMotion.loaderMinimum, () {
      if (!widget.loading) setState(_hide);
    });
    _shown = true;
  }

  void _hide() {
    _minimum?.cancel();
    _shown = false;
  }

  @override
  void dispose() {
    _delay?.cancel();
    _minimum?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BmMotion.micro,
      child: _shown
          ? KeyedSubtree(key: const ValueKey('loader'), child: widget.loader)
          : widget.child,
    );
  }
}
