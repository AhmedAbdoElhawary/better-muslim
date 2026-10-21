import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/more/model/contact.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

/// feedback, rate, share and the developer, each only once its value is set (FR-044)
class ContactSection extends ConsumerWidget {
  const ContactSection({this.contact = Contact.mine, super.key});
  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = contact.email;
    final website = contact.website;
    final store = defaultTargetPlatform == TargetPlatform.iOS
        ? contact.appStoreUrl
        : contact.playStoreUrl;
    final rows = [
      if (email != null)
        NavRow(
          icon: BmIcon.ui(BmUiIcon.note, size: SizeManager.iconList.r),
          title: StringsManager.sendFeedback,
          onTap: () => _mail(context, email),
        ),
      if (store != null) ...[
        NavRow(
          icon: BmIcon(BmIconName.bookmark, size: SizeManager.iconList.r),
          title: StringsManager.rateApp,
          onTap: () => SystemChannel.openUrl(store),
        ),
        NavRow(
          icon: BmIcon.ui(BmUiIcon.share, size: SizeManager.iconList.r),
          title: StringsManager.shareApp,
          onTap: () => ref.read(shareProvider)(
            ShareParams(text: context.tr(StringsManager.shareLine, {'link': store})),
          ),
        ),
      ],
      if (website != null)
        NavRow(
          icon: BmIcon(BmIconName.home, size: SizeManager.iconList.r),
          title: StringsManager.developer,
          value: contact.developerName,
          translateValue: false,
          onTap: () => SystemChannel.openUrl(website),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupedSection(label: StringsManager.sectionContact, children: rows),
        const RSizedBox.vertical(SpaceManager.sectionGap),
      ],
    );
  }

  /// the draft opens in the mail app, nothing is sent from here (constitution VII)
  Future<void> _mail(BuildContext context, String email) async {
    final subject = context.tr(StringsManager.feedbackSubject);
    final version = await SystemChannel.version();
    final device = await SystemChannel.device();
    if (!context.mounted) return;
    final opened = await SystemChannel.mail(
      to: email,
      subject: subject,
      body: context.tr(StringsManager.feedbackBody, {
        'version': version,
        'device': device.model,
        'os': device.os,
      }),
    );
    if (!opened && context.mounted) {
      showToast(context, StringsManager.noMailApp, args: {'email': email});
    }
  }
}
