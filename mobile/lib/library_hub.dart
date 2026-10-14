import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart' show Artwork, StoryCover, muted;
import 'story_session.dart';
import 'creator/project_library.dart';
import 'story_files.dart';

Future<void> storyExport(BuildContext context,ProjectLibrary library,CreatorDraft draft,{StoryFileGateway? files}) async {
  String text;
  try { text=library.exportDraft(draft); }
  on FormatException catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));return;}
  await showDialog<void>(context:context,builder:(_)=>_ExportDialog(text:text,name:storyFilename(draft.title),files:files??NativeStoryFiles()));
}
class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.text,required this.name,required this.files});
  final String text,name;final StoryFileGateway files;
  @override State<_ExportDialog> createState()=>_ExportDialogState();
}
class _ExportDialogState extends State<_ExportDialog>{
  bool busy=false;String? message;
  Future<void> run(String action)async{
    if(busy)return;setState(()=>busy=true);
    try{
      if(action=='copy'){await Clipboard.setData(ClipboardData(text:widget.text));if(mounted)setState(()=>message='Story copied.');}
      if(action=='save'){final saved=await widget.files.save(widget.text,widget.name);if(mounted)setState(()=>message=saved?'Story file saved.':'Save canceled.');}
      if(action=='share'){
        final box=context.findRenderObject();final origin=box is RenderBox&&box.hasSize?box.localToGlobal(Offset.zero)&box.size:const Rect.fromLTWH(0,0,1,1);
        await widget.files.share(widget.text,widget.name,origin);if(mounted)setState(()=>message='Share sheet closed.');
      }
    }catch(_){if(mounted)setState(()=>message='Could not complete this action. Try again or copy the story text.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Export original story'),content:SizedBox(width:600,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(widget.name),const SizedBox(height:12),const Text('Includes creator settings and rules. Excludes player profiles, transcripts and private notes.'),const SizedBox(height:16),
    Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:busy?null:()=>run('save'),icon:const Icon(Icons.save_alt),label:const Text('Save file')),OutlinedButton.icon(onPressed:busy?null:()=>run('share'),icon:const Icon(Icons.share_outlined),label:const Text('Share file')),TextButton(onPressed:busy?null:()=>run('copy'),child:const Text('Copy text'))]),
    if(busy)const Padding(padding:EdgeInsets.only(top:16),child:LinearProgressIndicator()),if(message!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(message!)),
  ])),actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Close'))]);
}
Future<void> storyImport(BuildContext context,ProjectLibrary library,{StoryFileGateway? files}) async {
  await showDialog<void>(context:context,builder:(_)=>_ImportDialog(library:library,files:files??NativeStoryFiles()));
}
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.library,required this.files});final ProjectLibrary library;final StoryFileGateway files;
  @override State<_ImportDialog> createState()=>_ImportDialogState();
}
class _ImportDialogState extends State<_ImportDialog>{
  final input=TextEditingController();bool busy=false,paste=false;String? error;
  @override void dispose(){input.dispose();super.dispose();}
  void importStory(String raw){try{widget.library.importDraft(raw);Navigator.pop(context);}catch(e){setState(()=>error=e is FormatException?e.message:'Invalid story file. Nothing was imported.');}}
  Future<void> pick()async{if(busy)return;setState(()=>busy=true);try{final raw=await widget.files.pick();if(mounted&&raw!=null)importStory(raw);}catch(e){if(mounted)setState(()=>error=e is FormatException?e.message:'File could not be read. Try again or paste story text.');}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Import original story'),content:SizedBox(width:600,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Text('Choose an Animeverse .json story file. It becomes a new unpublished draft.'),const SizedBox(height:16),FilledButton.icon(onPressed:busy?null:pick,icon:const Icon(Icons.folder_open),label:const Text('Choose story file')),
    TextButton(onPressed:busy?null:()=>setState(()=>paste=!paste),child:const Text('Paste story text instead')),
    if(paste)TextField(controller:input,minLines:4,maxLines:8,maxLength:150000,decoration:const InputDecoration(labelText:'Story JSON')),
    if(busy)const LinearProgressIndicator(),if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
  ]))),actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Cancel')),if(paste)FilledButton(onPressed:busy?null:()=>importStory(input.text),child:const Text('Import draft'))]);
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
  String filter='Continue', query='', sort='Recent';
  Future<void> rename(StorySession session) async {
    final input=TextEditingController(text:session.displayTitle);
    final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Rename playthrough'),content:TextField(controller:input,maxLength:80,decoration:const InputDecoration(labelText:'Playthrough name')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,input.text),child:const Text('Rename'))]));
    input.dispose();if(value!=null) widget.library.renameSession(session,value);
  }
  @override
  Widget build(BuildContext context) {
    final p=widget.library;
    final sessions=(filter=='Archived'?p.sessions.where((s)=>s.archived).toList():p.recent).where((s)=>'${s.displayTitle} ${s.character}'.toLowerCase().contains(query.toLowerCase())).toList();
    if(sort=='Title')sessions.sort((a,b)=>a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
    if(sort=='Progress')sessions.sort((a,b)=>(b.state?.actions??b.turns.length).compareTo(a.state?.actions??a.turns.length));
    final saved=widget.covers.where((s)=>p.bookmarks.contains(s.definition?.id??s.title)&&'${s.title} ${s.genre}'.toLowerCase().contains(query.toLowerCase())).toList();
    if(sort=='Title')saved.sort((a,b)=>a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Your library',style:TextStyle(fontFamily:'Lora',fontSize:34,fontWeight:FontWeight.w500)),const SizedBox(height:8),const Text('Every world you’ve made a little more yours.', style: TextStyle(color: muted, height: 1.5)),const SizedBox(height:16),
      Wrap(spacing:8,children:[for(final f in ['Continue','Bookmarks','Archived']) ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f))]),const SizedBox(height:16),
      TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(labelText:'Search your library',prefixIcon:Icon(Icons.search))),
      DropdownButton<String>(value:sort,items:[for(final s in ['Recent','Title','Progress'])DropdownMenuItem(value:s,child:Text('Sort: $s'))],onChanged:(v)=>setState(()=>sort=v??'Recent')),
      if(filter=='Bookmarks') ...[
        for(final s in saved) Card(child: ListTile(contentPadding: const EdgeInsets.all(12), leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 52, height: 68, child: Artwork(s.art))), title:Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),subtitle:Text('${s.genre} · With ${s.character}', style: const TextStyle(color: muted, fontSize: 11)), trailing: const Icon(Icons.arrow_forward, size: 18),onTap:()=>widget.onStory(s))),
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
