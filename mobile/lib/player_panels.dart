import 'package:flutter/material.dart';
import 'story_session.dart';
import 'creator/project_library.dart';

class AdventurePanel extends StatelessWidget {
  const AdventurePanel({super.key, required this.session});
  final StorySession session;
  @override
  Widget build(BuildContext context) {
    final rules=session.story?.rules, state=session.state;
    if(rules==null || state==null) return const SizedBox.shrink();
    final ending=session.ending;
    return Card(margin:const EdgeInsets.only(top:16,bottom:20),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(rules.scene(state.scene).title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      for(final stat in rules.stats) Padding(padding:const EdgeInsets.only(bottom:10),child:Semantics(label:'${stat.name}, ${state.stats[stat.id]} of ${stat.max}',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${stat.name} · ${state.stats[stat.id]} / ${stat.max}'),const SizedBox(height:5),
        LinearProgressIndicator(value:((state.stats[stat.id]??stat.initial)-stat.min)/(stat.max-stat.min))]))),
      for(final goal in rules.goals) ListTile(contentPadding:EdgeInsets.zero,dense:true,leading:Icon(state.goals.contains(goal.id)?Icons.check_circle:Icons.radio_button_unchecked),title:Text(goal.title)),
      if(state.changes.isNotEmpty) ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('Why did things change?'),children:[for(final reason in state.changes) ListTile(contentPadding:EdgeInsets.zero,title:Text(reason))]),
      ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('World & companion knowledge'),children:[
        for(final lore in rules.activeLore(state)) ListTile(contentPadding:EdgeInsets.zero,title:Text(lore.title),subtitle:Text('${lore.scope} · ${lore.body}')),
        const Padding(padding:EdgeInsets.only(bottom:12),child:Text('Player-pinned notes remain private and separate from authored lore.'))]),
      if(ending!=null) ...[
        const Divider(),Text('ENDING UNLOCKED',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontSize:11,letterSpacing:2)),const SizedBox(height:8),
        Text(ending.name,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text(session.personalize(ending.epilogue),style:const TextStyle(height:1.6)),
        const SizedBox(height:16),Wrap(spacing:8,runSpacing:8,children:[
          FilledButton(onPressed:()=>session.fork(throughTurn:0),child:const Text('Restart this start')),
          OutlinedButton(onPressed:()=>session.fork(throughTurn:(session.turns.length-3).clamp(0,session.turns.length-1)),child:const Text('Try another ending'))]),
      ],
      ExpansionTile(tilePadding:EdgeInsets.zero,title:const Text('Ending collection'),children:[for(final end in rules.endings)
        ListTile(contentPadding:EdgeInsets.zero,leading:Icon(session.branches.values.any((turns)=>turns.any((t)=>t.state?.ending==end.id))?Icons.emoji_events_outlined:Icons.lock_outline),
          title:Text(session.branches.values.any((turns)=>turns.any((t)=>t.state?.ending==end.id))?end.name:'Undiscovered ending'),subtitle:Text(end.hint))]),
      if(session.story!.mode=='Endless world') const Text('Endless world · objectives and stats continue; ending attempts do not close this timeline.'),
    ])));
  }
}
class PlayerSettings extends StatefulWidget {
  const PlayerSettings({super.key,required this.library});
  final ProjectLibrary library;
  @override
  State<PlayerSettings> createState()=>_PlayerSettingsState();
}
class _PlayerSettingsState extends State<PlayerSettings> {
  late final name=TextEditingController(text:widget.library.playerName);
  late String pronouns=widget.library.pronouns, avatar=widget.library.avatar;
  late double size=widget.library.readingSize;
  @override
  void dispose(){name.dispose();super.dispose();}
  Future<void> save() async {
    final p=widget.library;
    if(p.readOnly) return;
    p.playerName=name.text.trim().isEmpty?'You':name.text.trim();p.pronouns=pronouns;p.avatar=avatar;p.readingSize=size;
    p.changed();await p.flush();
    if(mounted && p.saveError==null) Navigator.pop(context);
    else if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(p.saveError??'Save unavailable.')));
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Player & reading settings')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
    const Text('Make the adventure yours',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    const Text('Your identity is stored on this device and copied into new playthroughs. Existing stories keep the identity they started with.'),const SizedBox(height:24),
    TextField(controller:name,maxLength:40,decoration:const InputDecoration(labelText:'Player name')),
    const SizedBox(height:12),const Text('Pronouns'),Wrap(spacing:8,children:[for(final v in ['they/them','she/her','he/him']) ChoiceChip(label:Text(v),selected:pronouns==v,onSelected:(_)=>setState(()=>pronouns=v))]),
    const SizedBox(height:20),const Text('Avatar'),Wrap(spacing:8,children:[for(final v in ['Star','Moon','Leaf']) ChoiceChip(avatar:Icon(v=='Star'?Icons.star_outline:v=='Moon'?Icons.dark_mode_outlined:Icons.eco_outlined),label:Text(v),selected:avatar==v,onSelected:(_)=>setState(()=>avatar=v))]),
    const SizedBox(height:20),Text('Reading size · ${size.toInt()}'),Slider(value:size,min:17,max:23,divisions:2,label:'${size.toInt()}',onChanged:(v)=>setState(()=>size=v)),
    const SizedBox(height:12),FilledButton(onPressed:widget.library.readOnly?null:save,child:const Text('Save settings')),
  ])));
}
