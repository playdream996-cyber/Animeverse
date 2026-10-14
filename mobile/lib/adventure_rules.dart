/// Deterministic authored rules. The server can later validate the same contracts.
Map<String, dynamic> object(dynamic value) => Map<String, dynamic>.from(value as Map);
List<T> objects<T>(dynamic value, T Function(Map<String, dynamic>) parse) =>
    (value as List? ?? []).map((x) => parse(object(x))).toList();
Map<String, int> numbers(dynamic value) => (value as Map? ?? {}).map((k, v) => MapEntry(k as String, v as int));
List<String> strings(dynamic value) => List<String>.from(value as List? ?? []);
const storyArt = ['assets/art/academy.png', 'assets/art/signals.png', 'assets/art/lantern.png'];

class StatRule {
  const StatRule(this.id, this.name, {this.min = 0, this.max = 5, this.initial = 0});
  final String id, name;
  final int min, max, initial;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'min': min, 'max': max, 'initial': initial};
  factory StatRule.fromJson(Map<String, dynamic> j) => StatRule(j['id'], j['name'], min: j['min'], max: j['max'], initial: j['initial']);
}
class GoalRule {
  const GoalRule(this.id, this.title);
  final String id, title;
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
  factory GoalRule.fromJson(Map<String, dynamic> j) => GoalRule(j['id'], j['title']);
}
class LoreRule {
  const LoreRule(this.id, this.title, this.body, {this.stat = '', this.atLeast = 0, this.priority = 0, this.scope = 'World'});
  final String id, title, body, stat, scope;
  final int atLeast, priority;
  bool active(AdventureState s) => stat.isEmpty || (s.stats[stat] ?? 0) >= atLeast;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body, 'stat': stat, 'atLeast': atLeast, 'priority': priority, 'scope': scope};
  factory LoreRule.fromJson(Map<String, dynamic> j) => LoreRule(j['id'], j['title'], j['body'], stat: j['stat'], atLeast: j['atLeast'], priority: j['priority'], scope: j['scope']);
}
class EndingRule {
  const EndingRule(this.id, this.name, this.epilogue, this.hint, {this.minTurns = 1, this.minimum = const {}, this.maximum = const {}, this.goals = const []});
  final String id, name, epilogue, hint;
  final int minTurns;
  final Map<String, int> minimum, maximum;
  final List<String> goals;
  bool eligible(AdventureState s) => s.actions >= minTurns && goals.every(s.goals.contains) &&
    minimum.entries.every((e) => (s.stats[e.key] ?? 0) >= e.value) && maximum.entries.every((e) => (s.stats[e.key] ?? 0) <= e.value);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'epilogue': epilogue, 'hint': hint, 'minTurns': minTurns, 'minimum': minimum, 'maximum': maximum, 'goals': goals};
  factory EndingRule.fromJson(Map<String, dynamic> j) => EndingRule(j['id'], j['name'], j['epilogue'], j['hint'], minTurns: j['minTurns'], minimum: numbers(j['minimum']), maximum: numbers(j['maximum']), goals: strings(j['goals']));
}
class ActionRule {
  const ActionRule(this.id, this.label, this.reply, this.next, {this.deltas = const {}, this.goals = const [], this.minimum = const {}, this.ending = ''});
  final String id, label, reply, next, ending;
  final Map<String, int> deltas, minimum;
  final List<String> goals;
  bool available(AdventureState s) => minimum.entries.every((e) => (s.stats[e.key] ?? 0) >= e.value);
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'reply': reply, 'next': next, 'deltas': deltas, 'goals': goals, 'minimum': minimum, 'ending': ending};
  factory ActionRule.fromJson(Map<String, dynamic> j) => ActionRule(j['id'], j['label'], j['reply'], j['next'], deltas: numbers(j['deltas']), goals: strings(j['goals']), minimum: numbers(j['minimum']), ending: j['ending']);
}
class SceneRule {
  const SceneRule(this.id, this.title, this.art, this.actions);
  final String id, title, art;
  final List<ActionRule> actions;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'art': art, 'actions': actions.map((a) => a.toJson()).toList()};
  factory SceneRule.fromJson(Map<String, dynamic> j) => SceneRule(j['id'], j['title'], j['art'], objects(j['actions'], ActionRule.fromJson));
}
class StartRule {
  const StartRule(this.id, this.name, this.opening, this.scene, {this.stats = const {}});
  final String id, name, opening, scene;
  final Map<String, int> stats;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'opening': opening, 'scene': scene, 'stats': stats};
  factory StartRule.fromJson(Map<String, dynamic> j) => StartRule(j['id'], j['name'], j['opening'], j['scene'], stats: numbers(j['stats']));
}
class AdventureState {
  const AdventureState({required this.scene, this.stats = const {}, this.goals = const [], this.actions = 0, this.ending = '', this.changes = const []});
  final String scene, ending;
  final Map<String, int> stats;
  final List<String> goals, changes;
  final int actions;
  Map<String, dynamic> toJson() => {'scene': scene, 'stats': stats, 'goals': goals, 'actions': actions, 'ending': ending, 'changes': changes};
  factory AdventureState.fromJson(Map<String, dynamic> j) => AdventureState(scene: j['scene'], stats: numbers(j['stats']), goals: strings(j['goals']), actions: j['actions'], ending: j['ending'], changes: strings(j['changes']));
}
class AdventureRules {
  const AdventureRules({this.stats = const [], this.goals = const [], this.lore = const [], this.endings = const [], this.scenes = const [], this.starts = const []});
  final List<StatRule> stats;
  final List<GoalRule> goals;
  final List<LoreRule> lore;
  final List<EndingRule> endings;
  final List<SceneRule> scenes;
  final List<StartRule> starts;
  Map<String, dynamic> toJson() => {'stats': stats.map((x) => x.toJson()).toList(), 'goals': goals.map((x) => x.toJson()).toList(), 'lore': lore.map((x) => x.toJson()).toList(), 'endings': endings.map((x) => x.toJson()).toList(), 'scenes': scenes.map((x) => x.toJson()).toList(), 'starts': starts.map((x) => x.toJson()).toList()};
  factory AdventureRules.fromJson(Map<String, dynamic> j) => AdventureRules(stats: objects(j['stats'], StatRule.fromJson), goals: objects(j['goals'], GoalRule.fromJson), lore: objects(j['lore'], LoreRule.fromJson), endings: objects(j['endings'], EndingRule.fromJson), scenes: objects(j['scenes'], SceneRule.fromJson), starts: objects(j['starts'], StartRule.fromJson));
  SceneRule scene(String id) => scenes.firstWhere((x) => x.id == id);
  EndingRule? ending(String id) => endings.where((x) => x.id == id).firstOrNull;
  AdventureState initial(String id) {
    final start = starts.firstWhere((x) => x.id == id, orElse: () => starts.first);
    return AdventureState(scene: start.scene, stats: {for (final s in stats) s.id: (start.stats[s.id] ?? s.initial).clamp(s.min, s.max)});
  }
  List<LoreRule> activeLore(AdventureState s) {
    final result = lore.where((x) => x.active(s)).toList()..sort((a,b) => b.priority.compareTo(a.priority));
    return result.take(3).toList();
  }
  AdventureState advance(AdventureState s, ActionRule action, {bool endless = false}) {
    final canonical = scene(s.scene).actions.where((x) => x.id == action.id).firstOrNull;
    if (s.ending.isNotEmpty || canonical == null || !canonical.available(s)) throw StateError('Action unavailable');
    action = canonical;
    final values = Map<String,int>.of(s.stats);
    final changes = <String>[];
    for (final rule in stats) {
      final old = values[rule.id] ?? rule.initial;
      final next = (old + (action.deltas[rule.id] ?? 0)).clamp(rule.min, rule.max);
      values[rule.id] = next;
      if (next != old) changes.add('${rule.name}: $old → $next · ${action.label}');
    }
    final completed = {...s.goals, ...action.goals}.toList();
    for (final g in goals.where((g) => action.goals.contains(g.id) && !s.goals.contains(g.id))) { changes.add('Objective completed: ${g.title}'); }
    var result = AdventureState(scene: action.next, stats: values, goals: completed, actions: s.actions + 1, changes: changes);
    final end = ending(action.ending);
    if (!endless && end != null && end.eligible(result)) {
      result = AdventureState(scene: result.scene, stats: values, goals: completed, actions: result.actions, changes: changes, ending: end.id);
    }
    return result;
  }
  List<String> validate() {
    final errors = <String>[];
    void fail(bool condition, String message) { if (condition) errors.add(message); }
    void ids(Iterable<String> values, String name) {
      final list = values.toList(); fail(list.any((x) => x.isEmpty) || list.toSet().length != list.length, '$name must have unique keys.');
    }
    fail(stats.length > 7 || goals.length > 20 || lore.length > 30 || endings.length > 10 || scenes.length > 30 || starts.length > 6, 'Adventure exceeds supported limits.');
    fail(starts.isEmpty || scenes.isEmpty, 'Add at least one start and scene.');
    ids(stats.map((x)=>x.id), 'Stats'); ids(goals.map((x)=>x.id), 'Objectives'); ids(lore.map((x)=>x.id), 'Lore'); ids(endings.map((x)=>x.id), 'Endings'); ids(scenes.map((x)=>x.id), 'Scenes'); ids(starts.map((x)=>x.id), 'Starts');
    final statIds = stats.map((x)=>x.id).toSet(), goalIds = goals.map((x)=>x.id).toSet(), sceneIds = scenes.map((x)=>x.id).toSet();
    void refs(Map<String,int> values, List<String> targets) { fail(values.keys.any((x)=>!statIds.contains(x)) || targets.any((x)=>!goalIds.contains(x)), 'A rule refers to a removed stat or objective.'); }
    void text(String value, String label) { fail(value.trim().isEmpty || value.length > 4000, '$label must contain 1–4000 characters.'); }
    for (final s in stats) { text(s.name, 'Stat name'); fail(s.min >= s.max || s.initial < s.min || s.initial > s.max || s.min < -1000 || s.max > 1000, 'Stat bounds or starting value are invalid.'); }
    for (final g in goals) { text(g.title, 'Objective'); }
    for (final l in lore) { text(l.title,'Lore title'); text(l.body,'Lore text'); fail(l.stat.isNotEmpty && !statIds.contains(l.stat), 'Lore trigger refers to a removed stat.'); fail(!['World','Companion'].contains(l.scope), 'Choose a lore scope.'); }
    for (final e in endings) { text(e.name,'Ending name'); text(e.epilogue,'Epilogue'); refs(e.minimum, e.goals); refs(e.maximum, []); fail(e.minTurns < 1 || e.minTurns > 1000, 'Ending needs a valid minimum action count.'); }
    for (final start in starts) { text(start.name,'Start name'); text(start.opening,'Start opening'); refs(start.stats, []); fail(!sceneIds.contains(start.scene), 'Start refers to a removed scene.'); }
    for (final s in scenes) {
      text(s.title,'Scene title'); fail(!storyArt.contains(s.art), 'Choose supported scene artwork.'); fail(s.actions.isEmpty || s.actions.length > 8, 'Each scene needs 1–8 actions.'); ids(s.actions.map((x)=>x.id), 'Scene actions'); ids(s.actions.map((x)=>x.label.trim().toLowerCase()), 'Action labels');
      for (final a in s.actions) { text(a.label,'Action label'); text(a.reply,'Action reply'); refs(a.deltas,a.goals); refs(a.minimum,[]); fail(!sceneIds.contains(a.next), 'Action refers to a removed scene.'); fail(a.ending.isNotEmpty && ending(a.ending)==null, 'Action refers to a removed ending.'); }
    }
    return errors.toSet().toList();
  }
}

AdventureRules lighthouseRules() => const AdventureRules(
  stats: [StatRule('insight','Insight', max: 3), StatRule('trust','Trust', max: 3), StatRule('energy','Energy', max: 3, initial: 3)],
  goals: [GoalRule('map','Find the keeper’s map'), GoalRule('signal','Understand the signal'), GoalRule('light','Restore the lighthouse')],
  lore: [LoreRule('world','The sleeping coast','The lighthouse stores the memories of safe journeys.', priority: 1), LoreRule('keeper','Mika’s promise','Mika promised the keeper that nobody would sail into darkness alone.', stat: 'trust', atLeast: 1, priority: 2, scope: 'Companion'), LoreRule('signal','The three-note signal','Three notes reveal the lantern’s tuning sequence.', stat:'insight', atLeast:2, priority:3)],
  endings: [EndingRule('dawn','A light for everyone','The beacon wakes. Ships answer from the horizon. Mika places the keeper’s map in your hands: the next journey is yours.','Learn the signal before restoring the light.', minTurns:2, minimum:{'insight':2}, goals:['map','signal','light']), EndingRule('tomorrow','A promise for tomorrow','You leave a safe signal and guide the waiting boats ashore. The lighthouse sleeps, but nobody is lost tonight. Mika promises to return with you.','A safe retreat is also a choice.', minTurns:2)],
  starts: [StartRule('harbor','At the harbor','{player}, the last lantern is fading. Mika asks you to find the keeper’s map before the tide rises.','harbor'), StartRule('tower','Inside the tower','{player}, you already carry the keeper’s map. Mika points toward a strange three-note signal.','tower', stats:{'insight':1})],
  scenes: [
    SceneRule('harbor','The waiting harbor','assets/art/lantern.png', [ActionRule('search','Search the keeper’s desk','You find the map beneath a weather log. A penciled path leads to the tower.','tower', deltas:{'insight':1}, goals:['map']),ActionRule('listen','Listen to Mika','Mika shares the keeper’s promise and helps you uncover the map. Together, you climb toward the signal.','tower', deltas:{'trust':1,'insight':1},goals:['map'])]),
    SceneRule('tower','The three-note signal','assets/art/signals.png', [ActionRule('study','Study the signal','You match the three notes to the map. The tuning sequence becomes clear.','beacon',deltas:{'insight':1},goals:['map','signal']),ActionRule('shortcut','Take the shortcut','The climb costs energy. At the beacon, the signal is still a mystery.','beacon',deltas:{'energy':-1},goals:['map'])]),
    SceneRule('beacon','The last light','assets/art/lantern.png',[ActionRule('tune','Learn the tuning sequence','You listen carefully and compare the map until the lantern answers.','beacon',deltas:{'insight':1},goals:['signal']),ActionRule('relight','Relight the lighthouse','You tune the lantern. A steady light sweeps across the sea.','beacon',goals:['light'],minimum:{'insight':2},ending:'dawn'),ActionRule('retreat','Leave a signal for tomorrow','You place a safe signal on the shore and guide the boats home.','beacon',ending:'tomorrow')]),
  ]);
