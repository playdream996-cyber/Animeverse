import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'package:animeverse/story_session.dart';
import 'package:animeverse/creator/project_library.dart';
import 'load_fonts.dart';

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('reader reveals creator guidance and branches from a selected message', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final d = CreatorDraft(id: 'guide', title: 'Cloudborne', premise: 'A mystery.',
      world: 'A floating city', role: 'An investigator', goal: 'Find the lighthouse',
      opening: 'Aira gives you a map.');
    final s = StorySession(d.title, d.character, story: d.definition(1));
    s.send(s.choices.first); s.finishReply(); s.addMemory('Later clue');
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: ChatScreen(session: s)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Your adventure guide'), -300, scrollable: find.descendant(of: find.byType(ChatScreen), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your adventure guide'));
    await tester.pumpAndSettle();
    expect(find.text('Your role · An investigator'), findsOneWidget);
    expect(find.text('Your goal · Find the lighthouse'), findsOneWidget);
    final checkpoint = find.byTooltip('Branch after this message').first;
    await tester.ensureVisible(checkpoint); await tester.pumpAndSettle();
    await tester.tap(checkpoint); await tester.pumpAndSettle();
    await tester.tap(find.text('Create branch')); await tester.pumpAndSettle();
    expect(s.activeBranch, 'Branch 1'); expect(s.turns.length, 1);
    expect(s.memories, isEmpty); expect(s.branches['Original']!.length, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); s.dispose();
  });
}
