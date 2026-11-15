import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// More › Send feedback, sent from here with no mail app. nothing leaves before Send
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _maxLength = 1000;
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  var _message = '';
  var _contact = '';
  var _wrongEmail = false;
  var _sending = false;

  Future<void> _send() async {
    final email = _contact.trim();
    if (email.isNotEmpty && !_email.hasMatch(email)) {
      setState(() => _wrongEmail = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final version = await SystemChannel.version();
    final device = await SystemChannel.device();
    if (!mounted) return;
    final details = context.tr(StringsManager.feedbackBody, {
      'version': version,
      'device': device.model,
      'os': device.os,
    });
    await CrashReporter.instance.sendFeedback(
      '${_message.trim()}\n\n$details',
      email: email.isEmpty ? null : email,
    );
    if (!mounted) return;
    showToast(context, StringsManager.feedbackSent, icon: BmIconName.settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.sendFeedback, heroTag: Routes.feedback),
            Expanded(
              child: ListView(
                padding: REdgeInsets.all(SpaceManager.screen),
                children: [
                  BmTextField(
                    label: StringsManager.feedbackMessage,
                    hint: StringsManager.feedbackMessageHint,
                    maxLines: null,
                    maxHeight: SizeManager.noteMaxHeight,
                    maxLength: _maxLength,
                    autofocus: true,
                    onChanged: (text) => setState(() => _message = text),
                  ),
                  const RSizedBox.vertical(SpaceManager.s4),
                  BmTextField(
                    label: StringsManager.feedbackEmail,
                    hint: StringsManager.feedbackEmailHint,
                    error: _wrongEmail ? StringsManager.feedbackEmailWrong : null,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onChanged: (text) => setState(() {
                      _contact = text;
                      _wrongEmail = false;
                    }),
                  ),
                  const RSizedBox.vertical(SpaceManager.s3),
                  const HorizontalPadding(
                    padding: SpaceManager.s1,
                    child: RegularText(
                      StringsManager.feedbackAttached,
                      fontSize: FontSizeManager.rowSubtitle,
                      color: ThemeEnum.text3,
                    ),
                  ),
                  const RSizedBox.vertical(SpaceManager.s6),
                  BmButton.primary(
                    StringsManager.send,
                    busy: _message.trim().isEmpty || _sending,
                    onPressed: _send,
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
