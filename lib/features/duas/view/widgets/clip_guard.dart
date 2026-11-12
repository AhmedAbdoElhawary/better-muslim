import 'package:better_muslim/features/duas/view_model/dua_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// a page pushed on top, the adhan screen too, stops the dua playing (R11)
class ClipGuard extends ConsumerStatefulWidget {
  const ClipGuard({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ClipGuard> createState() => _ClipGuardState();
}

class _ClipGuardState extends ConsumerState<ClipGuard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) ?? true) return;

    /// riverpod doesn't allow a change while the tree builds
    final player = ref.read(duaPlayerProvider.notifier);
    Future.microtask(player.stop);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
