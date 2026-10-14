import 'dart:async';
import 'package:flutter/foundation.dart';
import 'adventure_rules.dart';
import 'story_catalog.dart';

enum PreviewFailure { none, offline, timeout, interrupted }
class ReplyPlan {
  const ReplyPlan(this.text, {this.failure = PreviewFailure.none});
  final String text;
  final PreviewFailure failure;
}
abstract interface class ReplyTransport {
  ReplyPlan request(String authoredReply);
}
/// An injectable local transport. Faults are test controls, never network claims.
class PreviewTransport implements ReplyTransport {
  PreviewFailure nextFailure = PreviewFailure.none;
  @override
  ReplyPlan request(String authoredReply) {
    final failure = nextFailure; nextFailure = PreviewFailure.none;
    return ReplyPlan(authoredReply, failure: failure);
  }
}
class Turn {
  const Turn(this.speaker, this.text, {this.state, this.partial = false});
  final String speaker, text;
  final AdventureState? state;
  final bool partial;
  Map<String,dynamic> toJson() => {'speaker':speaker, 'text':text, 'state':state?.toJson(), 'partial':partial};
  factory Turn.fromJson(Map<String,dynamic> j) => Turn(j['speaker'],j['text'],state:j['state']==null?null:AdventureState.fromJson(object(j['state'])),partial:j['partial']==true);
}
class StorySession extends ChangeNotifier {
  StorySession(this.title, this.character, {this.story, String? startId, this.playerName = 'You', this.pronouns = 'they/them', this.avatar = 'Star', ReplyTransport? transport})
      : transport = transport ?? PreviewTransport(),
        id = '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
        updatedAt = DateTime.now().millisecondsSinceEpoch,
        branches = {'Original': []} {
    selectedStart = startId ?? story?.rules?.starts.first.id ?? '';
    final rules = story?.rules;
    final start = rules?.starts.firstWhere((s)=>s.id==selectedStart,orElse:()=>rules.starts.first);
    final opening = start?.opening ?? story?.opening ?? 'The lanterns go dark. A silver key appears in your hand. “You came back,” I whisper. “This time, we choose our own ending.”';
    branches['Original']!.add(Turn(character, personalize(opening), state:rules?.initial(selectedStart)));
    if (story != null) { summary = personalize(opening); memories.clear(); }
  }
  static int _nextId = 0;
  final StoryDefinition? story;
  final ReplyTransport transport;
  String id, selectedStart = '', playerName, pronouns, avatar;
  int updatedAt;
  bool archived = false;
  String label = '';
  String get displayTitle => label.isEmpty ? title : label;
  String personalize(String text) => text.replaceAll('{player}',playerName).replaceAll('{pronouns}',pronouns);
  AdventureState? get state => turns.reversed.map((t)=>t.state).whereType<AdventureState>().firstOrNull;
  EndingRule? get ending => story?.rules?.ending(state?.ending ?? '');
  bool get completed => ending != null;
  List<String> get choices => completed ? [] : story?.rules == null
    ? story?.choices ?? const ['Examine the key','Can I trust you?','Follow the chime']
    : story!.rules!.scene(state!.scene).actions.where((a)=>a.available(state!)).map((a)=>a.label).toList();
  final String title, character;
  final Map<String,List<Turn>> branches;
  String activeBranch = 'Original';
  final Map<String,String> _summaries = {'Original':'You arrived at the academy after dusk. Your companion recognized you and a mysterious silver key appeared.'};
  String get summary => _summaries[activeBranch] ?? '';
  set summary(String value) => _summaries[activeBranch] = value;
  final Map<String,List<String>> _memories = {'Original':['You carry a silver key.','Your companion recognized you at the academy.']};
  List<String> get memories => _memories.putIfAbsent(activeBranch,()=>[]);
  List<Turn> get turns => branches[activeBranch]!;
  String? replyError;
  AdventureState? _pendingState;
  String _retryText = '';
  bool get canRetry => !isReplying && _retryText.isNotEmpty;
  Map<String,dynamic> toJson() => {
    'id':id,'updatedAt':updatedAt,'archived':archived,'label':label,'selectedStart':selectedStart,
    'playerName':playerName,'pronouns':pronouns,'avatar':avatar,'title':title,'character':character,'story':story?.toJson(),
    'branches':branches.map((k,v)=>MapEntry(k,v.map((t)=>t.toJson()).toList())),
    'activeBranch':activeBranch,'summary':summary,'memories':memories,'branchSummaries':_summaries,'branchMemories':_memories,
    'interrupted':isReplying,'visibleReply':visibleReply,'replyStopped':replyStopped,
    'retryText':_retryText,'pendingState':_pendingState?.toJson(),'replyError':replyError};
  factory StorySession.fromJson(Map<String,dynamic> j) {
    final story = j['story']==null?null:StoryDefinition.fromJson(object(j['story']));
    final s = StorySession(j['title'],j['character'],story:story,startId:j['selectedStart'],playerName:j['playerName']??'You',pronouns:j['pronouns']??'they/them',avatar:j['avatar']??'Star');
    s.id=j['id']??s.id; s.updatedAt=j['updatedAt']??s.updatedAt; s.archived=j['archived']==true; s.label=j['label']??'';
    s.branches.clear();
    (j['branches'] as Map).forEach((key,values) { s.branches[key as String]=objects(values,Turn.fromJson); });
    s.activeBranch=j['activeBranch'];
    if (!s.branches.containsKey(s.activeBranch) || s.turns.isEmpty) throw const FormatException('Missing saved timeline');
    s._summaries.clear(); s._memories.clear();
    for(final name in s.branches.keys) {
      s._summaries[name]=j['branchSummaries'] is Map?(j['branchSummaries'][name] as String? ?? ''):(name==s.activeBranch?j['summary'] as String:'');
      s._memories[name]=j['branchMemories'] is Map?strings(j['branchMemories'][name]):(name==s.activeBranch?strings(j['memories']):[]);
    }
    s.replyStopped=j['replyStopped']==true || j['interrupted']==true;
    s._retryText=j['retryText']??'';
    s._pendingState=j['pendingState']==null?null:AdventureState.fromJson(object(j['pendingState']));
    s.replyError=j['replyError'];
    final partial=j['visibleReply'] as String? ?? '';
    if(j['interrupted']==true && partial.isNotEmpty) s.turns.add(Turn(s.character,partial,state:s.state,partial:true));
    if(j['interrupted']==true) s.replyError='Reply interrupted. Retry when you are ready.';
    return s;
  }
  Timer? _replyTimer;
  bool isReplying=false, replyStopped=false;
  String pendingReply='', visibleReply='';
  void _notify() { updatedAt=DateTime.now().millisecondsSinceEpoch; notifyListeners(); }
  void stopReply() {
    if(!isReplying) return;
    _replyTimer?.cancel();
    if(visibleReply.isNotEmpty) turns.add(Turn(character,visibleReply,state:state,partial:true));
    isReplying=false; replyStopped=true; visibleReply=''; pendingReply='';
    replyError='Reply interrupted. Retry or choose a new action.'; _notify();
  }
  void finishReply() {
    if(!isReplying) return;
    _replyTimer?.cancel();
    turns.add(Turn(character,pendingReply,state:_pendingState ?? state));
    isReplying=false; visibleReply=''; pendingReply=''; _retryText=''; _pendingState=null; replyError=null; _notify();
  }
  void send(String text) {
    final clean=text.trim();
    if(clean.isEmpty || isReplying || completed) return;
    _retryText=''; _pendingState=null;
    turns.add(Turn('You',clean,state:state));
    final rules=story?.rules;
    String response;
    if(rules!=null) {
      final action=rules.scene(state!.scene).actions.where((a)=>a.label.toLowerCase()==clean.toLowerCase() && a.available(state!)).firstOrNull;
      if(action==null) { response='In this authored preview, choose a suggested action to change the world. Your free-text message has been recorded.'; }
      else { _pendingState=rules.advance(state!,action,endless:story!.mode=='Endless world'); response=personalize(action.reply); }
    } else {
      final lower=clean.toLowerCase();
      final legacy=lower.contains('key')?'I glance at the silver key. “The observatory has a matching lock. Shall we find out what it opens?”':lower.contains('trust')?'“You don’t have to trust me yet.” I step aside, leaving the choice to you. “Ask me one question. I’ll answer honestly.”':'A quiet chime comes from the observatory. I turn toward you. “We can follow it, or stay here and investigate. What do you choose?”';
      final selected=story?.choices.indexOf(clean)??-1;
      response=story==null || story!.responses.isEmpty?legacy:story!.responses[(selected>=0?selected:turns.where((t)=>t.speaker=='You').length-1)%story!.responses.length];
    }
    _retryText=response; _beginReply();
  }
  void retryReply() {
    if(!canRetry || completed) return;
    if(turns.last.partial) turns.removeLast();
    _beginReply();
  }
  void _beginReply() {
    final plan=transport.request(_retryText);
    replyStopped=false; replyError=null; pendingReply=plan.text; visibleReply=''; isReplying=true; _notify();
    _replyTimer=Timer(const Duration(milliseconds:550),(){
      if(plan.failure==PreviewFailure.offline || plan.failure==PreviewFailure.timeout) {
        isReplying=false; pendingReply=''; replyError=plan.failure==PreviewFailure.offline?'Offline test: reply was not received. Retry.':'Timeout test: reply was not received. Retry.'; _notify(); return;
      }
      var count=0; final characters=plan.text.runes.toList();
      _replyTimer=Timer.periodic(const Duration(milliseconds:30),(_){
        count=(count+2).clamp(0,characters.length); visibleReply=String.fromCharCodes(characters.take(count));
        if(plan.failure==PreviewFailure.interrupted && count>=10) { stopReply(); }
        else if(count==characters.length) { finishReply(); }
        else { _notify(); }
      });
    });
  }
  void _clearPending() { _retryText=''; _pendingState=null; pendingReply=''; visibleReply=''; replyError=null; replyStopped=false; }
  void fork({int? throughTurn}) {
    if(isReplying) return;
    final last=throughTurn??turns.length-1;
    if(last<0 || last>=turns.length) return;
    final prefix=turns.take(last+1).toList(); final atEnd=last==turns.length-1;
    final recap=atEnd?summary:prefix.map((t)=>'${t.speaker}: ${t.text}').join('\n');
    final facts=atEnd?List<String>.of(memories):<String>[];
    final name='Branch ${branches.length}'; branches[name]=prefix; _summaries[name]=recap; _memories[name]=facts; activeBranch=name; _clearPending(); _notify();
  }
  void selectBranch(String name) { if(isReplying || !branches.containsKey(name)) return; activeBranch=name; _clearPending(); _notify(); }
  void updateSummary(String value) { summary=value.trim(); _notify(); }
  void addMemory(String value) { final clean=value.trim(); if(clean.isNotEmpty && !memories.contains(clean)) memories.add(clean); _notify(); }
  void removeMemory(String value) { memories.remove(value); _notify(); }
  @override
  void dispose() { _replyTimer?.cancel(); super.dispose(); }
}
