import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// write, change or delete the one private note of an ayah (FR-040)
Future<void> showNoteEditor(BuildContext context, AyahKey ayah) =>
    showBmSheet(context, builder: (_) => _NoteEditor(ayah));

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor(this.ayah);

  final AyahKey ayah;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final Note? _note = ref.read(noteProvider(widget.ayah));
  late var _text = _note?.text ?? '';

  Future<void> _save() async {
    await ref.read(quranStoreProvider).saveNote(widget.ayah, _text);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(Note note) async {
    final store = ref.read(quranStoreProvider);
    await store.deleteNote(widget.ayah);
    if (!mounted) return;
    showToast(
      context,
      StringsManager.noteDeleted,
      icon: BmIconName.quran,
      onUndo: () => store.restoreNote(note),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final surah = ref.watch(quranAssetsProvider).value?.surah(widget.ayah.surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                StringsManager.quranAyahN,
                args: {
                  'surah': surah == null ? '' : (isArabic ? surah.ar : surah.en),
                  'n': context.formatDigits('${widget.ayah.ayah}', digits),
                },
                subtitle: StringsManager.private,
              ),
              HorizontalPadding(
                padding: SpaceManager.s5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BmTextField(
                      label: StringsManager.note,
                      hint: StringsManager.noteHint,
                      initial: note?.text,
                      maxLines: null,
                      autofocus: true,
                      onChanged: (text) => setState(() => _text = text),
                    ),
                    const RSizedBox.vertical(SpaceManager.s5),
                    BmButton.primary(
                      StringsManager.save,
                      busy: _text.trim().isEmpty,
                      onPressed: _save,
                    ),
                    if (note != null) ...[
                      const RSizedBox.vertical(SpaceManager.s2),
                      BmButton.text(
                        StringsManager.deleteNote,
                        color: ThemeEnum.error,
                        onPressed: () => _delete(note),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the note under its ayah on Saved, or under "12 Oct · Private" in the ayah's notes
class NoteCard extends ConsumerWidget {
  const NoteCard(
    this.note, {
    required this.onTap,
    this.showAyah = true,
    this.radius = RadiusManager.lg,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final bool showAyah;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = savedWhen(context, ref, note.updatedAt);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface),
            borderRadius: BorderRadius.circular(radius.r),
            boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
          ),
          child: SymmetricPadding(
            horizontal: SpaceManager.noteCardSide,
            vertical: SpaceManager.noteCardV,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showAyah)
                  Row(
                    children: [
                      Expanded(
                        child: SemiBoldText(
                          StringsManager.noteRef,
                          fontSize: FontSizeManager.labelStrong,
                          color: ThemeEnum.primary,
                          args: {
                            's': context.formatDigits('${note.ayah.surah}', digits),
                            'a': context.formatDigits('${note.ayah.ayah}', digits),
                          },
                        ),
                      ),
                      RegularText(
                        when,
                        translate: false,
                        fontSize: FontSizeManager.label,
                        color: ThemeEnum.text3,
                      ),
                    ],
                  )
                else
                  RegularText(
                    StringsManager.whenPrivate,
                    args: {'when': when},
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.text3,
                  ),
                const RSizedBox.vertical(SpaceManager.noteLineGap),
                RegularText(
                  note.text,
                  translate: false,
                  fontSize: FontSizeManager.body,
                  height: LineHeightManager.body,
                  color: ThemeEnum.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
