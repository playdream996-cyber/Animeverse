import 'package:flutter/foundation.dart';

class Turn {
  const Turn(this.speaker, this.text);
  final String speaker;
  final String text;
}

class StorySession extends ChangeNotifier {
  StorySession(this.title, this.character)
      : branches = {'Original': [Turn(character, 'The lanterns go dark. A silver key appears in your hand. “You came back,” I whisper. “This time, we choose our own ending.”')]};
  final String title;
  final String character;
  final Map<String, List<Turn>> branches;
  String activeBranch = 'Original';
  String summary = 'You arrived at the academy after dusk. Your companion recognized you and a mysterious silver key appeared.';
  final List<String> memories = ['You carry a silver key.', 'Your companion recognized you at the academy.'];
  List<Turn> get turns => branches[activeBranch]!;
  void send(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    turns.add(Turn('You', clean));
    final lower = clean.toLowerCase();
    final response = lower.contains('key')
        ? 'I glance at the silver key. “The observatory has a matching lock. Shall we find out what it opens?”'
        : lower.contains('trust')
            ? '“You don’t have to trust me yet.” I step aside, leaving the choice to you. “Ask me one question. I’ll answer honestly.”'
            : 'A quiet chime comes from the observatory. I turn toward you. “We can follow it, or stay here and investigate. What do you choose?”';
    turns.add(Turn(character, response));
    notifyListeners();
  }
  void fork() {
    final name = 'Branch ${branches.length}';
    branches[name] = List<Turn>.of(turns);
    activeBranch = name;
    notifyListeners();
  }
  void selectBranch(String name) {
    if (!branches.containsKey(name)) return;
    activeBranch = name;
    notifyListeners();
  }
  void updateSummary(String value) {
    summary = value.trim();
    notifyListeners();
  }
  void addMemory(String value) {
    final clean = value.trim();
    if (clean.isNotEmpty && !memories.contains(clean)) memories.add(clean);
    notifyListeners();
  }
  void removeMemory(String value) {
    memories.remove(value);
    notifyListeners();
  }
}
