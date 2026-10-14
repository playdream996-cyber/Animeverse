import 'package:flutter/material.dart';
import 'creator/project_library.dart';

class SaveIndicator extends StatelessWidget {
  const SaveIndicator({super.key,required this.library});
  final ProjectLibrary library;
  @override
  Widget build(BuildContext context)=>ValueListenableBuilder<SavePhase>(valueListenable:library.savePhase,builder:(context,phase,_)=>Row(mainAxisSize:MainAxisSize.min,children:[
    Icon(phase==SavePhase.failed?Icons.error_outline:phase==SavePhase.saving?Icons.sync:phase==SavePhase.pending?Icons.schedule:Icons.check_circle_outline,size:14),const SizedBox(width:6),
    Text(library.readOnly?'Read-only recovery':switch(phase){SavePhase.saved=>'Saved on device',SavePhase.pending=>'Unsaved changes',SavePhase.saving=>'Saving…',SavePhase.failed=>'Save failed',SavePhase.readOnly=>'Read-only recovery'},style:const TextStyle(fontSize:11)),
    if(phase==SavePhase.failed && !library.readOnly) TextButton(onPressed:library.flush,child:const Text('Retry')),
  ]));
}
Future<void> artworkViewer(BuildContext context,String art) => Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>Scaffold(
  backgroundColor:Colors.black,appBar:AppBar(title:const Text('Scene artwork'),backgroundColor:Colors.black),
  body:SafeArea(child:InteractiveViewer(minScale:1,maxScale:4,child:Center(child:Image.asset(art,fit:BoxFit.contain,cacheWidth:1600,errorBuilder:(_,e,s)=>const Center(child:Text('Artwork unavailable')))))))));

Future<void> quickGuide(BuildContext context) => showDialog<void>(context:context,builder:(context)=>AlertDialog(title:const Text('Your first adventure'),
  content:const Text('Choose a story and a starting scene. Suggested actions change stats and objectives.\n\nTap Adventure status for lore and ending hints. Split a message to try another path. Your library keeps playthroughs, bookmarks and archived journeys.\n\nCreate lets you author your own rules. This preview saves on this device.'),
  actions:[FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Start exploring'))]));
