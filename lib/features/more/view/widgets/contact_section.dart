import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/review.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/more/model/contact.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// feedback and rate always, share and the developer only once their value is set (FR-044)
class ContactSection extends ConsumerWidget {
  const ContactSection({this.contact = Contact.mine, super.key});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final website = contact.website;
    final store = defaultTargetPlatform == TargetPlatform.iOS
        ? contact.appStoreUrl
        : contact.playStoreUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(
          label: StringsManager.sectionContact,
          children: [
            NavRow(
              icon: BmIcon.ui(BmUiIcon.note, size: SizeManager.iconList.r),
              title: StringsManager.sendFeedback,
              heroTag: Routes.feedback,
              onTap: () => context.push(Routes.feedback),
            ),
            NavRow(
              icon: BmIcon(BmIconName.bookmark, size: SizeManager.iconList.r),
              title: StringsManager.rateApp,
              onTap: () async {
                final shown = await ref.read(reviewProvider)();
                if (!shown && context.mounted) showToast(context, StringsManager.rateUnavailable);
              },
            ),
            if (store != null)
              NavRow(
                icon: BmIcon.ui(BmUiIcon.share, size: SizeManager.iconList.r),
                title: StringsManager.shareApp,
                onTap: () => ref.read(shareProvider)(
                  ShareParams(text: context.tr(StringsManager.shareLine, {'link': store})),
                ),
              ),
            if (website != null)
              NavRow(
                icon: BmIcon(BmIconName.home, size: SizeManager.iconList.r),
                title: StringsManager.developer,
                value: contact.developerName,
                translateValue: false,
                onTap: () => SystemChannel.openUrl(website),
              ),
          ],
        ),
        const RSizedBox.vertical(SpaceManager.sectionGap),
      ],
    );
  }
}
