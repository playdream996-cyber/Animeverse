import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../story_catalog.dart';
import '../adventure_rules.dart';
import '../story_session.dart';

abstract interface class ProjectStorage {
  Future<String?> read();
  Future<void> write(String value);
}
class MemoryProjectStorage implements ProjectStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async { this.value = value; }
}
class DeviceProjectStorage implements ProjectStorage {
  DeviceProjectStorage(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'animeverse_project_v1';
  @override
  Future<String?> read() => preferences.getString(key);
  @override
  Future<void> write(String value) async {
    await preferences.setString(key, value);
  }
}

enum SavePhase { saved, pending, saving, failed, readOnly }

enum WorkVisibility { private, linkOnly, public }
class CreatorDraft {
  CreatorDraft({required this.id, this.title = '', this.premise = '', this.world = '',
    this.role = '', this.goal = '', this.opening = '', this.genre = 'Fantasy',
    this.tone = 'Hopeful', this.character = 'Aira', this.mode = 'Complete adventure',
    this.art = 'assets/art/academy.png', this.rules, this.creator = 'You',
    this.ageRating = 'Everyone', this.tags = const []});
  final String id;
  AdventureRules? rules;
  String creator, ageRating;
  List<String> tags;
  bool archived = false;
  String title, premise, world, role, goal, opening, genre, tone, character, mode, art;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'premise': premise,
    'world': world, 'role': role, 'goal': goal, 'opening': opening, 'genre': genre,
    'tone': tone, 'character': character, 'mode': mode, 'art': art, 'rules': rules?.toJson(),
    'creator': creator, 'ageRating': ageRating, 'tags': tags, 'archived': archived};
  factory CreatorDraft.fromJson(Map<String, dynamic> j) => CreatorDraft(
    id: j['id'] as String, title: j['title'] as String, premise: j['premise'] as String,
    world: j['world'] as String, role: j['role'] as String, goal: j['goal'] as String,
    opening: j['opening'] as String, genre: j['genre'] as String, tone: j['tone'] as String,
    character: j['character'] as String, mode: j['mode'] as String, art: j['art'] as String,
    rules: j['rules'] == null ? null : AdventureRules.fromJson(object(j['rules'])),
    creator: j['creator'] as String? ?? 'You', ageRating: j['ageRating'] as String? ?? 'Everyone', tags: strings(j['tags']))..archived = j['archived'] == true;
  CreatorDraft copy() => CreatorDraft.fromJson(toJson());
  bool get ready => [title, premise, world, role, goal, opening].every((s) => s.trim().isNotEmpty);
  StoryDefinition definition(int version) {
    if (!ready) throw StateError('Complete your story before making a preview');
    return StoryDefinition(id: '$id@$version', title: title.trim(), genre: genre,
      description: premise.trim(), art: art, character: character, tag: 'BY YOU · $tone',
      opening: opening.trim(), choices: ['Investigate the scene', 'Ask $character for help', 'Follow your goal'],
      responses: [
        'You examine your surroundings in ${world.trim()}. $character notices a detail that could help with ${goal.trim()}. Which clue will you follow?',
        '$character listens. “We should decide our next step together.” Your objective remains: ${goal.trim()}.',
        'As ${role.trim()}, you take a first step toward ${goal.trim()}. $character waits for your direction.'],
      foundation: 'Original creator draft', sourceUrl: '', world: world.trim(),
      playerRole: role.trim(), goal: goal.trim(), mode: mode, rules: rules == null ? null : AdventureRules.fromJson(rules!.toJson()), creator: creator.trim(), ageRating: ageRating, tags: List.of(tags));
  }
}
class PublishedWork {
  PublishedWork(CreatorDraft draft, this.version, this.visibility) : _draft = draft.copy();
  final CreatorDraft _draft;
  CreatorDraft get draft => _draft.copy();
  final int version;
  final WorkVisibility visibility;
  StoryDefinition get story => _draft.definition(version);
  Map<String, dynamic> toJson() => {'draft': draft.toJson(), 'version': version, 'visibility': visibility.name};
  factory PublishedWork.fromJson(Map<String, dynamic> j) => PublishedWork(
    CreatorDraft.fromJson(Map<String, dynamic>.from(j['draft'] as Map)), j['version'] as int,
    WorkVisibility.values.byName(j['visibility'] as String));
}

/// Local preview adapter. Visibility here is not online authorization.
class ProjectLibrary extends ChangeNotifier {
  ProjectLibrary(this.storage);
  final ProjectStorage storage;
  final List<CreatorDraft> drafts = [];
  final List<PublishedWork> editions = [];
  final List<StorySession> sessions = [];
  String playerName = 'You', pronouns = 'they/them', avatar = 'Star';
  double readingSize = 17;
  final Set<String> bookmarks = {};
  List<StorySession> get recent => sessions.where((s) => !s.archived).toList()..sort((a,b) => b.updatedAt.compareTo(a.updatedAt));
  String? saveError;
  bool readOnly = false;
  Timer? _saveTimer;
  final ValueNotifier<SavePhase> savePhase = ValueNotifier(SavePhase.saved);
  int _revision = 0, _savedRevision = 0;
  Future<void>? _activeSave;
  bool _isSaving = false;
  bool onboardingSeen = false;
  bool _disposed = false;
  int _counter = 0;
  List<PublishedWork> get latest {
    final works = <String, PublishedWork>{};
    for (final edition in editions) { works[edition.draft.id] = edition; }
    return works.values.toList().reversed.toList();
  }
  List<PublishedWork> get showcase => latest.where((w) => w.visibility == WorkVisibility.public).toList();
  Future<void> load() async {
    final raw = await storage.read();
    if (raw == null) return;
    final j = raw.length > 65536 ? await compute(_decodeProject, raw) : _decodeProject(raw);
    onboardingSeen = j['onboardingSeen'] == true;
    if (j['schema'] != 1) throw const FormatException('Unsupported saved project');
    final profile = j['profile'] is Map ? object(j['profile']) : <String,dynamic>{};
    playerName = profile['name'] as String? ?? 'You'; pronouns = profile['pronouns'] as String? ?? 'they/them'; avatar = profile['avatar'] as String? ?? 'Star';
    readingSize = (profile['readingSize'] as num? ?? 17).toDouble().clamp(17, 23);
    bookmarks.addAll(strings(j['bookmarks']));
    drafts.addAll((j['drafts'] as List).map((x) => CreatorDraft.fromJson(Map<String, dynamic>.from(x as Map))));
    editions.addAll((j['editions'] as List).map((x) => PublishedWork.fromJson(Map<String, dynamic>.from(x as Map))));
    for (final value in j['sessions'] as List) {
      final s = StorySession.fromJson(Map<String, dynamic>.from(value as Map));
      sessions.add(s); s.addListener(_sessionChanged);
    }
  }
  CreatorDraft newDraft() {
    final draft = CreatorDraft(id: '${DateTime.now().microsecondsSinceEpoch}-${_counter++}');
    drafts.add(draft); changed(); return draft;
  }
  void changed() { _revision++; _scheduleSave(); if (!_disposed) notifyListeners(); }
  void _sessionChanged() { _revision++; _scheduleSave(); }
  void _scheduleSave() {
    if (_disposed) return;
    _saveTimer?.cancel();
    savePhase.value = readOnly ? SavePhase.readOnly : SavePhase.pending;
    _saveTimer = Timer(const Duration(milliseconds: 350), () { flush(); });
  }
  Future<void> flush() {
    if (readOnly || _disposed) return Future<void>.value();
    _saveTimer?.cancel();
    if (_isSaving) return _activeSave!;
    final done = Completer<void>();
    _activeSave = done.future; _isSaving = true;
    _saveLatest().then((_) { _isSaving = false; done.complete(); }, onError: (Object e, StackTrace stack) { _isSaving = false; done.completeError(e, stack); });
    return done.future;
  }
  Map<String,dynamic> _snapshot() => {'schema': 1, 'onboardingSeen': onboardingSeen,
    'drafts': drafts.map((d)=>d.toJson()).toList(), 'editions': editions.map((w)=>w.toJson()).toList(),
    'sessions': sessions.map((s)=>s.toJson()).toList(), 'bookmarks': bookmarks.toList(),
    'profile': {'name':playerName,'pronouns':pronouns,'avatar':avatar,'readingSize':readingSize}};
  Future<void> _saveLatest() async {
    do {
      final revision = _revision;
      if (!_disposed) savePhase.value = SavePhase.saving;
      try {
        // Encoding runs off the UI isolate on native Flutter. One write at a
        // time; edits during a write coalesce into the next newest snapshot.
        final snapshot = _snapshot();
        final large = drafts.length + editions.length > 20 || sessions.fold<int>(0,(count,s)=>count+s.branches.values.fold<int>(0,(n,t)=>n+t.length)) > 200;
        final payload = large ? await compute(_encodeProject, snapshot) : _encodeProject(snapshot);
        await storage.write(payload); saveError = null; _savedRevision = revision;
      } catch (_) {
        saveError = 'Changes could not be saved on this device. Try again.';
        if (!_disposed) { savePhase.value = SavePhase.failed; notifyListeners(); }
        return;
      }
    } while (!_disposed && _savedRevision != _revision);
    if (!_disposed) { savePhase.value = SavePhase.saved; notifyListeners(); }
  }
  Future<PublishedWork> publish(CreatorDraft draft, WorkVisibility visibility) async {
    if (!draft.ready) throw StateError('Complete the story first');
    final errors = draft.rules?.validate() ?? [];
    if (errors.isNotEmpty) throw FormatException(errors.first);
    exportDraft(draft); // Ensure a saved edition fits the portable format limits.
    final version = editions.where((w) => w.draft.id == draft.id).length + 1;
    final work = PublishedWork(draft.copy(), version, visibility);
    editions.add(work);
    changed(); await flush(); return work;
  }
  void toggleBookmark(String key) { if (!bookmarks.add(key)) bookmarks.remove(key); changed(); }
  void archiveSession(StorySession session, bool value) { session.archived = value; changed(); }
  void renameSession(StorySession session, String value) { session.label = value.trim(); changed(); }
  void archiveDraft(CreatorDraft draft, bool value) { draft.archived = value; changed(); }
  String exportDraft(CreatorDraft draft) {
    final result = const JsonEncoder.withIndent('  ').convert({
      'format': 'animeverse-original-story', 'version': 1, 'draft': draft.toJson()..remove('archived')});
    if (result.length > 150000) throw const FormatException('Shorten the story or its authored replies before export or publication. The portable format supports 150,000 characters.');
    return result;
  }
  CreatorDraft importDraft(String raw) {
    if (raw.length > 150000) throw const FormatException('Story text is too large.');
    try {
      final envelope = object(jsonDecode(raw));
      if (envelope['format'] != 'animeverse-original-story' || envelope['version'] != 1 || envelope.keys.any((k) => !['format','version','draft'].contains(k))) {
        throw const FormatException('Use an Animeverse original-story export, version 1.');
      }
      final data = object(envelope['draft']);
      const allowed = ['id','title','premise','world','role','goal','opening','genre','tone','character','mode','art','rules','creator','ageRating','tags'];
      if(data.keys.any((k) => !allowed.contains(k))) throw const FormatException('Story exports cannot contain private playthrough or profile data.');
      data['id'] = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
      final draft = CreatorDraft.fromJson(data);
      if(!storyArt.contains(draft.art) || !['Complete adventure','Endless world'].contains(draft.mode) ||
        !['Everyone','Teen','Mature'].contains(draft.ageRating) || draft.tags.length > 8 || draft.tags.any((t)=>t.length>30) ||
        [draft.title,draft.premise,draft.world,draft.role,draft.goal,draft.opening,draft.character,draft.creator].any((t)=>t.length>4000)) {
        throw const FormatException('Story contains unsupported artwork, settings or oversized fields.');
      }
      final errors = draft.rules?.validate() ?? [];
      if(errors.isNotEmpty) throw FormatException(errors.first);
      drafts.add(draft); changed(); return draft;
    } on FormatException { rethrow; }
      catch (_) { throw const FormatException('Invalid story file. Nothing was imported.'); }
  }
  void addSession(StorySession session) {
    sessions.add(session); session.addListener(_sessionChanged); changed();
    flush();
  }
  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    for (final s in sessions) { s.removeListener(_sessionChanged); s.dispose(); }
    savePhase.dispose();
    super.dispose();
  }
}

String _encodeProject(Map<String,dynamic> snapshot) => jsonEncode(snapshot);
Map<String,dynamic> _decodeProject(String raw) => object(jsonDecode(raw));
