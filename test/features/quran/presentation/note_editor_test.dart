import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/note_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/providers.dart';
import '../../../helpers/widgets.dart';

void main() {
  const ayah = AyahKey(1, 5);
  final long = List.generate(60, (i) => 'line $i').join('\n');

  Future<void> pump(WidgetTester tester, Widget child, {List<Note> notes = const []}) async {
    await pumpCoreWidget(
      tester,
      ProviderScope(
        overrides: [...testOverrides(), notesProvider.overrideWith((ref) => Stream.value(notes))],

        /// the editor reads its note once, like the Study pane it waits for the notes
        child: Consumer(
          builder: (_, ref, _) =>
              ref.watch(notesProvider).hasValue ? child : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Note note(String text) =>
      Note(ayah: ayah, text: text, highlight: true, updatedAt: DateTime(2026, 10, 12));

  testWidgets('no note: Add note only, a tap opens the field with Highlight and Save', (
    tester,
  ) async {
    await pump(tester, const NoteEditor(ayah));
    expect(find.text('Add note'), findsOneWidget);
    expect(find.byType(BmTextField), findsNothing);
    expect(find.text('Highlight in mushaf'), findsNothing);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    expect(find.text('Add note'), findsNothing);
    expect(find.byType(BmTextField), findsOneWidget);
    expect(find.text('Highlight in mushaf'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await unmount(tester);
  });

  testWidgets('a note opens straight into the field, a long one stops at 300', (tester) async {
    await pump(tester, const NoteEditor(ayah), notes: [note(long)]);
    expect(find.text('Add note'), findsNothing);
    expect(find.text('Delete note'), findsOneWidget);
    final box = find.ancestor(of: find.byType(TextField), matching: find.byType(ConstrainedBox));
    expect(tester.getSize(box.first).height, lessThanOrEqualTo(SizeManager.noteMaxHeight.r + .5));
    await unmount(tester);
  });

  testWidgets('the field opens at the height of Add note and grows with the text', (tester) async {
    await pump(tester, const NoteEditor(ayah), notes: [note('one line')]);
    final box = find.ancestor(of: find.byType(TextField), matching: find.byType(ConstrainedBox));
    expect(tester.getSize(box.first).height, closeTo(SizeManager.textField.r, .5));

    await tester.enterText(find.byType(TextField), List.generate(4, (i) => 'line $i').join('\n'));
    await tester.pump();
    expect(tester.getSize(box.first).height, greaterThan(SizeManager.textField.r + .5));
    await unmount(tester);
  });

  testWidgets('Delete note asks first, Cancel keeps the note', (tester) async {
    await pump(tester, const NoteEditor(ayah), notes: [note('kept')]);
    await tester.tap(find.text('Delete note'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this note?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this note?'), findsNothing);
    expect(find.text('Delete note'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets("Saved's card cuts a long note at 6 lines and leaves every drag to the list", (
    tester,
  ) async {
    await pump(tester, NoteCard(note(long), onTap: () {}), notes: [note(long)]);
    expect(
      find.descendant(of: find.byType(NoteCard), matching: find.byType(Scrollable)),
      findsNothing,
    );
    final text = tester.widget<Text>(find.textContaining('line 0'));
    expect(text.maxLines, 6);
    await unmount(tester);
  });
}
