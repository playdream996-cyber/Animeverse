import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart' show Artwork,StoryGuide,DemoBadge,MemorySheet,ink,panel,lavender,muted,line,artFor,coverFor;
import 'story_session.dart';
import 'creator/project_library.dart';
import 'player_panels.dart';
import 'ui_helpers.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key,required this.session,this.library});
  final StorySession session;final ProjectLibrary? library;
  @override State<ChatScreen> createState()=>_ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen>{
  final input=TextEditingController();final scroll=ScrollController();
  Timer? _readingTimer;
  double textSize=17;
  bool _layoutQueued=false;
  static const historyPageSize=40;
  int windowStart=0;
  int get windowEnd=>(windowStart+historyPageSize).clamp(0,s.turns.length);
  bool get atLatest=>windowEnd==s.turns.length;
  int savedWindow()=>s.readingWindows[s.activeBranch]??(s.readingOffset==null?(s.turns.length-historyPageSize).clamp(0,s.turns.length):0);
  late String _branch;
  StorySession get s=>widget.session;
  @override void initState(){super.initState();textSize=widget.library?.readingSize??17;_branch=s.activeBranch;windowStart=savedWindow();s.addListener(refresh);s.replyText.addListener(followReply);scroll.addListener(readingChanged);restoreReading();}
  void readingChanged(){_readingTimer?.cancel();_readingTimer=Timer(const Duration(milliseconds:600),(){if(mounted&&scroll.hasClients)s.recordReadingOffset(scroll.offset.clamp(0,scroll.position.maxScrollExtent),windowStart:windowStart);});}
  void restoreReading(){WidgetsBinding.instance.addPostFrameCallback((_){if(!mounted||!scroll.hasClients)return;final saved=s.readingOffset;scroll.jumpTo(saved==null?(s.turns.length>1?scroll.position.maxScrollExtent:0):saved.clamp(0,scroll.position.maxScrollExtent));});}
  void followReply(){if(!atLatest||!mounted||!scroll.hasClients||scroll.position.maxScrollExtent-scroll.offset>120||_layoutQueued)return;_layoutQueued=true;WidgetsBinding.instance.addPostFrameCallback((_){_layoutQueued=false;if(mounted&&scroll.hasClients)scroll.jumpTo(scroll.position.maxScrollExtent);});}
  void refresh(){if(!mounted)return;final changed=_branch!=s.activeBranch;final follow=scroll.hasClients&&scroll.position.maxScrollExtent-scroll.offset<120;setState((){_branch=s.activeBranch;if(changed)windowStart=savedWindow();});if(changed){_readingTimer?.cancel();restoreReading();}else if(follow){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&scroll.hasClients)scroll.jumpTo(scroll.position.maxScrollExtent);});}}
  @override void dispose(){_readingTimer?.cancel();s.removeListener(refresh);s.replyText.removeListener(followReply);scroll.removeListener(readingChanged);if(scroll.hasClients)s.recordReadingOffset(scroll.offset.clamp(0,scroll.position.maxScrollExtent),windowStart:windowStart);s.stopReply();input.dispose();scroll.dispose();super.dispose();}
  void send([String? choice]){if(s.isReplying||s.completed)return;final value=(choice??input.text).trim();if(value.isEmpty)return;setState(()=>windowStart=(s.turns.length-historyPageSize+3).clamp(0,s.turns.length));s.send(value);input.clear();WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&scroll.hasClients)scroll.jumpTo(scroll.position.maxScrollExtent);});}
  void page(int start,{bool latest=false}){
    _readingTimer?.cancel();
    setState(()=>windowStart=start.clamp(0,s.turns.length-1));
    s.recordReadingOffset(0,windowStart:windowStart);
    WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&scroll.hasClients)scroll.jumpTo(latest?scroll.position.maxScrollExtent:0);});
  }
  Widget historyControls()=>Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    Text('Messages ${windowStart+1}–$windowEnd of ${s.turns.length}',style:const TextStyle(color:muted,fontSize:11)),
    Wrap(spacing:8,runSpacing:4,children:[if(windowStart>0)TextButton(onPressed:()=>page((windowStart-historyPageSize).clamp(0,s.turns.length)),child:const Text('Earlier messages')),
      if(!atLatest)TextButton(onPressed:()=>page(windowEnd),child:const Text('Later messages')),
      if(!atLatest)TextButton(onPressed:()=>page((s.turns.length-historyPageSize).clamp(0,s.turns.length),latest:true),child:const Text('Jump to latest'))]),
  ]));
  Future<void> branchAfter(int index)async{
    final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Try another path?'),content:const Text('Keep the original timeline and start a new one after this message. Earlier checkpoints clear pinned notes so later discoveries cannot leak into the past.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Create branch'))]));
    if(yes==true&&mounted)s.fork(throughTurn:index);
  }
  Future<void> memories()async{await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:ink,builder:(_)=>MemorySheet(session:s));}
  Future<void> status()async{await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:ink,builder:(_)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:s.story?.rules==null?const Text('This opening-only story has no authored stats or ending rules.'):AdventurePanel(session:s))));}
  Future<void> branches()async{if(s.isReplying)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:ink,builder:(_)=>BranchSheet(session:s));}
  Future<void> transportTest()async{
    final transport=s.transport;if(transport is! PreviewTransport||s.isReplying)return;
    final failure=await showDialog<PreviewFailure>(context:context,builder:(context)=>SimpleDialog(title:const Text('Preview connection tests'),children:[const Padding(padding:EdgeInsets.all(16),child:Text('Fail the next reply locally to test recovery. No server request is made.')),for(final f in PreviewFailure.values)SimpleDialogOption(onPressed:()=>Navigator.pop(context,f),child:Text(f==PreviewFailure.none?'Normal reply':f.name))]));
    if(failure!=null&&mounted){transport.nextFailure=failure;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Next reply test: ${failure.name}')));}
  }
  String get art=>s.state==null?s.story?.art??coverFor(s.title).art:s.story!.rules!.scene(s.state!.scene).art;
  Widget header()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Semantics(button:true,label:'View scene artwork',child:InkWell(onTap:()=>artworkViewer(context,art),child:SizedBox(height:260,child:Stack(fit:StackFit.expand,children:[Artwork(art),const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xEE0D0E10)]))),Positioned(bottom:20,left:22,right:22,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('CHAPTER 01',style:TextStyle(color:lavender,fontSize:10,letterSpacing:2)),const SizedBox(height:6),Text(s.state==null?'The first encounter':s.story!.rules!.scene(s.state!.scene).title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontFamily:'Lora',fontSize:28,fontWeight:FontWeight.w500))]))])))),
    Padding(padding:const EdgeInsets.fromLTRB(22,8,22,24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const DemoBadge(),if(s.story!=null)StoryGuide(story:s.story!),const Padding(padding:EdgeInsets.only(top:12),child:Text('Choose an action or write what you do. Split a message to try another path.',style:TextStyle(color:muted,fontSize:12,height:1.5)))])),
  ]);
  Widget choices(){
    final rules=s.story?.rules,world=s.state;
    final actions=rules!=null&&world!=null?rules.scene(world.scene).actions:null;
    final labels=actions?.map((a)=>a.label).toList()??s.choices;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Divider(),const SizedBox(height:18),const Text('WHERE DOES YOUR STORY GO?',style:TextStyle(color:muted,fontSize:9,letterSpacing:1.5)),const SizedBox(height:12),for(var i=0;i<labels.length;i++)Builder(builder:(context){
      final a=actions?[i];final available=a==null||a.available(world!);
      final requirements=a==null?'':a.minimum.entries.where((e)=>(world!.stats[e.key]??0)<e.value).map((e)=>'Needs ${rules!.stats.firstWhere((x)=>x.id==e.key).name} ${e.value} · you have ${world!.stats[e.key]}').join('\n');
      return Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:panel,borderRadius:BorderRadius.circular(16),child:InkWell(onTap:available?()=>send(labels[i]):null,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(available?Icons.east:Icons.lock_outline,size:17,color:available?lavender:muted),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(labels[i],style:TextStyle(fontSize:13,color:available?null:muted)),if(!available)Padding(padding:const EdgeInsets.only(top:6),child:Text(requirements,style:const TextStyle(color:muted,fontSize:11)))])),if(available)const Icon(Icons.arrow_upward,size:15,color:muted)])))));
    })]);
  }
  Widget footer()=>Padding(padding:const EdgeInsets.fromLTRB(22,0,22,24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    if(s.isReplying&&atLatest)ReplyStream(session:s,textSize:textSize),
    if(s.completed&&atLatest)AdventurePanel(session:s),
    if(s.replyError!=null&&atLatest)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.replyError!,style:const TextStyle(color:Colors.orangeAccent)),if(s.canRetry)TextButton.icon(onPressed:s.retryReply,icon:const Icon(Icons.refresh),label:const Text('Retry reply'))]))),
    if(s.replyStopped)const Padding(padding:EdgeInsets.only(bottom:12),child:Text('Reply stopped',style:TextStyle(color:muted,fontSize:12))),
    if(!s.isReplying&&!s.completed&&atLatest)choices(),
    if(!atLatest)TextButton(onPressed:()=>page((s.turns.length-historyPageSize).clamp(0,s.turns.length),latest:true),child:const Text('Jump to latest')),
  ]));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(titleSpacing:0,title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.displayTitle,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600)),const SizedBox(height:2),Text(s.activeBranch,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:10))]),actions:[
    IconButton(tooltip:'Adventure status',onPressed:status,icon:const Icon(Icons.insights_outlined)),
    PopupMenuButton<String>(tooltip:'Story controls',onSelected:(v){if(v=='memory')memories();if(v=='branch')branches();if(v=='status')status();if(v=='fault')transportTest();if(v=='size'){setState(()=>textSize=textSize>=23?17:textSize+3);if(widget.library!=null){widget.library!.readingSize=textSize;widget.library!.changed();}}},itemBuilder:(_)=>[const PopupMenuItem(value:'memory',child:Text('Memories & summary')),PopupMenuItem(value:'branch',enabled:!s.isReplying,child:const Text('Story branches')),const PopupMenuItem(value:'status',child:Text('Adventure status')),const PopupMenuItem(value:'size',child:Text('Reading size')),PopupMenuItem(value:'fault',enabled:!s.isReplying,child:const Text('Preview connection tests'))]),
  ]),body:SafeArea(top:false,child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:Column(children:[
    if(s.state!=null)AdventureSummary(session:s,onTap:status),
    Expanded(child:CustomScrollView(controller:scroll,slivers:[SliverToBoxAdapter(child:header()),if(s.turns.length>historyPageSize)SliverToBoxAdapter(child:historyControls()),SliverList.builder(itemCount:windowEnd-windowStart,itemBuilder:(context,index){final absolute=windowStart+index;return RepaintBoundary(child:TurnMessage(key:ObjectKey(s.turns[absolute]),turn:s.turns[absolute],session:s,textSize:textSize,onBranch:s.isReplying?null:()=>branchAfter(absolute)));}),SliverToBoxAdapter(child:footer())])),
    Container(decoration:const BoxDecoration(color:ink,border:Border(top:BorderSide(color:line))),padding:const EdgeInsets.all(10),child:Column(children:[if(widget.library!=null)Align(alignment:Alignment.centerRight,child:SaveIndicator(library:widget.library!)),Row(crossAxisAlignment:CrossAxisAlignment.end,children:[IconButton(tooltip:'Memories',onPressed:memories,icon:const Icon(Icons.auto_stories_outlined,color:muted,size:20)),Expanded(child:TextField(controller:input,enabled:!s.completed,minLines:1,maxLines:4,maxLength:2000,decoration:InputDecoration(hintText:s.completed?'Ending reached · try another path':'Write your next move…',counterText:'',isDense:true),onSubmitted:(_)=>send())),const SizedBox(width:8),IconButton.filled(tooltip:'Send action',onPressed:s.isReplying||s.completed?null:send,icon:const Icon(Icons.arrow_upward,size:21))])])),
  ])))));
}
class TurnMessage extends StatelessWidget{
  const TurnMessage({super.key,required this.turn,required this.session,required this.textSize,this.onBranch});
  final Turn turn;final StorySession session;final double textSize;final VoidCallback? onBranch;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(22,0,22,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[if(turn.speaker!='You')...[ClipOval(child:SizedBox(width:26,height:26,child:Artwork(artFor(turn.speaker)))),const SizedBox(width:8)]else...[Icon(session.avatar=='Star'?Icons.star_outline:session.avatar=='Moon'?Icons.dark_mode_outlined:Icons.eco_outlined,size:16,color:muted),const SizedBox(width:6)],Flexible(child:Text(turn.speaker=='You'?session.playerName:turn.speaker,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:turn.speaker=='You'?muted:lavender,fontWeight:FontWeight.w600,fontSize:12))),const Spacer(),IconButton(tooltip:'Branch after this message',onPressed:onBranch,icon:const Icon(Icons.call_split,size:16,color:muted))]),const SizedBox(height:12),if(turn.partial)const Text('Partial reply · world state unchanged',style:TextStyle(color:muted,fontSize:11)),SelectableText(turn.text,style:TextStyle(fontFamily:'Lora',fontSize:textSize,height:1.75,color:turn.speaker=='You'?muted:const Color(0xFFDCDDE1)))]));
}
class ReplyStream extends StatelessWidget{
  const ReplyStream({super.key,required this.session,required this.textSize});final StorySession session;final double textSize;
  @override Widget build(BuildContext context)=>ValueListenableBuilder<String>(valueListenable:session.replyText,builder:(context,value,_)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(value.isNotEmpty)...[Text(session.character,style:const TextStyle(color:lavender,fontWeight:FontWeight.w600)),const SizedBox(height:12),SelectableText(value,style:TextStyle(fontFamily:'Lora',fontSize:textSize,height:1.75)),const SizedBox(height:12)],Row(children:[const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2,color:lavender)),const SizedBox(width:10),Expanded(child:Text(value.isEmpty?'${session.character} is replying…':'${session.character} is writing…',style:const TextStyle(color:muted,fontSize:12))),TextButton(onPressed:session.stopReply,child:const Text('Stop'))]) ]));
}
class BranchSheet extends StatefulWidget{
  const BranchSheet({super.key,required this.session});final StorySession session;
  @override State<BranchSheet> createState()=>_BranchSheetState();
}
class _BranchSheetState extends State<BranchSheet>{
  Future<void> rename(String name)async{
    final input=TextEditingController(text:name);String? error;
    await showDialog<void>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setState)=>AlertDialog(title:const Text('Rename timeline'),content:TextField(controller:input,maxLength:50,decoration:InputDecoration(labelText:'Timeline name',errorText:error)),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){if(widget.session.renameBranch(name,input.text)){Navigator.pop(context);}else{setState(()=>error='Choose a unique, nonempty name.');}},child:const Text('Rename'))])));input.dispose();
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.session,builder:(context,_){final s=widget.session;return SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Choose a timeline',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),for(final entry in s.branches.entries)ListTile(contentPadding:EdgeInsets.zero,leading:Icon(entry.key==s.activeBranch?Icons.check_circle:Icons.alt_route,color:lavender),title:Text(entry.key),subtitle:Text('${s.branchOrigins[entry.key]??'Saved checkpoint'}\n${entry.value.length} messages · ${entry.value.last.state?.goals.length??0} objectives',maxLines:3,overflow:TextOverflow.ellipsis),trailing:IconButton(tooltip:'Rename timeline',onPressed:()=>rename(entry.key),icon:const Icon(Icons.edit_outlined)),onTap:(){s.selectBranch(entry.key);Navigator.pop(context);}),const SizedBox(height:14),FilledButton.icon(onPressed:s.isReplying?null:(){s.fork();Navigator.pop(context);},icon:const Icon(Icons.call_split),label:const Text('Branch from here'))])));});
}
