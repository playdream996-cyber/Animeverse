import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/main.dart';
import 'package:animeverse/adventure_rules.dart';
import 'package:animeverse/authored_story.dart';
import 'package:animeverse/story_session.dart';
import 'package:animeverse/player_panels.dart';
import 'package:animeverse/creator/rules_editor.dart';
import 'package:animeverse/creator/project_library.dart';
import 'load_fonts.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
}
void main(){
  setUpAll(loadPreviewFonts);
  testWidgets('discover, bookmark, select alternate start and reach an ending',(tester)async{
    phone(tester);final p=ProjectLibrary(MemoryProjectStorage())..playerName='Noor';
    await tester.pumpWidget(AnimeverseApp(library:p));
    await tester.enterText(find.byType(TextField).first,'Lighthouse Promise');await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('The Lighthouse Promise').first);await tester.pumpAndSettle();
    await tester.tap(find.text('The Lighthouse Promise').first);await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bookmark story'));await tester.pumpAndSettle();await tester.tap(find.text('Bookmark story'));await tester.pumpAndSettle();
    expect(p.bookmarks,contains('original-lighthouse-v1'));
    await tester.ensureVisible(find.text('Start adventure'));await tester.pumpAndSettle();await tester.tap(find.text('Start adventure'));await tester.pumpAndSettle();
    await tester.tap(find.text('Inside the tower'));await tester.pumpAndSettle();
    expect(p.sessions.single.selectedStart,'tower');expect(p.sessions.single.turns.first.text,contains('Noor'));
    for(final action in ['Study the signal','Relight the lighthouse']) {
      await tester.ensureVisible(find.text(action).last);await tester.pumpAndSettle();await tester.tap(find.text(action).last);
      await tester.pump(const Duration(milliseconds:550));await tester.pump(const Duration(seconds:5));await tester.pumpAndSettle();
    }
    expect(p.sessions.single.completed,isTrue);expect(find.text('A light for everyone'),findsOneWidget);
    await tester.ensureVisible(find.text('Try another ending'));await tester.pumpAndSettle();await tester.tap(find.text('Try another ending'));await tester.pumpAndSettle();
    expect(p.sessions.single.completed,isFalse);expect(p.sessions.single.state!.goals,isNot(contains('light')));
    expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());
  });
  testWidgets('creator edits a bounded stat and applies the playable rules',(tester)async{
    phone(tester);AdventureRules? saved;
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:const Scaffold()));
    final context=tester.element(find.byType(Scaffold));
    Navigator.of(context).push(MaterialPageRoute<AdventureRules>(builder:(_)=>RulesEditor(rules:lighthouseRules()))).then((r)=>saved=r);
    await tester.pumpAndSettle();await tester.tap(find.text('Stats (3)'));await tester.pumpAndSettle();
    final name=find.widgetWithText(TextFormField,'Stat name').first;
    await tester.ensureVisible(name);await tester.pumpAndSettle();await tester.enterText(name,'Clarity');tester.testTextInput.hide();await tester.pumpAndSettle();
    await tester.tap(find.text('Apply rules').first);await tester.pumpAndSettle();expect(saved!.stats.first.name,'Clarity');expect(saved!.validate(),isEmpty);
    expect(tester.takeException(),isNull);
  });
  testWidgets('reading and identity controls save on a phone',(tester)async{
    phone(tester);final p=ProjectLibrary(MemoryProjectStorage());
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:const Scaffold()));
    Navigator.of(tester.element(find.byType(Scaffold))).push(MaterialPageRoute<void>(builder:(_)=>PlayerSettings(library:p)));
    await tester.pumpAndSettle();await tester.enterText(find.byType(TextField),'Noor');tester.testTextInput.hide();await tester.pumpAndSettle();
    await tester.tap(find.text('she/her'));await tester.tap(find.text('Moon'));
    await tester.ensureVisible(find.text('Save settings'));await tester.pumpAndSettle();await tester.tap(find.text('Save settings'));await tester.pumpAndSettle();
    expect(p.playerName,'Noor');expect(p.pronouns,'she/her');expect(p.avatar,'Moon');expect(tester.takeException(),isNull);p.dispose();
  });
  testWidgets('large text adventure status has no overflow and renders',(tester)async{
    phone(tester);final s=StorySession('Lighthouse','Mika',story:lighthouseStory());
    s.send('Listen to Mika');s.finishReply();s.send('Study the signal');s.finishReply();
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:MediaQuery(data:const MediaQueryData(textScaler:TextScaler.linear(1.4)),
      child:Scaffold(appBar:AppBar(title:const Text('Your adventure')),body:RepaintBoundary(key:const Key('adventure'),child:SingleChildScrollView(child:AdventurePanel(session:s)))))));
    await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    await expectLater(find.byKey(const Key('adventure')),matchesGoldenFile('goldens/adventure.png'));
    await tester.pumpWidget(const SizedBox());s.dispose();
  });
  testWidgets('ending screen and restart render on a phone',(tester)async{
    phone(tester);final s=StorySession('Lighthouse','Mika',story:lighthouseStory());
    for(final action in ['Search the keeper’s desk','Study the signal','Relight the lighthouse']){s.send(action);s.finishReply();}
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:RepaintBoundary(key:const Key('ending'),child:Scaffold(appBar:AppBar(title:const Text('Journey complete')),body:SingleChildScrollView(child:AdventurePanel(session:s))))));
    await tester.pumpAndSettle();await tester.ensureVisible(find.text('ENDING UNLOCKED'));await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('ending')),matchesGoldenFile('goldens/ending.png'));
    await tester.ensureVisible(find.text('Restart this start'));await tester.pumpAndSettle();await tester.tap(find.text('Restart this start'));await tester.pumpAndSettle();
    expect(s.state!.actions,0);expect(s.completed,isFalse);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());s.dispose();
  });
}
