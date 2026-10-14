import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'package:animeverse/story_session.dart';
import 'load_fonts.dart';
import 'package:animeverse/creator/project_library.dart';
import 'package:animeverse/creator/creator_studio.dart';

void viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('render discovery preview', (tester) async {
    viewport(tester);
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final cover in covers) {
        await precacheImage(AssetImage(cover.art), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/discover.png'));
  });
  testWidgets('render chapter preview', (tester) async {
    viewport(tester);
    final session = StorySession('The Midnight Academy', 'Aira');
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    final context = tester.element(find.byType(LibraryScreen));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(session: session)));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final cover in covers) {
        await precacheImage(AssetImage(cover.art), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/chapter.png'));
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('render guided studio preview', (tester) async {
    viewport(tester);
    final p = ProjectLibrary(MemoryProjectStorage());
    final d = p.newDraft()..title = 'The city above the clouds'..premise = 'A missing lighthouse. A promise only you can keep.';
    await tester.pumpWidget(const AnimeverseApp());
    final context = tester.element(find.byType(LibraryScreen));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RepaintBoundary(
      key: const Key('studio'), child: CreatorStudio(library: p, draft: d, onPlay: (_) async {}))));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/art/academy.png'), context);
    });
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('studio')), matchesGoldenFile('goldens/studio.png'));
    await tester.pumpWidget(const SizedBox()); p.dispose();
  });
  testWidgets('render creator preview', (tester) async {
    viewport(tester);
    await tester.pumpWidget(const RepaintBoundary(key: Key('preview'), child: AnimeverseApp()));
    await tester.tap(find.text('Create'));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final cover in covers) {
        await precacheImage(AssetImage(cover.art), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/create.png'));
  });
}
