import 'package:flutter/material.dart';
import '../main.dart' show Artwork, panel, lavender, muted, line;
import '../story_session.dart';
import 'project_library.dart';

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
  WorkVisibility visibility = WorkVisibility.private;
  CreatorDraft get d => widget.draft;
  @override
  void dispose() {
    for (final c in [title, premise, world, role, goal, opening]) { c.dispose(); }
    scroll.dispose();
    super.dispose();
  }
  void sync() {
    d.title = title.text; d.premise = premise.text; d.world = world.text;
    d.role = role.text; d.goal = goal.text; d.opening = opening.text;
    widget.library.changed();
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
    sync();
    if (edition && !d.ready) { setState(() => error = 'Complete the story and its opening first.'); return; }
    setState(() => saving = true);
    if (edition) { await widget.library.publish(d, visibility); }
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
      controller: c, onChanged: (_) => sync(), minLines: lines, maxLines: lines + 2,
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
        Text('STEP ${step + 1} OF 3', style: const TextStyle(color: lavender, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: (step + 1) / 3, color: lavender, backgroundColor: line),
        const SizedBox(height: 24),
        Text(['Give it a spark.', 'Build your world.', 'Make the first move.'][step],
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
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
          options('Companion', ['Aira', 'Ren', 'Mika'], d.character, (v) => d.character = v),
          options('Adventure type', ['Complete adventure', 'Endless world'], d.mode, (v) => d.mode = v),
          const Text('These settings will guide the AI when the backend is connected.',
            style: TextStyle(color: muted, fontSize: 12)),
        ],
        if (step == 2) ...[
          field(opening, 'Opening scene', 'Write what the player sees first…', lines: 6, limit: 2000),
          const Text('The suggested opening is a local template. You can rewrite it completely.',
            style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: !d.ready ? null : () async {
            sync();
            final session = StorySession(d.title, d.character, story: d.definition(0));
            widget.library.addSession(session); await widget.onPlay(session);
          }, icon: const Icon(Icons.play_arrow), label: const Text('Play preview')),
          const SizedBox(height: 26),
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
