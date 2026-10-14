import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart' show Artwork, StoryCover;
import 'story_session.dart';
import 'creator/project_library.dart';

Future<void> storyExport(BuildContext context,ProjectLibrary library,CreatorDraft draft) async {
  String text;
  try { text=library.exportDraft(draft); }
  on FormatException catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message))); return; }
  await showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('Export original story'),
    content:SizedBox(width:600,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Copy this portable story file into a .json document. It includes creator settings and rules, and excludes player profiles, transcripts and private notes.'),const SizedBox(height:16),SelectableText(text,style:const TextStyle(fontSize:11))]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close')),FilledButton(onPressed:()async{await Clipboard.setData(ClipboardData(text:text));if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Original story copied')));},child:const Text('Copy story'))]));
}
Future<void> storyImport(BuildContext context,ProjectLibrary library) async {
  final input=TextEditingController(); String? error;
  await showDialog<void>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setState)=>AlertDialog(title:const Text('Import original story'),
    content:SizedBox(width:600,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('Paste an Animeverse original-story export. Imported stories become a new draft and are never automatically published.'),const SizedBox(height:16),
      TextField(controller:input,minLines:5,maxLines:10,maxLength:150000,decoration:InputDecoration(labelText:'Story JSON',errorText:error))]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){try{library.importDraft(input.text);Navigator.pop(context);}catch(e){setState(()=>error=e is FormatException?e.message:'Invalid story file.');}},child:const Text('Import draft'))])));
  input.dispose();
}
class LibraryHub extends StatefulWidget {
  const LibraryHub({super.key,required this.library,required this.covers,required this.onOpen,required this.onStory,required this.onExplore});
  final ProjectLibrary library;
  final List<StoryCover> covers;
  final Future<void> Function(StorySession) onOpen;
  final Future<void> Function(StoryCover) onStory;
  final VoidCallback onExplore;
  @override
  State<LibraryHub> createState()=>_LibraryHubState();
}
class _LibraryHubState extends State<LibraryHub> {
  String filter='Continue';
  Future<void> rename(StorySession session) async {
    final input=TextEditingController(text:session.displayTitle);
    final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Rename playthrough'),content:TextField(controller:input,maxLength:80,decoration:const InputDecoration(labelText:'Playthrough name')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,input.text),child:const Text('Rename'))]));
    input.dispose();if(value!=null) widget.library.renameSession(session,value);
  }
  @override
  Widget build(BuildContext context) {
    final p=widget.library;
    final sessions=filter=='Archived'?p.sessions.where((s)=>s.archived).toList():p.recent;
    final saved=widget.covers.where((s)=>p.bookmarks.contains(s.definition?.id??s.title)).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Your library',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('Resume a journey, revisit a bookmark, or restore an archived run.'),const SizedBox(height:16),
      Wrap(spacing:8,children:[for(final f in ['Continue','Bookmarks','Archived']) ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f))]),const SizedBox(height:20),
      if(filter=='Bookmarks') ...[
        for(final s in saved) ListTile(leading:const Icon(Icons.bookmark),title:Text(s.title),subtitle:Text(s.genre),onTap:()=>widget.onStory(s)),
        if(saved.isEmpty) const Padding(padding:EdgeInsets.all(20),child:Text('Bookmark a story from its detail page.')),
      ] else ...[
        if(sessions.isEmpty) Padding(padding:const EdgeInsets.all(20),child:Column(children:[Text(filter=='Archived'?'No archived playthroughs.':'Your first chapter is waiting.'),const SizedBox(height:12),FilledButton(onPressed:widget.onExplore,child:const Text('Explore stories'))])),
        for(final s in sessions) Card(child:ListTile(contentPadding:const EdgeInsets.all(12),
          leading:ClipRRect(borderRadius:BorderRadius.circular(8),child:SizedBox(width:54,height:74,child:Artwork(s.story?.art??'assets/art/academy.png'))),
          title:Text(s.displayTitle),subtitle:Text('${s.character} · ${s.activeBranch}\n${s.completed?'Ending reached':'Continue adventure'} · ${DateTime.fromMillisecondsSinceEpoch(s.updatedAt).toLocal().toString().substring(0,16)}'),isThreeLine:true,
          onTap:()=>widget.onOpen(s),trailing:PopupMenuButton<String>(tooltip:'Manage playthrough',onSelected:(v){if(v=='rename')rename(s);else p.archiveSession(s,!s.archived);},itemBuilder:(_)=>[const PopupMenuItem(value:'rename',child:Text('Rename')),PopupMenuItem(value:'archive',child:Text(s.archived?'Restore':'Archive'))]))),
      ],
    ]);
  }
}

class BookmarkControl extends StatelessWidget {
  const BookmarkControl({super.key,required this.library,required this.storyKey});
  final ProjectLibrary library;
  final String storyKey;
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:library,builder:(context,_)=>TextButton.icon(
    onPressed:library.readOnly?null:()=>library.toggleBookmark(storyKey),icon:Icon(library.bookmarks.contains(storyKey)?Icons.bookmark:Icons.bookmark_border),
    label:Text(library.bookmarks.contains(storyKey)?'Bookmarked':'Bookmark story')));
}
