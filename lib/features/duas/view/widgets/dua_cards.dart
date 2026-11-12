import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// duas as cards one under the other, keyed by id so a removed one doesn't shift the others
class DuaCards extends StatelessWidget {
  const DuaCards(this.duas, {super.key});
  final List<(Dua, DuaCategory)> duas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (dua, category)) in duas.indexed) ...[
          if (i > 0) const RSizedBox.vertical(SpaceManager.s4),
          DuaCard(key: ValueKey(dua.id), dua: dua, category: category),
        ],
      ],
    );
  }
}
