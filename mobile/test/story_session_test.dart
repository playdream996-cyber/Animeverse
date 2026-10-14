import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/story_session.dart';

void main() {
  test('historical fork excludes future turns and notes, survives reload', () {
    final s = StorySession('Academy', 'Aira');
    s.send('key'); s.finishReply();
    s.addMemory('Future discovery'); s.updateSummary('Future recap');
    s.fork(throughTurn: 0);
    expect(s.turns.length, 1);
    expect(s.memories, isEmpty);
    expect(s.summary, isNot(contains('Future recap')));
    s.addMemory('Branch-only fact'); s.updateSummary('Alternate recap');
    final restored = StorySession.fromJson(s.toJson());
    expect(restored.memories, ['Branch-only fact']);
    restored.selectBranch('Original');
    expect(restored.turns.length, 3);
    expect(restored.memories, contains('Future discovery'));
    expect(restored.memories, isNot(contains('Branch-only fact')));
    expect(restored.summary, 'Future recap');
    restored.dispose(); s.dispose();
  });
  test('current fork copies notes without sharing mutable state', () {
    final s = StorySession('Academy', 'Aira');
    s.fork(); s.addMemory('Alternate fact'); s.updateSummary('Alternate recap');
    s.selectBranch('Original');
    expect(s.memories, isNot(contains('Alternate fact')));
    expect(s.summary, isNot('Alternate recap'));
    s.dispose();
  });
  test('legacy saves retain shared notes only on their active timeline', () {
    final s = StorySession('Academy', 'Aira'); s.fork();
    final j = s.toJson()..remove('branchSummaries')..remove('branchMemories');
    final restored = StorySession.fromJson(j);
    expect(restored.memories, isNotEmpty);
    restored.selectBranch('Original'); expect(restored.memories, isEmpty);
    restored.dispose(); s.dispose();
  });
  testWidgets('stop preserves partial text and allows a fresh turn', (tester) async {
    final session = StorySession('Academy', 'Aira');
    session.send('key');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 90));
    final partial = session.visibleReply;
    session.stopReply();
    expect(session.turns.last.text, partial);
    expect(session.replyStopped, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(session.turns.last.text, partial);
    session.send('trust');
    expect(session.isReplying, isTrue);
    session.stopReply();
    session.dispose();
  });

  testWidgets('reply loads, reveals text, blocks duplicate sends and branch changes', (tester) async {
    final session = StorySession('Academy', 'Aira');
    session.send('key');
    expect(session.isReplying, isTrue);
    expect(session.visibleReply, isEmpty);
    expect(session.turns.length, 2);
    session.send('duplicate');
    session.fork();
    expect(session.turns.length, 2);
    expect(session.branches.length, 1);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 60));
    expect(session.visibleReply, isNotEmpty);
    expect(session.visibleReply.length, lessThan(session.pendingReply.length));
    await tester.pump(const Duration(seconds: 4));
    expect(session.isReplying, isFalse);
    expect(session.turns.last.text, contains('matching lock'));
    session.dispose();
  });
  testWidgets('disposing cancels pending reply', (tester) async {
    final session = StorySession('Academy', 'Aira');
    session.send('key');
    session.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(session.turns.length, 2);
  });
  test('branch actions do not alter the original transcript', () {
    final session = StorySession('Academy', 'Aira');
    session.send('Examine the key');
    session.finishReply();
    final originalCount = session.turns.length;
    session.fork();
    session.send('Follow the chime');
    session.finishReply();
    expect(session.turns.length, originalCount + 2);
    session.selectBranch('Original');
    expect(session.turns.length, originalCount);
    session.dispose();
  });
  test('notes are editable, deduplicated and session scoped', () {
    final first = StorySession('Academy', 'Aira');
    final second = StorySession('Signals', 'Ren');
    first.addMemory('  The key is warm.  ');
    first.addMemory('The key is warm.');
    expect(first.memories.where((m) => m == 'The key is warm.').length, 1);
    expect(second.memories, isNot(contains('The key is warm.')));
    first.removeMemory('The key is warm.');
    expect(first.memories, isNot(contains('The key is warm.')));
    first.updateSummary('A new discovery');
    expect(first.summary, 'A new discovery');
    first.send('   ');
    expect(first.turns.length, 1);
    first.dispose(); second.dispose();
  });
}
