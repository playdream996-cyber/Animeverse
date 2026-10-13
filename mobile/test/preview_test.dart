import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'package:animeverse/story_session.dart';

void viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('render discovery preview', (tester) async {
    viewport(tester);
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/discover.png'));
  });
  testWidgets('render chapter preview', (tester) async {
    viewport(tester);
    final session = StorySession('The Midnight Academy', 'Aira');
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    final context = tester.element(find.byType(LibraryScreen));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(session: session)));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/chapter.png'));
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('render creator preview', (tester) async {
    viewport(tester);
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/create.png'));
  });
}
