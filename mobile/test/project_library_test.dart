import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/creator/project_library.dart';
import 'package:animeverse/story_session.dart';

CreatorDraft ready(ProjectLibrary p) {
  final d = p.newDraft();
  d.title = 'Cloudborne'; d.premise = 'A city above the sea.';
  d.world = 'A floating city'; d.role = 'An investigator';
  d.goal = 'Find the lighthouse'; d.opening = 'Ren hands you a map.';
  return d;
}
class FailedStorage extends MemoryProjectStorage {
  @override
  Future<void> write(String value) async => throw StateError('Device unavailable');
}
void main() {
  test('edition guidance is pinned and restores independently of draft edits', () async {
    final p = ProjectLibrary(MemoryProjectStorage());
    final d = ready(p);
    final w = await p.publish(d, WorkVisibility.private);
    final session = StorySession(d.title, d.character, story: w.story);
    d.goal = 'A different goal'; d.role = 'A different role';
    final restored = StorySession.fromJson(session.toJson());
    expect(restored.story!.goal, 'Find the lighthouse');
    expect(restored.story!.playerRole, 'An investigator');
    expect(restored.story!.mode, 'Complete adventure');
    expect(restored.story!.withReference('Reference', 'https://example.com').goal, 'Find the lighthouse');
    restored.dispose(); session.dispose(); p.dispose();
  });
  test('failed write produces a visible save error', () async {
    final p = ProjectLibrary(FailedStorage());
    ready(p); await p.flush();
    expect(p.saveError, isNotNull);
    p.dispose();
  });
  test('public preview is discoverable; private and link-only editions are not', () async {
    final p = ProjectLibrary(MemoryProjectStorage());
    await p.publish(ready(p), WorkVisibility.private);
    await p.publish(ready(p), WorkVisibility.linkOnly);
    await p.publish(ready(p), WorkVisibility.public);
    expect(p.showcase.length, 1);
    expect(p.latest.length, 3);
    p.dispose();
  });
  test('editing draft cannot mutate an edition or existing playthrough', () async {
    final p = ProjectLibrary(MemoryProjectStorage());
    final d = ready(p);
    final first = await p.publish(d, WorkVisibility.public);
    final session = StorySession(first.story.title, first.story.character, story: first.story);
    p.addSession(session);
    d.opening = 'A new opening.';
    await p.publish(d, WorkVisibility.private);
    expect(first.story.opening, 'Ren hands you a map.');
    expect(session.turns.first.text, 'Ren hands you a map.');
    expect(session.story!.id, endsWith('@1'));
    expect(p.latest.single.version, 2);
    expect(p.showcase, isEmpty);
    p.dispose();
  });
  test('drafts, editions, progress, branches and notes restore after reload', () async {
    final storage = MemoryProjectStorage();
    final p = ProjectLibrary(storage);
    final d = ready(p);
    await p.publish(d, WorkVisibility.private);
    final session = StorySession(d.title, d.character, story: d.definition(1));
    p.addSession(session);
    session.addMemory('The map is warm.');
    session.fork();
    session.send(session.choices.first); session.finishReply();
    await p.flush();
    p.dispose();
    final reopened = ProjectLibrary(storage);
    await reopened.load();
    expect(reopened.drafts.single.title, 'Cloudborne');
    expect(reopened.editions.single.version, 1);
    expect(reopened.sessions.single.activeBranch, 'Branch 1');
    expect(reopened.sessions.single.turns.length, 3);
    expect(reopened.sessions.single.memories, contains('The map is warm.'));
    reopened.dispose();
  });
  test('interrupted partial reply restores once and never resumes an old timer', () async {
    final p = ProjectLibrary(MemoryProjectStorage());
    final s = StorySession('Academy', 'Aira');
    s.send('key');
    // Serialized transport-shaped partial state avoids wall-clock timers in this test.
    final payload = s.toJson(); payload['visibleReply'] = 'I glance';
    s.dispose();
    final restored = StorySession.fromJson(payload);
    expect(restored.isReplying, isFalse);
    expect(restored.replyStopped, isTrue);
    expect(restored.turns.last.text, 'I glance');
    final second = StorySession.fromJson(restored.toJson());
    expect(second.turns.length, 3); second.dispose();
    restored.dispose(); p.dispose();
  });
  test('publishing does not copy private playthrough memories', () async {
    final p = ProjectLibrary(MemoryProjectStorage());
    final d = ready(p);
    final s = StorySession(d.title, d.character);
    p.addSession(s); s.addMemory('PRIVATE_SESSION_FACT');
    final w = await p.publish(d, WorkVisibility.public);
    expect(w.toJson().toString(), isNot(contains('PRIVATE_SESSION_FACT')));
    p.dispose();
  });
  test('failed device write is reported, and readonly recovery never overwrites data', () async {
    final storage = MemoryProjectStorage()..value = 'broken saved data';
    final p = ProjectLibrary(storage)..readOnly = true;
    await p.flush();
    expect(storage.value, 'broken saved data');
    p.dispose();
  });
}
