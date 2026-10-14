import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/adventure_rules.dart';
import 'package:animeverse/authored_story.dart';
import 'package:animeverse/story_session.dart';
import 'package:animeverse/creator/project_library.dart';

void act(StorySession s,String label) {s.send(label);s.finishReply();}
void main() {
  test('authored adventure validates, reaches two endings and restores checkpoint state', () {
    final s=StorySession('Lighthouse','Mika',story:lighthouseStory(),playerName:'Noor');
    expect(s.story!.rules!.validate(),isEmpty);expect(s.turns.first.text,contains('Noor'));
    act(s,'Search the keeper’s desk');act(s,'Study the signal');
    final checkpoint=s.turns.length-1;
    act(s,'Relight the lighthouse');expect(s.ending!.id,'dawn');
    final completedCount=s.turns.length;s.send('extra');expect(s.turns.length,completedCount);
    s.fork(throughTurn:checkpoint);expect(s.completed,isFalse);expect(s.state!.stats['insight'],2);
    expect(s.state!.goals,isNot(contains('light')));act(s,'Leave a signal for tomorrow');expect(s.ending!.id,'tomorrow');
    final restored=StorySession.fromJson(s.toJson());expect(restored.ending!.id,'tomorrow');
    restored.selectBranch('Original');expect(restored.ending!.id,'dawn');expect(restored.playerName,'Noor');
    restored.dispose();s.dispose();
  });
  test('alternate start is pinned and endless mode never awards terminal endings', () {
    final story=lighthouseStory();final j=story.toJson()..['mode']='Endless world';
    final p=ProjectLibrary(MemoryProjectStorage());
    final imported=p.importDraft(jsonEncode({'format':'animeverse-original-story','version':1,'draft':{
      'id':'x','title':story.title,'premise':story.description,'world':story.world,'role':story.playerRole,'goal':story.goal,
      'opening':story.opening,'genre':story.genre,'tone':'Hopeful','character':'Mika','mode':j['mode'],'art':story.art,'rules':story.rules!.toJson()}}));
    final s=StorySession(story.title,'Mika',story:imported.definition(1),startId:'tower');
    expect(s.selectedStart,'tower');act(s,'Study the signal');act(s,'Relight the lighthouse');
    expect(s.completed,isFalse);expect(s.state!.goals,contains('light'));expect(s.choices,isNotEmpty);
    s.dispose();p.dispose();
  });
  test('stat bounds, eligibility and canonical actions prevent invented effects', () {
    final r=lighthouseRules();var s=r.initial('harbor');
    expect(()=>r.advance(s,const ActionRule('invented','fake','fake','harbor',deltas:{'insight':999})),throwsStateError);
    s=r.advance(s,r.scene('harbor').actions.first);s=r.advance(s,r.scene('tower').actions.first);
    s=r.advance(s,const ActionRule('tune','fake','fake','harbor',deltas:{'insight':999},ending:'dawn'));
    expect(s.stats['insight'],3);expect(s.scene,'beacon');expect(s.ending,isEmpty);
    s=r.advance(s,r.scene('beacon').actions.first);expect(s.stats['insight'],3);
    final early=r.initial('tower');expect(r.ending('dawn')!.eligible(early),isFalse);
  });
  test('lore activation, priorities and maximum active entries respect state', () {
    final r=lighthouseRules();var s=r.initial('harbor');
    expect(r.activeLore(s).map((l)=>l.id),['world']);
    s=r.advance(s,r.scene('harbor').actions.last);s=r.advance(s,r.scene('tower').actions.first);
    expect(r.activeLore(s).map((l)=>l.id),['signal','keeper','world']);
  });
  for(final failure in [PreviewFailure.offline,PreviewFailure.timeout,PreviewFailure.interrupted]) {
    testWidgets('${failure.name} retries exactly once without duplicate input or premature effects',(tester)async{
      final transport=PreviewTransport()..nextFailure=failure;
      final s=StorySession('Lighthouse','Mika',story:lighthouseStory(),transport:transport);
      s.send('Search the keeper’s desk');s.send('duplicate');
      await tester.pump(const Duration(milliseconds:550));
      if(failure==PreviewFailure.interrupted) await tester.pump(const Duration(milliseconds:200));
      expect(s.isReplying,isFalse);expect(s.replyError,isNotNull);expect(s.state!.actions,0);expect(s.state!.goals,isEmpty);
      expect(s.turns.where((t)=>t.speaker=='You').length,1);
      s.retryReply();s.retryReply();s.finishReply();expect(s.state!.actions,1);expect(s.state!.goals,['map']);
      expect(s.turns.length,3);expect(s.canRetry,isFalse);s.dispose();
    });
  }
  test('interrupted state persists and retry replaces partial without double award', () {
    final s=StorySession('Lighthouse','Mika',story:lighthouseStory());s.send('Search the keeper’s desk');
    final payload=s.toJson()..['visibleReply']='You find';s.dispose();
    final restored=StorySession.fromJson(payload);expect(restored.state!.actions,0);expect(restored.turns.last.partial,isTrue);
    restored.retryReply();restored.finishReply();expect(restored.state!.actions,1);expect(restored.turns.length,3);
    final again=StorySession.fromJson(restored.toJson());expect(again.state!.actions,1);expect(again.canRetry,isFalse);
    again.dispose();restored.dispose();
  });
  test('abandoning failed request cannot commit its effects in a new branch', () {
    final s=StorySession('Lighthouse','Mika',story:lighthouseStory());s.send('Search the keeper’s desk');s.stopReply();
    s.fork(throughTurn:0);expect(s.canRetry,isFalse);act(s,'Listen to Mika');expect(s.state!.actions,1);expect(s.state!.stats['trust'],1);
    s.selectBranch('Original');expect(s.state!.actions,0);s.dispose();
  });
  test('export/import isolates edition rules and excludes player state', () async {
    final p=ProjectLibrary(MemoryProjectStorage());final d=p.newDraft()..title='Original'..premise='A coast'..world='A coast'..role='Traveler'..goal='Bring boats home'..opening='A lantern.'..rules=lighthouseRules();
    final s=StorySession(d.title,d.character,story:d.definition(1));p.addSession(s);s.addMemory('PRIVATE_FACT');p.playerName='PRIVATE_NAME';
    final raw=p.exportDraft(d);expect(raw,isNot(contains('PRIVATE_FACT')));expect(raw,isNot(contains('PRIVATE_NAME')));
    final imported=p.importDraft(raw);expect(imported.id,isNot(d.id));expect(imported.rules!.validate(),isEmpty);
    final edition=await p.publish(d,WorkVisibility.private);d.rules=null;expect(edition.story.rules,isNotNull);
    expect(p.showcase,isEmpty);p.dispose();
  });
  test('invalid import leaves project intact; invalid rules cannot publish', () async {
    final p=ProjectLibrary(MemoryProjectStorage());expect(()=>p.importDraft('{'),throwsFormatException);expect(p.drafts,isEmpty);
    final d=p.newDraft()..title='X'..premise='X'..world='X'..role='X'..goal='X'..opening='X'..rules=const AdventureRules();
    expect(()=>p.importDraft(p.exportDraft(d)),throwsFormatException);expect(p.drafts.length,1);
    await expectLater(p.publish(d,WorkVisibility.private),throwsFormatException);expect(p.editions,isEmpty);p.dispose();
  });
  test('profile, reading, bookmarks, names and archive restore', () async {
    final storage=MemoryProjectStorage();final p=ProjectLibrary(storage);
    p.playerName='Noor';p.pronouns='she/her';p.avatar='Moon';p.readingSize=23;p.toggleBookmark('lighthouse');
    final d=p.newDraft();p.archiveDraft(d,true);final s=StorySession('Lighthouse','Mika');p.addSession(s);p.renameSession(s,'My journey');p.archiveSession(s,true);
    await p.flush();p.dispose();final restored=ProjectLibrary(storage);await restored.load();
    expect(restored.playerName,'Noor');expect(restored.readingSize,23);expect(restored.bookmarks,contains('lighthouse'));
    expect(restored.drafts.single.archived,isTrue);expect(restored.sessions.single.displayTitle,'My journey');expect(restored.recent,isEmpty);
    restored.archiveSession(restored.sessions.single,false);expect(restored.recent.length,1);restored.dispose();
  });
}
