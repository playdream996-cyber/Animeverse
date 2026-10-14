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
  final Map<String, String> _summaries = {'Original': 'You arrived at the academy after dusk. Your companion recognized you and a mysterious silver key appeared.'};
  String get summary => _summaries[activeBranch] ?? '';
  set summary(String value) => _summaries[activeBranch] = value;
  final Map<String, List<String>> _memories = {'Original': ['You carry a silver key.', 'Your companion recognized you at the academy.']};
  List<String> get memories => _memories.putIfAbsent(activeBranch, () => []);
  List<Turn> get turns => branches[activeBranch]!;
  Map<String, dynamic> toJson() => {
    'title': title, 'character': character, 'story': story?.toJson(),
    'branches': branches.map((key, turns) => MapEntry(key,
      turns.map((t) => {'speaker': t.speaker, 'text': t.text}).toList())),
    'activeBranch': activeBranch, 'summary': summary, 'memories': memories,
    'branchSummaries': _summaries, 'branchMemories': _memories,
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
    s._summaries.clear(); s._memories.clear();
    for (final name in s.branches.keys) {
      // Old saves had shared notes. Retain them on the active branch only;
      // never infer historical facts for another timeline.
      s._summaries[name] = j['branchSummaries'] is Map
          ? (j['branchSummaries'][name] as String? ?? '')
          : (name == s.activeBranch ? j['summary'] as String : '');
      s._memories[name] = j['branchMemories'] is Map
          ? List<String>.from(j['branchMemories'][name] as List? ?? [])
          : (name == s.activeBranch ? List<String>.from(j['memories'] as List) : []);
    }
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
  void fork({int? throughTurn}) {
    if (isReplying) return;
    final last = throughTurn ?? turns.length - 1;
    if (last < 0 || last >= turns.length) return;
    final prefix = turns.take(last + 1).toList();
    final atEnd = last == turns.length - 1;
    final branchSummary = atEnd ? summary : prefix.map((t) => '${t.speaker}: ${t.text}').join('\n');
    final branchMemories = atEnd ? List<String>.of(memories) : <String>[];
    final name = 'Branch ${branches.length}';
    branches[name] = prefix;
    _summaries[name] = branchSummary;
    _memories[name] = branchMemories;
    activeBranch = name;
    replyStopped = false;
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
