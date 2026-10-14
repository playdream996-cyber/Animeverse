export 'reader.dart' show ChatScreen;
import 'package:flutter/material.dart';
import 'story_session.dart';
import 'reader.dart';
import 'ui_helpers.dart';
import 'authored_story.dart';
import 'player_panels.dart';
import 'library_hub.dart';
import 'demo/temporary_story_catalog.dart';
import 'story_catalog.dart';
import 'creator/project_library.dart';
import 'creator/creator_studio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF0D0E10);
const panel = Color(0xFF191A1E);
const lavender = Color(0xFFD5F76B);
const muted = Color(0xFF92959E);
const line = Color(0xFF2B2D32);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = ProjectLibrary(DeviceProjectStorage(SharedPreferencesAsync()));
  try { await library.load(); }
  catch (_) { library.readOnly = true; library.saveError = 'Saved project could not be loaded. Restart before creating new content.'; }
  runApp(AnimeverseApp(library: library));
}

class AnimeverseApp extends StatelessWidget {
  const AnimeverseApp({super.key, this.library});
  final ProjectLibrary? library;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Animeverse', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true,
      scaffoldBackgroundColor: ink, fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(seedColor: lavender, brightness: Brightness.dark, primary: lavender, onPrimary: ink, surface: panel),
      appBarTheme: const AppBarTheme(backgroundColor: ink, surfaceTintColor: Colors.transparent),
      dividerColor: line,
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: ink, indicatorColor: Color(0xFF2A331B)),
      cardTheme: const CardThemeData(color: panel, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel, contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)))),
    home: LibraryScreen(library: library));
}

class StoryCover {
  const StoryCover(this.title, this.genre, this.description, this.art, this.character, this.tag, {this.definition});
  final StoryDefinition? definition;
  final String title, genre, description, art, character, tag;
}
const covers = [
  StoryCover('The Midnight Academy', 'Fantasy', 'The academy has forgotten you. One girl hasn’t.', 'assets/art/academy.png', 'Aira', 'MYSTERY · MAGIC'),
  StoryCover('Signals from Tomorrow', 'Sci-fi', 'A message from the future. A stranger who knows your name.', 'assets/art/signals.png', 'Ren', 'CYBERPUNK · SUSPENSE'),
  StoryCover('The Last Lantern', 'Adventure', 'Keep the last light alive in a city of sleeping stars.', 'assets/art/lantern.png', 'Mika', 'ADVENTURE · FOUND FAMILY'),
];
StoryCover coverFor(String title) => covers.firstWhere((s) => s.title == title, orElse: () => covers.first);
String artFor(String character) => covers.firstWhere((s) => s.character == character, orElse: () => covers.first).art;

class Artwork extends StatelessWidget {
  const Artwork(this.path, {super.key, this.alignment = Alignment.centerRight});
  final String path;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Image.asset(path, fit: BoxFit.cover, alignment: alignment, width: double.infinity, height: double.infinity,
    cacheWidth: 1000, errorBuilder: (_, error, stack) => const ColoredBox(color: panel, child: Center(child: Icon(Icons.landscape_outlined, color: muted))));
}
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 5, color: muted), SizedBox(width: 6), Flexible(child: Text('Preview · scripted story · local device saves', style: TextStyle(color: muted, fontSize: 10)))]);
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.library});
  final ProjectLibrary? library;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> with WidgetsBindingObserver {
  late final project = widget.library ?? ProjectLibrary(MemoryProjectStorage());
  @override
  void initState() { super.initState(); project.addListener(projectChanged); WidgetsBinding.instance.addObserver(this); WidgetsBinding.instance.addPostFrameCallback((_) async { if (mounted && widget.library != null && project.storage is DeviceProjectStorage && !project.onboardingSeen) { project.onboardingSeen = true; project.changed(); await quickGuide(context); } }); }
  void projectChanged() { if (mounted) setState(() {}); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) project.flush();
  }
  Future<void> editDraft([CreatorDraft? draft]) async {
    if (project.readOnly) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(project.saveError!)));
      return;
    }
    final editing = draft ?? project.newDraft();
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CreatorStudio(
      library: project, draft: editing, onPlay: open)));
    if (mounted) setState(() => tab = 2);
  }
  Future<void> showDetail(StoryCover story) async {
    final begin = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      backgroundColor: ink, builder: (context) => SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 200, child: Artwork(story.art))),
          const SizedBox(height: 20), Text(story.tag, style: const TextStyle(color: lavender, fontSize: 10)),
          const SizedBox(height: 8), Text(story.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), Text(story.description, style: const TextStyle(color: muted, height: 1.6)),
          const SizedBox(height: 18), Text('Companion · ${story.character}'),
          BookmarkControl(library: project, storyKey: story.definition?.id ?? story.title),
          if (story.definition != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('By ${story.definition!.creator} · ${story.definition!.ageRating}\n${story.definition!.tags.join(' · ')}')),

          if (story.definition != null) StoryGuide(story: story.definition!),
          if (story.definition?.foundation == 'Original creator draft') const Padding(
            padding: EdgeInsets.only(top: 12), child: Text('Local creator edition · your playthrough stays separate.',
              style: TextStyle(color: muted, fontSize: 12))),
          const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.play_arrow), label: const Text('Start adventure'))),
        ]))));
    if (begin == true && mounted) await start(story.title, definition: story.definition);
  }
  int tab = 0;
  String genre = 'All';
  final search = TextEditingController();
  List<StorySession> get sessions => project.sessions;
  static const testStoriesEnabled = bool.fromEnvironment('ANIMEVERSE_DEMO_CATALOG', defaultValue: true);
  final temporaryCatalog = TemporaryStoryCatalog();
  bool loadingCatalog = false;
  List<StoryCover> get libraryCovers => [...covers,
    StoryCover(lighthouseStory().title, lighthouseStory().genre, lighthouseStory().description,
      lighthouseStory().art, lighthouseStory().character, lighthouseStory().tag, definition: lighthouseStory()), if (testStoriesEnabled)
    ...temporaryCatalog.stories.map((s) => StoryCover(s.title, s.genre, s.description, s.art, s.character, s.tag, definition: s)),
    ...project.showcase.map((w) => StoryCover(w.story.title, w.story.genre, w.story.description,
      w.story.art, w.story.character, 'LOCAL SHOWCASE · VERSION ${w.version}', definition: w.story))];
  List<StoryCover> get bookmarkCovers {
    final saved = {for (final s in libraryCovers) s.definition?.id ?? s.title: s};
    for (final work in project.editions) {
      final s = work.story;
      saved[s.id] = StoryCover(s.title, s.genre, s.description, s.art, s.character, 'SAVED EDITION · VERSION ${work.version}', definition: s);
    }
    return saved.values.toList();
  }
  Future<void> refreshCatalog() async {
    if (loadingCatalog) return;
    setState(() => loadingCatalog = true);
    await temporaryCatalog.refresh();
    if (mounted) {
      setState(() => loadingCatalog = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        temporaryCatalog.offline ? 'Manga API unavailable · offline test stories kept' : 'Manga references updated · original test stories ready')));
    }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); project.removeListener(projectChanged); project.dispose(); temporaryCatalog.dispose(); search.dispose(); super.dispose(); }
  Future<void> start(String title, {StoryDefinition? definition}) async {
    if (definition?.foundation == 'Original creator draft' || definition?.rules != null) {
      await createSession(title, definition!.character, definition: definition); return;
    }
    final companion = await showModalBottomSheet<String>(context: context, isScrollControlled: true, backgroundColor: ink,
      builder: (context) => SafeArea(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 34, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 24),
        const Text('Every story starts with someone.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 8), const Text('Choose the companion for this chapter.', style: TextStyle(color: muted)), const SizedBox(height: 20),
        for (final c in [('Aira', 'A mage with a promise to keep'), ('Ren', 'A quiet investigator from tomorrow'), ('Mika', 'A traveler who follows the stars')])
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: panel, borderRadius: BorderRadius.circular(14), child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => Navigator.pop(context, c.$1), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 64, height: 72, child: Artwork(artFor(c.$1)))), const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(c.$2, style: const TextStyle(color: muted, fontSize: 12))])), const Icon(Icons.arrow_forward, size: 18, color: lavender),
          ]))))),
        const SizedBox(height: 12), const DemoBadge(),
      ])))));
    if (companion == null || !mounted) return;
    final candidates = temporaryCatalog.stories.where((s) => s.title == title);
    await createSession(title, companion, definition: definition ?? (testStoriesEnabled && candidates.isNotEmpty ? candidates.first : null));
  }
  Future<void> createSession(String title, String companion, {StoryDefinition? definition}) async {
    String? startId;
    if (definition?.rules != null) {
      startId = await showModalBottomSheet<String>(context: context, isScrollControlled: true,
        backgroundColor: ink, builder: (context) => SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Choose your beginning', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12), for (final start in definition!.rules!.starts)
              ListTile(title: Text(start.name), subtitle: Text(start.opening.replaceAll('{player}', project.playerName)),
                trailing: const Icon(Icons.arrow_forward), onTap: () => Navigator.pop(context, start.id)),
          ]))));
      if (startId == null || !mounted) return;
    }
    final session = StorySession(title, companion, story: definition, startId: startId,
      playerName: project.playerName, pronouns: project.pronouns, avatar: project.avatar);
    project.addSession(session); await open(session);
  }
  Future<void> open(StorySession session) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(session: session, library: project)));
    await project.flush();
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = libraryCovers.where((s) => (genre == 'All' || genre == s.genre) && '${s.title} ${s.genre} ${s.description} ${s.character}'.toLowerCase().contains(query)).toList();
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), children: [
      Row(children: [const Icon(Icons.auto_awesome, color: lavender, size: 22), const SizedBox(width: 9), const Text('animeverse', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -1)), const Spacer(), IconButton(tooltip: 'Player settings', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PlayerSettings(library: project))), icon: const Icon(Icons.person_outline)), IconButton(tooltip: 'About this preview', onPressed: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('A new world, in progress'), content: const Text('This is a frontend preview with original artwork and scripted replies. Replies are scripted. Stories and progress save on this device. Online accounts and sharing are not connected.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))])), icon: const Icon(Icons.info_outline, size: 20)), IconButton(tooltip: 'How to play', onPressed: () => quickGuide(context), icon: const Icon(Icons.help_outline, size: 20))]),
      const SizedBox(height: 8), SaveIndicator(library: project),
      const SizedBox(height: 16),
      if (project.saveError != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(project.saveError!, style: const TextStyle(color: Colors.orangeAccent)),
        if (!project.readOnly) TextButton(onPressed: project.flush, child: const Text('Retry save')),
      ]))),
      if (tab == 0) ...[
        const Text('YOUR STORY. YOUR RULES.', style: TextStyle(color: lavender, fontSize: 10, letterSpacing: 2.4, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
        const Text('Your next chapter\nstarts here.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.12, letterSpacing: -.8)), const SizedBox(height: 20),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search stories, worlds, possibilities', prefixIcon: Icon(Icons.search, size: 20), isDense: true)), const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final g in ['All', 'Fantasy', 'Sci-fi', 'Adventure', 'Mystery', 'Romance', 'Horror']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(g), selected: genre == g, showCheckmark: false, onSelected: (_) => setState(() => genre = g), selectedColor: lavender, labelStyle: TextStyle(color: genre == g ? ink : muted, fontSize: 12), side: const BorderSide(color: line)))])),
        const SizedBox(height: 16),
        if (testStoriesEnabled) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          const Expanded(child: Text('5 temporary original adventures', style: TextStyle(color: muted, fontSize: 12))),
          TextButton(onPressed: loadingCatalog ? null : refreshCatalog, child: Text(loadingCatalog ? 'Loading…' : 'Refresh manga references')),
        ])),
        if (visible.isNotEmpty) HeroCover(story: visible.first, onTap: () => showDetail(visible.first)),
        if (visible.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Text('No stories found. Try another title or genre.')),
        const SizedBox(height: 26), const Row(children: [Expanded(child: Text('Find your next obsession', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))), SizedBox(width: 12), Icon(Icons.arrow_forward, size: 18, color: muted)]), const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth > 600 ? 3 : 2;
          final width = (constraints.maxWidth - 12 * (count - 1)) / count;
          return Wrap(spacing: 12, runSpacing: 20, children: [for (final story in visible) SizedBox(width: width, child: PosterCover(story: story, onTap: () => showDetail(story)))]);
        }),
        const SizedBox(height: 28), const DemoBadge(),
      ],
      if (tab == 1) ...[
        LibraryHub(library: project, covers: bookmarkCovers, onOpen: open, onStory: showDetail,
          onExplore: () => setState(() => tab = 0)),
      ],
      if (tab == 2) ...[
        const Text('My titles', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('Your worlds. Your editions. Your next idea.', style: TextStyle(color: muted)),
        const SizedBox(height: 22),
        if (project.drafts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Create your first story in the studio.', style: TextStyle(color: muted))),
        for (final d in project.drafts.reversed.where((d) => !d.archived)) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(tileColor: panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 48, height: 64, child: Artwork(d.art))),
            title: Text(d.title.trim().isEmpty ? 'Untitled draft' : d.title),
            subtitle: const Text('Draft · saved on this device'), trailing: PopupMenuButton<String>(tooltip: 'Manage draft', onSelected: (v) { if (v == 'export') storyExport(context, project, d); else project.archiveDraft(d, true); }, itemBuilder: (_) => const [PopupMenuItem(value: 'export', child: Text('Export original story')), PopupMenuItem(value: 'archive', child: Text('Archive draft'))]),
            onTap: () => editDraft(d))),
        if (project.latest.isNotEmpty) ...[
          const SizedBox(height: 22), const Text('Story editions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final w in project.latest) ListTile(contentPadding: EdgeInsets.zero,
            title: Text(w.draft.title), subtitle: Text('Version ${w.version} · ${w.visibility == WorkVisibility.public ? 'Local showcase' : w.visibility == WorkVisibility.linkOnly ? 'Link only preview' : 'Private'}'),
            trailing: const Icon(Icons.play_circle_outline, color: lavender),
            onTap: () => showDetail(StoryCover(w.story.title, w.story.genre, w.story.description,
              w.story.art, w.story.character, 'BY YOU · VERSION ${w.version}', definition: w.story))),
        ],
        const SizedBox(height: 22), FilledButton.icon(onPressed: () => editDraft(), icon: const Icon(Icons.add), label: const Text('New draft')),
        TextButton.icon(onPressed: project.readOnly ? null : () => storyImport(context, project), icon: const Icon(Icons.file_download_outlined), label: const Text('Import original story')),
        if (project.drafts.any((d) => d.archived)) ExpansionTile(title: const Text('Archived drafts'), children: [
          for (final d in project.drafts.where((d) => d.archived)) ListTile(title: Text(d.title.isEmpty ? 'Untitled draft' : d.title),
            trailing: TextButton(onPressed: () => project.archiveDraft(d, false), child: const Text('Restore'))),
        ]),
      ],
      if (tab == 3) ...[
        const Text('THE CREATOR STUDIO', style: TextStyle(color: lavender, letterSpacing: 2, fontSize: 10)),
        const SizedBox(height: 12), const Text('A world only you\ncould imagine.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15)),
        const SizedBox(height: 12), const Text('Build an original adventure. Shape the cast, the stakes and the first scene.',
          style: TextStyle(color: muted, height: 1.6)),
        const SizedBox(height: 24), ClipRRect(borderRadius: BorderRadius.circular(16),
          child: const SizedBox(height: 200, child: Artwork('assets/art/lantern.png'))),
        const SizedBox(height: 24),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.auto_awesome_outlined, color: lavender),
          title: Text('Define your world'), subtitle: Text('Choose a genre, tone, role and goal.')),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.play_circle_outline, color: lavender),
          title: Text('Preview the opening'), subtitle: Text('Read, edit and play your first scene.')),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.public_outlined, color: lavender),
          title: Text('Prepare your story edition'), subtitle: Text('Private, link only or local showcase.')),
        const SizedBox(height: 20), FilledButton.icon(onPressed: () => editDraft(),
          icon: const Icon(Icons.add), label: const Text('Create story')),
        const SizedBox(height: 20), const Text('Local preview · scripted replies · online publishing pending',
          style: TextStyle(color: muted, fontSize: 11)),
      ],
    ])))), bottomNavigationBar: DecoratedBox(decoration: const BoxDecoration(border: Border(top: BorderSide(color: line))), child: NavigationBar(height: 68, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'), NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'My stories'), NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: 'My titles'), NavigationDestination(icon: Icon(Icons.edit_square), label: 'Create')])));
  }
}

class HeroCover extends StatelessWidget {
  const HeroCover({super.key, required this.story, required this.onTap});
  final StoryCover story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: 'Begin ${story.title}', child: Material(borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: SizedBox(height: 300, child: Stack(fit: StackFit.expand, children: [Artwork(story.art), const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, .45, 1], colors: [Colors.transparent, Color(0x33000000), Color(0xF20D0E10)]))),
    Positioned(top: 16, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(6)), child: const Text('FEATURED WORLD', style: TextStyle(color: ink, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800)))),
    Positioned(bottom: 18, left: 18, right: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(story.tag, style: const TextStyle(color: lavender, fontSize: 9, letterSpacing: 1.4)), const SizedBox(height: 7), Text(story.title, style: const TextStyle(fontSize: 25, height: 1.1, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(story.description, style: const TextStyle(color: Color(0xFFCBD0D6), fontSize: 12)), const SizedBox(height: 15), const Row(children: [Text('Enter this world', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 17, color: lavender)])])),
  ])))));
}
class PosterCover extends StatelessWidget {
  const PosterCover({super.key, required this.story, required this.onTap});
  final StoryCover story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AspectRatio(aspectRatio: .78, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Artwork(story.art))), const SizedBox(height: 10),
    Text(story.genre.toUpperCase(), style: const TextStyle(color: lavender, fontSize: 9, letterSpacing: 1.2)), const SizedBox(height: 5), Text(story.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25)), const SizedBox(height: 5), Text(story.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11, height: 1.4)),
  ]));
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
    const Text('THE CREATOR STUDIO', style: TextStyle(color: lavender, letterSpacing: 2, fontSize: 10)), const SizedBox(height: 10), const Text('A world only you\ncould imagine.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15)), const SizedBox(height: 12), const Text('Give your next adventure a name. Then find the person who will share it.', style: TextStyle(color: muted, height: 1.5)), const SizedBox(height: 24),
    ClipRRect(borderRadius: BorderRadius.circular(14), child: const SizedBox(height: 160, width: double.infinity, child: Artwork('assets/art/lantern.png'))), const SizedBox(height: 24),
    const Text('01 / STORY PROFILE', style: TextStyle(color: lavender, fontSize: 10, letterSpacing: 1.5)), const SizedBox(height: 14),
    TextField(controller: title, maxLength: 80, decoration: InputDecoration(labelText: 'Story title', hintText: 'The city above the clouds', errorText: error)), const SizedBox(height: 16),
    const Text('Preview creation uses a prepared opening. Custom world generation will be available when the backend is connected.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)), const SizedBox(height: 24),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { if (title.text.trim().isEmpty) { setState(() => error = 'Give your story a name'); return; } setState(() => error = null); widget.onCreate(title.text.trim()); }, icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Choose companion'))), const SizedBox(height: 20), const DemoBadge(),
  ]);
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
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom), child: SizedBox(height: (MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom - 100).clamp(100.0, MediaQuery.sizeOf(context).height * .65), child: ListView(children: [
    const Text('Your story remembers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Manual demo notes. AI memory is not connected.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 20),
    TextField(controller: summary, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Story summary')),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () { widget.session.updateSummary(summary.text); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary updated for this timeline'))); }, child: const Text('Save summary'))),
    const Text('Pinned facts', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    for (final fact in List<String>.of(widget.session.memories)) ListTile(contentPadding: EdgeInsets.zero, title: Text(fact), trailing: IconButton(tooltip: 'Remove memory', icon: const Icon(Icons.close), onPressed: () => setState(() => widget.session.removeMemory(fact)))),
    TextField(controller: memory, maxLength: 250, decoration: const InputDecoration(hintText: 'Add a fact to remember')),
    FilledButton(onPressed: () { setState(() => widget.session.addMemory(memory.text)); memory.clear(); }, child: const Text('Pin memory')),
  ]))));
}

class ReplyCursor extends StatefulWidget {
  const ReplyCursor({super.key});
  @override
  State<ReplyCursor> createState() => _ReplyCursorState();
}
class _ReplyCursorState extends State<ReplyCursor> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: controller,
    child: const Padding(padding: EdgeInsets.only(bottom: 12),
      child: Text('▍', style: TextStyle(color: lavender))));
}

/// Creator-authored guidance belongs to the edition, not private player notes.
class StoryGuide extends StatelessWidget {
  const StoryGuide({super.key, required this.story});
  final StoryDefinition story;
  @override
  Widget build(BuildContext context) {
    if (story.playerRole.isEmpty && story.goal.isEmpty && story.world.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 12), child: Card(color: panel, margin: EdgeInsets.zero,
      child: ExpansionTile(title: const Text('Your adventure guide', style: TextStyle(fontSize: 14)),
        subtitle: Text(story.goal, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final entry in {'Your role': story.playerRole, 'Your goal': story.goal, 'World': story.world, 'Adventure type': story.mode}.entries)
            if (entry.value.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${entry.key} · ${entry.value}', style: const TextStyle(height: 1.5))),
          Text(story.rules == null ? 'This opening-only preview has scripted replies and no ending rules.' : 'This authored adventure has local rules. Choose suggested actions to change stats and reach endings.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        ])));
  }
}
