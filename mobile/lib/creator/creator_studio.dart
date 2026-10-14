import 'package:flutter/material.dart';
import '../main.dart' show Artwork, panel, lavender, muted, line;
import '../story_session.dart';
import 'project_library.dart';
import 'rules_editor.dart';
import '../ui_helpers.dart';

class CreatorStudio extends StatefulWidget {
  const CreatorStudio({super.key, required this.library, required this.draft, required this.onPlay});
  final ProjectLibrary library;
  final CreatorDraft draft;
  final Future<void> Function(StorySession) onPlay;
  @override
  State<CreatorStudio> createState() => _CreatorStudioState();
}
class _CreatorStudioState extends State<CreatorStudio> {
  int step = 0;
  final scroll = ScrollController();
  bool saving = false;
  String? error;
  late final title = TextEditingController(text: widget.draft.title);
  late final premise = TextEditingController(text: widget.draft.premise);
  late final world = TextEditingController(text: widget.draft.world);
  late final role = TextEditingController(text: widget.draft.role);
  late final goal = TextEditingController(text: widget.draft.goal);
  late final opening = TextEditingController(text: widget.draft.opening);
  late final companion = TextEditingController(text: widget.draft.character);
  late final creator = TextEditingController(text: widget.draft.creator);
  late final tags = TextEditingController(text: widget.draft.tags.join(', '));
  WorkVisibility visibility = WorkVisibility.private;
  CreatorDraft get d => widget.draft;
  @override
  void dispose() {
    for (final c in [title, premise, world, role, goal, opening, companion, creator, tags]) { c.dispose(); }
    scroll.dispose();
    super.dispose();
  }
  void sync() {
    d.title = title.text; d.premise = premise.text; d.world = world.text;
    d.role = role.text; d.goal = goal.text; d.opening = opening.text;
    d.character = companion.text.trim().isEmpty ? 'Aira' : companion.text.trim(); d.creator = creator.text;
    d.tags = tags.text.split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).take(8).toList();
    widget.library.changed();
    if (mounted) setState(() {});
  }
  void setStep(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { step = value; error = null; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) scroll.jumpTo(scroll.position.minScrollExtent);
    });
  }
  void next() {
    sync();
    final values = step == 0 ? [d.title, d.premise] : [d.world, d.role, d.goal];
    if (values.any((v) => v.trim().isEmpty)) {
      setState(() => error = step == 0 ? 'Add a title and premise to continue.' : 'Add your world, role and goal to continue.');
      return;
    }
    if (step == 1 && opening.text.trim().isEmpty) {
      opening.text = 'In ${d.world.trim()}, you are ${d.role.trim()}. Your goal: ${d.goal.trim()}. '
          '${d.character} arrives with a question. “Where should we begin?”';
      sync();
    }
    setStep(step + 1);
  }
  Future<void> save({bool edition = false}) async {
    if (saving) return;
    sync();
    if (edition && !d.ready) { setState(() => error = 'Complete the story and its opening first.'); return; }
    setState(() => saving = true);
    if (edition) {
      try { await widget.library.publish(d, visibility); }
      catch (e) { if (mounted) setState(() { saving = false; error = e.toString(); }); return; }
    }
    else { await widget.library.flush(); }
    if (!mounted) return;
    if (widget.library.saveError != null) {
      setState(() { saving = false; error = widget.library.saveError; });
      return;
    }
    Navigator.pop(context);
  }
  Widget field(TextEditingController c, String label, String hint, {int lines = 1, int limit = 500}) =>
    Padding(padding: const EdgeInsets.only(bottom: 18), child: TextField(
      controller: c, onChanged: (_) { if (error != null) error = null; sync(); }, minLines: lines, maxLines: lines + 2,
      maxLength: limit, decoration: InputDecoration(labelText: label, hintText: hint)));
  Widget options(String label, List<String> values, String current, void Function(String) select) =>
    Padding(padding: const EdgeInsets.only(bottom: 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: values.map((v) => ChoiceChip(
        label: Text(v), selected: v == current, showCheckmark: false,
        onSelected: (_) { setState(() => select(v)); sync(); })).toList())]));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Creator studio', style: TextStyle(fontSize: 16)),
      actions: [TextButton(onPressed: saving ? null : () => save(), child: const Text('Save draft'))]),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(controller: scroll, padding: const EdgeInsets.all(22), children: [
        SaveIndicator(library: widget.library), const SizedBox(height: 12),
        Text('STEP ${step + 1} OF 3', style: const TextStyle(color: lavender, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(children: [for (var i = 0; i < 3; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == 2 ? 0 : 8), child: Container(height: 4, decoration: BoxDecoration(color: i <= step ? lavender : line, borderRadius: BorderRadius.circular(4)))))]),
        const SizedBox(height: 24),
        Text(['Give it a spark.', 'Build your world.', 'Make the first move.'][step],
          style: const TextStyle(fontFamily: 'Lora', fontSize: 32, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(['An original premise someone will want to step into.',
          'Choose who the player is and what matters to them.',
          'Edit the opening, play it, then save an edition.'][step],
          style: const TextStyle(color: muted, height: 1.5)),
        const SizedBox(height: 24),
        if (step == 0) ...[
          ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 160, child: Artwork(d.art))),
          const SizedBox(height: 18),
          options('Cover artwork', ['Academy', 'Future city', 'Lantern town'],
            d.art.contains('academy') ? 'Academy' : d.art.contains('signals') ? 'Future city' : 'Lantern town',
            (v) => d.art = 'assets/art/${v == 'Academy' ? 'academy' : v == 'Future city' ? 'signals' : 'lantern'}.png'),
          field(title, 'Story title', 'The city above the clouds', limit: 80),
          field(premise, 'Premise', 'A promise, a mystery, a world worth exploring…', lines: 3),
          options('Genre', ['Fantasy', 'Sci-fi', 'Adventure', 'Mystery', 'Romance', 'Horror'], d.genre, (v) => d.genre = v),
          options('Tone', ['Hopeful', 'Mysterious', 'Lighthearted', 'Dramatic'], d.tone, (v) => d.tone = v),
        ],
        if (step == 1) ...[
          field(world, 'World', 'A floating city powered by forgotten memories', lines: 2),
          field(role, 'Player role', 'An investigator looking for their past'),
          field(goal, 'Main goal', 'Find the vanished lighthouse keeper', lines: 2),
          options('Companion', ['Aira', 'Ren', 'Mika'], d.character, (v) { d.character = v; companion.text = v; }),
          field(companion, 'Companion name', 'Name an original companion', limit: 40),
          options('Adventure type', ['Complete adventure', 'Endless world'], d.mode, (v) => d.mode = v),
          const Text('Add adventure rules to make choices playable locally.',
            style: TextStyle(color: muted, fontSize: 12)),
        ],
        if (step == 2) ...[
          field(opening, 'Opening scene', 'Write what the player sees first…', lines: 6, limit: 2000),
          const Text('The suggested opening is a local template. You can rewrite it completely.',
            style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: !d.ready ? null : () async {
            sync();
            if (!d.ready) { setState(() => error = 'Complete the story and opening before preview.'); return; }
            final problems = d.rules?.validate() ?? [];
            if (problems.isNotEmpty) { setState(() => error = problems.first); return; }
            String? start;
            if (d.rules != null) {
              start = await showDialog<String>(context: context, builder: (context) => SimpleDialog(
                title: const Text('Preview a starting scenario'), children: [for (final s in d.rules!.starts)
                  SimpleDialogOption(onPressed: () => Navigator.pop(context, s.id), child: Text(s.name))]));
              if (start == null || !mounted) return;
            }
            final session = StorySession(d.title, d.character, story: d.definition(0), startId: start, playerName: widget.library.playerName, pronouns: widget.library.pronouns, avatar: widget.library.avatar);
            widget.library.addSession(session); await widget.onPlay(session);
          }, icon: const Icon(Icons.play_arrow), label: const Text('Play preview')),
          const SizedBox(height: 26),
          OutlinedButton.icon(onPressed: () async {
            sync();
            final rules = await Navigator.push(context, MaterialPageRoute(builder: (_) => RulesEditor(rules: d.rules)));
            if (rules != null && mounted) setState(() { d.rules = rules; widget.library.changed(); });
          }, icon: const Icon(Icons.account_tree_outlined), label: Text(d.rules == null ? 'Add playable adventure rules' : 'Edit adventure rules')),
          if (d.rules != null) ...[
            Text('${d.rules!.stats.length} stats · ${d.rules!.starts.length} starts · ${d.rules!.endings.length} endings'),
            TextButton(onPressed: () => setState(() { d.rules = null; widget.library.changed(); }), child: const Text('Use opening-only preview')),
          ],
          const SizedBox(height: 18),
          field(creator, 'Creator name', 'Your pen name', limit: 40),
          field(tags, 'Tags', 'Mystery, coastal, choices matter', limit: 240),
          options('Age rating', ['Everyone', 'Teen', 'Mature'], d.ageRating, (v) => d.ageRating = v),
          const Text('Who can discover it?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final v in WorkVisibility.values) ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => setState(() => visibility = v),
            leading: Icon(visibility == v ? Icons.radio_button_checked : Icons.radio_button_off, color: lavender),
            title: Text(v == WorkVisibility.private ? 'Private' : v == WorkVisibility.linkOnly ? 'Link only' : 'Public'),
            subtitle: Text(v == WorkVisibility.private ? 'Keep it in My titles.' :
              v == WorkVisibility.linkOnly ? 'Prepare an unlisted edition. Sharing needs the backend.' :
              'Show it in this device’s local showcase.')),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
            child: const Text('Preview only: no story is uploaded or shared with other users. '
              'Online publishing and content review will be connected through the backend.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5))),
        ],
        if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(error!, style: const TextStyle(color: Colors.orangeAccent))),
        const SizedBox(height: 22),
        Row(children: [
          if (step > 0) TextButton(onPressed: saving ? null : () => setStep(step - 1), child: const Text('Back')),
          const Spacer(),
          FilledButton(onPressed: saving ? null : step < 2 ? next : () => save(edition: true),
            child: Text(saving ? 'Saving…' : step < 2 ? 'Continue' :
              visibility == WorkVisibility.public ? 'Add to local showcase' : 'Save story edition')),
        ]),
        const SizedBox(height: 24),
      ]))),
    ));
}
