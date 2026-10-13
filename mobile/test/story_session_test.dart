import 'package:flutter_test/flutter_test.dart';
import 'package:animeverse/story_session.dart';

void main() {
  test('branch actions do not alter the original transcript', () {
    final session = StorySession('Academy', 'Aira');
    session.send('Examine the key');
    final originalCount = session.turns.length;
    session.fork();
    session.send('Follow the chime');
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
