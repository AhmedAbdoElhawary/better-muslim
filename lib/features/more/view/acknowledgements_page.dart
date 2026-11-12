import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/more/model/credits.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// each source with the credit its license asks for, then the packages' own licenses (FR-033)
class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.acknowledgements, heroTag: Routes.acknowledgements),
            Expanded(
              child: ListView(
                padding: REdgeInsets.all(SpaceManager.screen),
                children: [
                  GroupedSection(children: [for (final credit in credits) _CreditRow(credit)]),
                  const RSizedBox.vertical(SpaceManager.s3),
                  GroupedSection(
                    children: [
                      NavRow(
                        title: StringsManager.openSourceLicenses,
                        onTap: () => showLicensePage(context: context),
                      ),
                    ],
                  ),
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
    final link = credit.link;
    return NavRow(
      title: credit.source,
      translateTitle: false,
      value: license == null ? credit.useKey : StringsManager.creditLine,
      args: {'use': context.tr(credit.useKey), 'license': ?license},
      onTap: link == null ? null : () => SystemChannel.openUrl(link),
    );
  }
}
