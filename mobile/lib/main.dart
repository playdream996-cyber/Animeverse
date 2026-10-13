import 'package:flutter/material.dart';
import 'story_session.dart';

const ink = Color(0xFF121320);
const panel = Color(0xFF1D2032);
const lavender = Color(0xFFB8A6FF);

void main() => runApp(const AnimeverseApp());

class AnimeverseApp extends StatelessWidget {
  const AnimeverseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Animeverse', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: lavender, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(backgroundColor: ink, surfaceTintColor: Colors.transparent),
      cardTheme: const CardThemeData(color: panel, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
    home: const LibraryScreen());
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> {
  int tab = 0;
  String genre = 'All';
  final search = TextEditingController();
  final List<StorySession> sessions = [];
  @override
  void dispose() { search.dispose(); for (final s in sessions) { s.dispose(); } super.dispose(); }
  Future<void> start(String title) async {
    final character = await showModalBottomSheet<String>(context: context, isScrollControlled: true,
      builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choose your companion', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('A new face. A story only you can tell.'), const SizedBox(height: 20),
        for (final c in [('Aira', 'Curious mage · fiercely loyal', Icons.auto_awesome), ('Ren', 'Reserved knight · a hidden past', Icons.shield_outlined), ('Mika', 'Inventor · chaos with a kind heart', Icons.bolt)])
          ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: lavender.withValues(alpha: .15), child: Icon(c.$3, color: lavender)),
            title: Text(c.$1), subtitle: Text(c.$2), trailing: const Icon(Icons.arrow_forward), onTap: () => Navigator.pop(context, c.$1)),
        const SizedBox(height: 12), const Text('Demo companions · original placeholder designs', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ]))));
    if (character == null || !mounted) return;
    final session = StorySession(title, character);
    setState(() => sessions.add(session));
    await open(session);
  }
  Future<void> open(StorySession session) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(session: session)));
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final stories = [('The Midnight Academy', 'Fantasy', 'A forgotten promise. A door that opens only for you.', Icons.nightlight_round),
      ('Signals from Tomorrow', 'Sci-fi', 'Someone in the future knows your name.', Icons.satellite_alt),
      ('The Last Lantern', 'Adventure', 'One light remains in a city of sleeping stars.', Icons.flare)];
    final visible = stories.where((s) => (genre == 'All' || genre == s.$2) && s.$1.toLowerCase().contains(query));
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [const Icon(Icons.auto_awesome, color: lavender), const SizedBox(width: 10), const Text('ANIMEVERSE', style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)), const Spacer(), IconButton(tooltip: 'About this demo', onPressed: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Your story starts here'), content: const Text('Frontend prototype. Replies are scripted; no AI or cloud service is connected. Sessions and memories reset when the app closes.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))])), icon: const Icon(Icons.info_outline))]),
      const SizedBox(height: 28), Text(tab == 0 ? 'Step into another life.' : tab == 1 ? 'Your stories.' : 'Make a world your own.', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15)),
      const SizedBox(height: 12), Text(tab == 0 ? 'You are the main character. Where will you go?' : tab == 1 ? 'Pick up where your imagination left off.' : 'Start with an idea. Choose your companion.', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 20), const DemoBadge(), const SizedBox(height: 24),
      if (tab == 0) ...[
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Find your next adventure', prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 14), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final g in ['All', 'Fantasy', 'Sci-fi', 'Adventure']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(g), selected: genre == g, onSelected: (_) => setState(() => genre = g)))])),
        const SizedBox(height: 20),
        for (final story in visible) Padding(padding: const EdgeInsets.only(bottom: 18), child: StoryCard(title: story.$1, genre: story.$2, description: story.$3, icon: story.$4, onTap: () => start(story.$1))),
        if (visible.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No stories found. Try another title or genre.')),
      ],
      if (tab == 1) ...[
        if (sessions.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('Your first adventure is waiting in Discover.')),
        for (final s in sessions) Card(child: ListTile(leading: const Icon(Icons.bookmark_outline, color: lavender), title: Text(s.title), subtitle: Text('${s.character} · ${s.activeBranch} · ${s.turns.length} messages'), trailing: const Icon(Icons.arrow_forward), onTap: () => open(s))),
      ],
      if (tab == 2) CreateStoryForm(onCreate: start),
      const SizedBox(height: 20), const Text('Original worlds. Endless possibilities.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
    ])))), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'), NavigationDestination(icon: Icon(Icons.auto_stories_outlined), label: 'My stories'), NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Create')]));
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) => const Row(children: [Icon(Icons.science_outlined, size: 16, color: lavender), SizedBox(width: 6), Flexible(child: Text('Demo mode · scripted replies · session-only saves', style: TextStyle(color: lavender, fontSize: 12)))]);
}
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.title, required this.genre, required this.description, required this.icon, required this.onTap});
  final String title, genre, description;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(height: 170, width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF353367), Color(0xFF171D35)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Stack(children: [Positioned(right: 24, top: 14, child: Icon(icon, size: 130, color: lavender.withValues(alpha: .45))), Positioned(left: 20, bottom: 20, child: Chip(label: Text(genre), backgroundColor: ink))])),
    Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(description, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 16), const Row(children: [Text('Begin your story', style: TextStyle(color: lavender, fontWeight: FontWeight.w700)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18, color: lavender)])])),
  ])));
}
class CreateStoryForm extends StatefulWidget {
  const CreateStoryForm({super.key, required this.onCreate});
  final Future<void> Function(String) onCreate;
  @override
  State<CreateStoryForm> createState() => _CreateStoryFormState();
}
class _CreateStoryFormState extends State<CreateStoryForm> {
  final title = TextEditingController();
  String? error;
  @override
  void dispose() { title.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.draw_outlined, size: 70, color: lavender), const SizedBox(height: 24),
    TextField(controller: title, maxLength: 80, decoration: InputDecoration(labelText: 'Story title', hintText: 'The city above the clouds', errorText: error)), const SizedBox(height: 16),
    const Text('This prototype uses the academy opening for every title. Custom world generation will be connected later.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 24),
    FilledButton.icon(onPressed: () { if (title.text.trim().isEmpty) { setState(() => error = 'Give your story a name'); return; } setState(() => error = null); widget.onCreate(title.text.trim()); }, icon: const Icon(Icons.auto_awesome), label: const Text('Choose companion')),
  ]);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.session});
  final StorySession session;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void initState() { super.initState(); widget.session.addListener(refresh); }
  void refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { widget.session.removeListener(refresh); input.dispose(); scroll.dispose(); super.dispose(); }
  void send([String? choice]) {
    widget.session.send(choice ?? input.text); input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); });
  }
  Future<void> memories() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => MemorySheet(session: widget.session));
  }
  Future<void> branches() async {
    await showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Story branches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 12), for (final name in widget.session.branches.keys) ListTile(title: Text(name), trailing: name == widget.session.activeBranch ? const Icon(Icons.check, color: lavender) : null, onTap: () { widget.session.selectBranch(name); Navigator.pop(context); }), FilledButton.icon(onPressed: () { widget.session.fork(); Navigator.pop(context); }, icon: const Icon(Icons.call_split), label: const Text('Branch from here'))]))));
  }
  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(appBar: AppBar(title: Text(s.title, style: const TextStyle(fontSize: 16)), actions: [IconButton(tooltip: 'Memories', onPressed: memories, icon: const Icon(Icons.psychology_outlined)), IconButton(tooltip: 'Branches', onPressed: branches, icon: const Icon(Icons.call_split))]), body: SafeArea(top: false, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Column(children: [const DemoBadge(), const SizedBox(height: 8), Row(children: [const Icon(Icons.circle, size: 7, color: lavender), const SizedBox(width: 6), Text('${s.character} · ${s.activeBranch}', style: const TextStyle(color: Colors.white60, fontSize: 12))])])),
      Expanded(child: ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [for (final turn in s.turns) Align(alignment: turn.speaker == 'You' ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18), constraints: const BoxConstraints(maxWidth: 540), decoration: BoxDecoration(color: turn.speaker == 'You' ? const Color(0xFF353052) : panel, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(turn.speaker, style: const TextStyle(color: lavender, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Text(turn.text, style: const TextStyle(fontSize: 16, height: 1.5))]))),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final choice in ['Examine the key', 'Can I trust you?', 'Follow the chime']) ActionChip(label: Text(choice), onPressed: () => send(choice))]),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4, maxLength: 2000, decoration: const InputDecoration(hintText: 'What do you do next?', counterText: ''), onSubmitted: (_) => send())), const SizedBox(width: 8), IconButton.filled(tooltip: 'Send action', onPressed: send, icon: const Icon(Icons.arrow_upward))])),
    ])))));
  }
}

class MemorySheet extends StatefulWidget {
  const MemorySheet({super.key, required this.session});
  final StorySession session;
  @override
  State<MemorySheet> createState() => _MemorySheetState();
}
class _MemorySheetState extends State<MemorySheet> {
  late final summary = TextEditingController(text: widget.session.summary);
  final memory = TextEditingController();
  @override
  void dispose() { summary.dispose(); memory.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom), child: SizedBox(height: MediaQuery.sizeOf(context).height * .65, child: ListView(children: [
    const Text('Your story remembers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Manual demo notes. AI memory is not connected.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 20),
    TextField(controller: summary, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Story summary')),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () { widget.session.updateSummary(summary.text); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary saved for this session'))); }, child: const Text('Save summary'))),
    const Text('Pinned facts', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    for (final fact in List<String>.of(widget.session.memories)) ListTile(contentPadding: EdgeInsets.zero, title: Text(fact), trailing: IconButton(tooltip: 'Remove memory', icon: const Icon(Icons.close), onPressed: () => setState(() => widget.session.removeMemory(fact)))),
    TextField(controller: memory, maxLength: 250, decoration: const InputDecoration(hintText: 'Add a fact to remember')),
    FilledButton(onPressed: () { setState(() => widget.session.addMemory(memory.text)); memory.clear(); }, child: const Text('Pin memory')),
  ]))));
}
