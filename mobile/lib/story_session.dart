import 'dart:async';
import 'package:flutter/foundation.dart';
import 'story_catalog.dart';

class Turn {
  const Turn(this.speaker, this.text);
  final String speaker;
  final String text;
}

class StorySession extends ChangeNotifier {
  StorySession(this.title, this.character, {this.story})
      : branches = {'Original': [Turn(character, story?.opening ?? 'The lanterns go dark. A silver key appears in your hand. “You came back,” I whisper. “This time, we choose our own ending.”')]} {
    if (story != null) {
      summary = story!.opening;
      memories.clear();
    }
  }
  final StoryDefinition? story;
  List<String> get choices => story?.choices ?? const ['Examine the key', 'Can I trust you?', 'Follow the chime'];
  final String title;
  final String character;
  final Map<String, List<Turn>> branches;
  String activeBranch = 'Original';
  String summary = 'You arrived at the academy after dusk. Your companion recognized you and a mysterious silver key appeared.';
  final List<String> memories = ['You carry a silver key.', 'Your companion recognized you at the academy.'];
  List<Turn> get turns => branches[activeBranch]!;
  Map<String, dynamic> toJson() => {
    'title': title, 'character': character, 'story': story?.toJson(),
    'branches': branches.map((key, turns) => MapEntry(key,
      turns.map((t) => {'speaker': t.speaker, 'text': t.text}).toList())),
    'activeBranch': activeBranch, 'summary': summary, 'memories': memories,
    'interrupted': isReplying, 'visibleReply': visibleReply, 'replyStopped': replyStopped};
  factory StorySession.fromJson(Map<String, dynamic> j) {
    final story = j['story'] == null ? null : StoryDefinition.fromJson(Map<String, dynamic>.from(j['story'] as Map));
    final s = StorySession(j['title'] as String, j['character'] as String, story: story);
    s.branches.clear();
    (j['branches'] as Map).forEach((key, values) {
      s.branches[key as String] = (values as List).map((t) => Turn(t['speaker'] as String, t['text'] as String)).toList();
    });
    s.activeBranch = j['activeBranch'] as String;
    if (!s.branches.containsKey(s.activeBranch)) throw const FormatException('Missing saved timeline');
    s.summary = j['summary'] as String;
    s.memories..clear()..addAll(List<String>.from(j['memories'] as List));
    s.replyStopped = j['replyStopped'] == true || j['interrupted'] == true;
    final partial = j['visibleReply'] as String? ?? '';
    if (j['interrupted'] == true && partial.isNotEmpty) s.turns.add(Turn(s.character, partial));
    return s;
  }
  Timer? _replyTimer;
  bool isReplying = false;
  bool replyStopped = false;
  void stopReply() {
    if (!isReplying) return;
    _replyTimer?.cancel();
    if (visibleReply.isNotEmpty) turns.add(Turn(character, visibleReply));
    isReplying = false;
    replyStopped = true;
    visibleReply = '';
    pendingReply = '';
    notifyListeners();
  }
  String pendingReply = '';
  String visibleReply = '';
  void finishReply() {
    if (!isReplying) return;
    _replyTimer?.cancel();
    turns.add(Turn(character, pendingReply));
    isReplying = false;
    visibleReply = '';
    pendingReply = '';
    notifyListeners();
  }
  @override
  void dispose() {
    _replyTimer?.cancel();
    super.dispose();
  }
  void send(String text) {
    final clean = text.trim();
    if (clean.isEmpty || isReplying) return;
    turns.add(Turn('You', clean));
    final lower = clean.toLowerCase();
    final legacyResponse = lower.contains('key')
        ? 'I glance at the silver key. “The observatory has a matching lock. Shall we find out what it opens?”'
        : lower.contains('trust')
            ? '“You don’t have to trust me yet.” I step aside, leaving the choice to you. “Ask me one question. I’ll answer honestly.”'
            : 'A quiet chime comes from the observatory. I turn toward you. “We can follow it, or stay here and investigate. What do you choose?”';
    final selected = story?.choices.indexOf(clean) ?? -1;
    final response = story == null ? legacyResponse
        : story!.responses[selected >= 0 ? selected : (turns.where((t) => t.speaker == 'You').length - 1) % story!.responses.length];
    replyStopped = false;
    pendingReply = response;
    visibleReply = '';
    isReplying = true;
    notifyListeners();
    _replyTimer = Timer(const Duration(milliseconds: 550), () {
      var count = 0;
      final characters = response.runes.toList();
      _replyTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        count = (count + 2).clamp(0, characters.length);
        visibleReply = String.fromCharCodes(characters.take(count));
        if (count == characters.length) {
          finishReply();
        } else {
          notifyListeners();
        }
      });
    });
  }
  void fork() {
    if (isReplying) return;
    final name = 'Branch ${branches.length}';
    branches[name] = List<Turn>.of(turns);
    activeBranch = name;
    notifyListeners();
  }
  void selectBranch(String name) {
    if (isReplying || !branches.containsKey(name)) return;
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
