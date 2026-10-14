import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/reader.dart';
import 'package:animeverse/story_session.dart';
import 'package:animeverse/authored_story.dart';
import 'package:animeverse/adventure_rules.dart';
import 'package:animeverse/player_panels.dart';
import 'package:animeverse/creator/creator_studio.dart';
import 'package:animeverse/creator/rules_editor.dart';
import 'package:animeverse/creator/project_library.dart';
import 'package:animeverse/library_hub.dart';
import 'package:animeverse/story_files.dart';
import 'load_fonts.dart';

void phone(WidgetTester tester){tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);}
CreatorDraft draft(ProjectLibrary p)=>p.newDraft()..title='A world'..premise='A coast'..world='A coast'..role='Traveler'..goal='Find the light'..opening='Aira waits.';
class SlowStorage extends MemoryProjectStorage{int writes=0;final first=Completer<void>();@override Future<void> write(String value)async{writes++;if(writes==1)await first.future;await super.write(value);}}
class ThrowingTransport implements ReplyTransport{@override ReplyPlan request(String text)=>throw StateError('Disconnected');}
class FakeFiles implements StoryFileGateway{String? value;bool fail=false;int saves=0,shares=0;@override Future<String?> pick()async{if(fail)throw StateError('File gone');return value;}@override Future<bool> save(String text,String name)async{saves++;if(fail)throw StateError('Storage');return true;}@override Future<void> share(String text,String name,Rect origin)async{shares++;if(fail)throw StateError('No share target');}}
void main(){
  setUpAll(loadPreviewFonts);
  test('slow device writes coalesce hundreds of requests into latest snapshot',()async{
    final storage=SlowStorage();final p=ProjectLibrary(storage);final d=draft(p);final first=p.flush();
    final futures=<Future<void>>[first];for(var i=0;i<100;i++){d.title='Newest $i';p.changed();futures.add(p.flush());}
    expect(storage.writes,1);storage.first.complete();await Future.wait(futures);
    expect(storage.writes,2);expect((jsonDecode(storage.value!)['drafts'] as List).single['title'],'Newest 99');expect(p.savePhase.value,SavePhase.saved);p.dispose();
  });
  test('large transcript saves and restores with native background JSON work',()async{
    final storage=MemoryProjectStorage();final p=ProjectLibrary(storage);final s=StorySession('Long journey','Aira');
    for(var i=0;i<1500;i++){s.branches['Original']!.add(Turn(i.isEven?'You':'Aira','Message $i with a readable checkpoint.'));}
    p.addSession(s);s.recordReadingOffset(1250);s.fork(throughTurn:100);expect(s.renameBranch(s.activeBranch,'Alternate coast'),isTrue);await p.flush();p.dispose();
    final loaded=ProjectLibrary(storage);await loaded.load();final saved=loaded.sessions.single;expect(saved.turns.length,101);expect(saved.activeBranch,'Alternate coast');saved.selectBranch('Original');expect(saved.readingOffset,1250);loaded.dispose();
  });
  test('throwing transport remains retryable and cannot award progress',(){final s=StorySession('Lighthouse','Mika',story:lighthouseStory(),transport:ThrowingTransport());s.send('Search the keeper’s desk');expect(s.isReplying,isFalse);expect(s.replyError,isNotNull);expect(s.state!.actions,0);expect(s.canRetry,isTrue);s.retryReply();expect(s.turns.length,2);s.dispose();});
  test('bounded file reads reject oversized and malformed UTF8 safely',()async{
    await expectLater(readBoundedStory(Stream.value(List<int>.filled(maxStoryFileBytes+1,65))),throwsFormatException);
    await expectLater(readBoundedStory(Stream.value([255,255])),throwsFormatException);
    expect(await readBoundedStory(Stream.value(utf8.encode('{"story":"ok"}'))),'{"story":"ok"}');
  });
  testWidgets('live preview validity follows a cleared opening',(tester)async{
    phone(tester);final p=ProjectLibrary(MemoryProjectStorage());final d=draft(p);
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:CreatorStudio(library:p,draft:d,onPlay:(_)async{})));await tester.pumpAndSettle();
    final outer=find.descendant(of:find.byType(CreatorStudio),matching:find.byType(Scrollable)).first;
    for(var i=0;i<2;i++){await tester.scrollUntilVisible(find.text('Continue'),300,scrollable:outer);await tester.pumpAndSettle();await tester.tap(find.text('Continue'));await tester.pumpAndSettle();}
    final opening=find.widgetWithText(TextField,'Opening scene');await tester.ensureVisible(opening);await tester.pumpAndSettle();await tester.enterText(opening,'');tester.testTextInput.hide();await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton,'Play preview')).onPressed,isNull);await tester.pumpWidget(const SizedBox());p.dispose();
  });
  testWidgets('status sheet content reacts immediately after restart',(tester)async{
    phone(tester);final s=StorySession('Lighthouse','Mika',story:lighthouseStory());for(final a in ['Search the keeper’s desk','Study the signal','Relight the lighthouse']){s.send(a);s.finishReply();}
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:Scaffold(body:SingleChildScrollView(child:AdventurePanel(session:s)))));await tester.pumpAndSettle();await tester.ensureVisible(find.text('Restart this start'));await tester.pumpAndSettle();await tester.tap(find.text('Restart this start'));await tester.pumpAndSettle();expect(find.text('ENDING UNLOCKED'),findsNothing);expect(find.text('The waiting harbor'),findsOneWidget);await tester.pumpWidget(const SizedBox());s.dispose();
  });
  testWidgets('editor back protects unapplied changes',(tester)async{
    phone(tester);await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:const Scaffold()));Navigator.of(tester.element(find.byType(Scaffold))).push(MaterialPageRoute(builder:(_)=>RulesEditor(rules:lighthouseRules())));await tester.pumpAndSettle();
    final name=find.widgetWithText(TextFormField,'Stat name').first;await tester.ensureVisible(name);await tester.pumpAndSettle();await tester.enterText(name,'Clarity');tester.testTextInput.hide();await tester.pumpAndSettle();await tester.tap(find.byTooltip('Back'));await tester.pumpAndSettle();expect(find.text('Keep your rule changes?'),findsOneWidget);await tester.tap(find.text('Keep editing'));await tester.pumpAndSettle();expect(find.byType(RulesEditor),findsOneWidget);await tester.pumpWidget(const SizedBox());
  });
  testWidgets('reader renders a small window of a 2000-message transcript',(tester)async{
    phone(tester);final s=StorySession('Long journey','Aira');for(var i=0;i<2000;i++){s.branches['Original']!.add(Turn('Aira','Message $i. The next path is yours.'));}s.recordReadingOffset(0);
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:ChatScreen(session:s)));await tester.pumpAndSettle();expect(find.byType(TurnMessage).evaluate().length,lessThan(20));expect(tester.takeException(),isNull);
    final position=tester.state<ScrollableState>(find.byType(Scrollable).first).position;expect(position.pixels,0);await tester.pumpWidget(const SizedBox());s.dispose();
  });
  testWidgets('reopening long history uses a bounded recent page and permits older pages',(tester)async{
    phone(tester);final s=StorySession('Long journey','Aira');for(var i=0;i<2000;i++){s.branches['Original']!.add(Turn('Aira','Message $i. The next path is yours.'));}
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:ChatScreen(session:s)));await tester.pumpAndSettle();
    final list=tester.widget<SliverList>(find.byType(SliverList));expect((list.delegate as SliverChildBuilderDelegate).estimatedChildCount,lessThanOrEqualTo(40));
    await tester.scrollUntilVisible(find.text('Earlier messages'),-300,scrollable:find.descendant(of:find.byType(ChatScreen),matching:find.byType(Scrollable)).first);await tester.pumpAndSettle();await tester.tap(find.text('Earlier messages'));await tester.pumpAndSettle();
    expect(find.textContaining('Messages 1922–1961'),findsOneWidget);expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());expect(s.readingWindows['Original'],1921);s.dispose();
  });
  testWidgets('locked choices explain required stats',(tester)async{
    phone(tester);final s=StorySession('Lighthouse','Mika',story:lighthouseStory());s.send('Search the keeper’s desk');s.finishReply();s.send('Take the shortcut');s.finishReply();
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),home:ChatScreen(session:s)));await tester.pumpAndSettle();expect(find.text('Needs Insight 2 · you have 1'),findsOneWidget);expect(find.text('Relight the lighthouse'),findsOneWidget);expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());s.dispose();
  });
  testWidgets('native import failure stays in dialog and changes no drafts',(tester)async{
    final p=ProjectLibrary(MemoryProjectStorage());final files=FakeFiles()..fail=true;await tester.pumpWidget(MaterialApp(home:const Scaffold()));final context=tester.element(find.byType(Scaffold));unawaited(storyImport(context,p,files:files));await tester.pumpAndSettle();await tester.tap(find.text('Choose story file'));await tester.pumpAndSettle();expect(find.textContaining('File could not be read'),findsOneWidget);expect(p.drafts,isEmpty);expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());p.dispose();
  });
}
