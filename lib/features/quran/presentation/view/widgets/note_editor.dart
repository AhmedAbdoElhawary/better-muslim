import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the Study sheet's Notes: write, change or delete the one private note of an ayah (FR-040).
/// keyed by the note's time, a save or a delete starts it again from the store
class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor(this.ayah, {super.key});

  final AyahKey ayah;

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late final Note? _note = ref.read(noteProvider(widget.ayah));
  late var _text = _note?.text ?? '';
  late var _highlight = _note?.highlight ?? true;

  /// an ayah with no note shows Add note until it is tapped
  late var _open = _note != null;

  Future<void> _save() async {
    if (_note case final note? when _text.trim().isEmpty && !_highlight) return _delete(note);
    FocusScope.of(context).unfocus();
    await ref.read(quranStoreProvider).saveNote(widget.ayah, _text, highlight: _highlight);
    if (mounted) showToast(context, StringsManager.noteSaved, icon: BmIconName.quran);
  }

  Future<void> _delete(Note note) async {
    FocusScope.of(context).unfocus();
    final confirmed = await showBmDialog(
      context,
      title: StringsManager.deleteNoteTitle,
      body: StringsManager.deleteNoteBody,
      action: StringsManager.delete,
    );
    if (!confirmed) return;
    await ref.read(quranStoreProvider).deleteNote(widget.ayah);
    if (mounted) showToast(context, StringsManager.noteDeleted, icon: BmIconName.quran);
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    return BmSwitcher(
      child: _open
          ? Column(
              key: const ValueKey(true),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HorizontalPadding(
                  padding: SpaceManager.s4,
                  child: BmTextField(
                    label: StringsManager.note,
                    hint: StringsManager.noteHint,
                    initial: note?.text,
                    maxLines: null,
                    maxHeight: SizeManager.noteMaxHeight,
                    autofocus: note == null,
                    onChanged: (text) => setState(() => _text = text),
                  ),
                ),

                /// the row pads 16 itself, like the field
                ToggleRow(
                  title: StringsManager.highlightInMushaf,
                  value: _highlight,
                  onChanged: (value) => setState(() => _highlight = value),
                ),
                HorizontalPadding(
                  padding: SpaceManager.s4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RSizedBox.vertical(SpaceManager.s3),

                      /// an existing note saved empty and unchecked is deleted, after the dialog
                      BmButton.primary(
                        StringsManager.save,
                        busy: note == null && _text.trim().isEmpty && !_highlight,
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
            )
          : HorizontalPadding(
              key: const ValueKey(false),
              padding: SpaceManager.s4,
              child: _AddNote(onTap: () => setState(() => _open = true)),
            ),
    );
  }
}

/// looks like the note field at rest, the real one takes its place on a tap
class _AddNote extends StatelessWidget {
  const _AddNote({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RegularText(StringsManager.note, color: ThemeEnum.text2),
        const RSizedBox.vertical(SpaceManager.textFieldGap),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.variant),
                borderRadius: BorderRadius.circular(RadiusManager.md.r),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: SizeManager.textField.r),
                child: const HorizontalPadding(
                  padding: SpaceManager.textFieldSide,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: RegularText(
                      StringsManager.addNote,
                      fontSize: FontSizeManager.body,
                      color: ThemeEnum.text3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// the note under its ayah on Saved, or under "12 Oct · Private" in the ayah's notes
class NoteCard extends ConsumerWidget {
  const NoteCard(
    this.note, {
    required this.onTap,
    this.onLongPress,
    this.showAyah = true,
    this.showArabic = false,
    this.radius = RadiusManager.lg,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showAyah;

  /// Highlights shows the ayah itself, its note under it only when there is one
  final bool showArabic;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = savedWhen(context, ref, note.updatedAt);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final (written, highlighted) = ref.watch(
      noteProvider(note.ayah)
          .select((note) => (note?.text.isNotEmpty ?? false, note?.highlight ?? false)),
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface),
            borderRadius: BorderRadius.circular(radius.r),
            boxShadow: [
              BoxShadow(
                color: context.getColor(highlighted ? ThemeEnum.glow : ThemeEnum.outline),
                spreadRadius: 1,
              ),
            ],
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
                if (showArabic) ...[
                  const RSizedBox.vertical(SpaceManager.noteLineGap),
                  _Arabic(note.ayah),
                ],
                if (note.text.isNotEmpty) ...[
                  const RSizedBox.vertical(SpaceManager.noteLineGap),

                  /// a scroll inside took every drag from the list, the whole note is in the Study sheet
                  RegularText(
                    note.text,
                    translate: false,
                    fontSize: FontSizeManager.body,
                    height: LineHeightManager.body,
                    color: ThemeEnum.text,
                    maxLines: 6,
                  ),
                ] else if (!showArabic) ...[
                  const RSizedBox.vertical(SpaceManager.noteLineGap),
                  const RegularText(
                    StringsManager.highlightedInMushaf,
                    fontSize: FontSizeManager.body,
                    height: LineHeightManager.body,
                    color: ThemeEnum.text2,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// in the reader's font, like a search hit
class _Arabic extends ConsumerWidget {
  const _Arabic(this.ayah);

  final AyahKey ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(ayahTextProvider(ayah)).value ?? '';
    final font = ref.watch(
      settingsProvider.select((settings) => settings.value?.quranFont ?? QuranFont.kfgqpc),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RegularText(
        font.drawn(text),
        translate: false,
        font: font.font,
        fontSize: FontSizeManager.searchAyah,
        height: LineHeightManager.searchAyah,
        color: ThemeEnum.text,
      ),
    );
  }
}
