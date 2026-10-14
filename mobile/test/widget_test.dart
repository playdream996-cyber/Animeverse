import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'load_fonts.dart';
import 'package:animeverse/creator/creator_studio.dart';

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('reader can choose a companion and send an action', (tester) async {
    await tester.pumpWidget(const AnimeverseApp());
    expect(find.text('Your next chapter\nstarts here.'), findsOneWidget);
    await tester.ensureVisible(find.text('The Midnight Academy').first);
      await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Midnight Academy').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start adventure'));
      await tester.pumpAndSettle();
    await tester.tap(find.text('Start adventure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aira'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Examine the key'), 250, scrollable: find.descendant(of: find.byType(ChatScreen), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Examine the key'));

    await tester.pump();
    expect(find.text('Aira is replying…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Aira is writing…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('You'), findsOneWidget);
    expect(find.textContaining('matching lock', findRichText: true), findsOneWidget);
  });
  testWidgets('small screen renders and empty story titles show validation', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AnimeverseApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Create story'), 250, scrollable: find.descendant(of: find.byType(LibraryScreen), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
    await tester.tap(find.text('Create story'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continue'), 300, scrollable:
      find.descendant(of: find.byType(CreatorStudio), matching: find.byType(Scrollable)).first);
      await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Add a title and premise to continue.'), findsOneWidget);
  });
}
