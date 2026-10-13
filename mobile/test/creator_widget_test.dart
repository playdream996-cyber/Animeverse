import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'package:animeverse/creator/project_library.dart';
import 'package:animeverse/creator/creator_studio.dart';
import 'load_fonts.dart';

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('creator completes guided flow and saves a public local edition', (tester) async {
    final p = ProjectLibrary(MemoryProjectStorage());
    final d = p.newDraft();
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: CreatorStudio(library: p, draft: d, onPlay: (_) async {})));
    Future<void> enter(String label, String value) async {
      final f = find.widgetWithText(TextField, label);
      await tester.scrollUntilVisible(f, 300, scrollable:
        find.descendant(of: find.byType(CreatorStudio), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
      await tester.enterText(f, value);
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
    }
    Future<void> next() async {
      await tester.scrollUntilVisible(find.text('Continue'), 300, scrollable:
        find.descendant(of: find.byType(CreatorStudio), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue')); await tester.pumpAndSettle();
    }
    await enter('Story title', 'Cloudborne');
    await enter('Premise', 'A mystery above the sea.');
    await next();
    await enter('World', 'A floating city');
    await enter('Player role', 'An investigator');
    await enter('Main goal', 'Find the lighthouse');
    await next();
    expect(d.opening, contains('Find the lighthouse'));
    await tester.scrollUntilVisible(find.text('Public'), 300, scrollable:
      find.descendant(of: find.byType(CreatorStudio), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
    await tester.tap(find.text('Public')); await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add to local showcase'), 300, scrollable:
      find.descendant(of: find.byType(CreatorStudio), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
    await tester.tap(find.text('Add to local showcase')); await tester.pumpAndSettle();
    expect(p.showcase.single.story.title, 'Cloudborne');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); p.dispose();
  });
  testWidgets('local showcase is visible in discovery without exposing private drafts', (tester) async {
    final p = ProjectLibrary(MemoryProjectStorage());
    for (final isPublic in [false, true]) {
      final d = p.newDraft()..title = isPublic ? 'Visible world' : 'Private world'
        ..premise = 'A mystery.'..world = 'City'..role = 'Explorer'..goal = 'Find home'..opening = 'A new beginning.';
      await p.publish(d, isPublic ? WorkVisibility.public : WorkVisibility.private);
    }
    await tester.pumpWidget(AnimeverseApp(library: p));
    await tester.enterText(find.byType(TextField).first, 'world');
    await tester.pumpAndSettle();
    expect(find.text('Visible world'), findsWidgets);
    expect(find.text('Private world'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
