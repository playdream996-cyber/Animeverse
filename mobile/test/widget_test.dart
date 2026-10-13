import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';

void main() {
  testWidgets('reader can choose a companion and send an action', (tester) async {
    await tester.pumpWidget(const AnimeverseApp());
    expect(find.text('Step into another life.'), findsOneWidget);
    await tester.tap(find.text('The Midnight Academy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aira'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Examine the key'));
    await tester.pumpAndSettle();
    expect(find.text('You'), findsOneWidget);
    expect(find.textContaining('matching lock'), findsOneWidget);
  });
  testWidgets('small screen and larger text render without an exception', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AnimeverseApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose companion'));
    await tester.pumpAndSettle();
    expect(find.text('Give your story a name'), findsOneWidget);
  });
}
