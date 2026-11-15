import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/more/model/credits.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// More › About › Credits, the sources as text (FR-033)
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.credits, heroTag: Routes.credits),
            Expanded(
              child: ListView(
                padding: REdgeInsets.all(SpaceManager.screen),
                children: [
                  GroupedSection(children: [for (final credit in credits) _CreditRow(credit)]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow(this.credit);
  final Credit credit;

  @override
  Widget build(BuildContext context) {
    final license = credit.license;
    return NavRow(
      title: credit.source,
      translateTitle: false,
      value: license == null ? credit.useKey : StringsManager.creditLine,
      args: {'use': context.tr(credit.useKey), 'license': ?license},
    );
  }
}
