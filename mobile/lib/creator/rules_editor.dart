import 'dart:convert';
import 'package:flutter/material.dart';
import '../adventure_rules.dart';

class RulesEditor extends StatefulWidget {
  const RulesEditor({super.key, this.rules});
  final AdventureRules? rules;
  @override
  State<RulesEditor> createState() => _RulesEditorState();
}
class _RulesEditorState extends State<RulesEditor> {
  late Map<String,dynamic> data = object(jsonDecode(jsonEncode((widget.rules ?? lighthouseRules()).toJson())));
  final form = GlobalKey<FormState>();
  final fieldScroll = <String, ScrollController>{};
  ScrollController scroller(Map row, String field) => fieldScroll.putIfAbsent('${identityHashCode(row)}-$field', () => ScrollController(keepScrollOffset: false));
  @override
  void dispose() { for (final controller in fieldScroll.values) { controller.dispose(); } super.dispose(); }
  String? error;
  int sequence = 0;
  String keyFor(String group) => '$group-${DateTime.now().microsecondsSinceEpoch}-${sequence++}';
  List<dynamic> rows(String group) => data[group] as List;
  Widget text(Map row, String key, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom:12), child: TextFormField(key: ValueKey('${row['id']}-$key'),
      scrollController: scroller(row, key), initialValue: row[key] as String? ?? '', minLines:lines,maxLines:lines+2,maxLength:4000,
      decoration:InputDecoration(labelText:label), onChanged:(v)=>row[key]=v,
      validator:(v)=>v==null||v.trim().isEmpty?'Add $label':null));
  Widget number(Map row,String key,String label) => Padding(padding:const EdgeInsets.only(bottom:12),
    child:TextFormField(key:ValueKey('${row['id']}-$key'),scrollController:scroller(row,key),initialValue:'${row[key]??0}',keyboardType:const TextInputType.numberWithOptions(signed:true),
      decoration:InputDecoration(labelText:label),validator:(v)=>int.tryParse(v??'')==null?'Use a whole number':null,
      onChanged:(v){ final n=int.tryParse(v); if(n!=null) row[key]=n; }));
  Widget select(Map row,String key,String label,List<dynamic> options,String name,{bool optional=false}) {
    final ids=options.map((e)=>e['id'] as String).toSet();
    final selected=ids.contains(row[key])?row[key] as String:'';
    return Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(label), DropdownButton<String>(isExpanded:true,value:selected.isEmpty?null:selected,
        hint:Text(optional?'None':'Choose one'),items:[if(optional) const DropdownMenuItem(value:'',child:Text('None')),
          for(final r in options) DropdownMenuItem(value:r['id'] as String,child:Text('${r[name]}',maxLines:1,overflow:TextOverflow.ellipsis))],
        onChanged:(v)=>setState(()=>row[key]=v??''))]));
  }
  Widget goals(Map row) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Objectives'),
    Wrap(spacing:6,children:[for(final goal in rows('goals')) FilterChip(label:Text(goal['title']),selected:(row['goals'] as List).contains(goal['id']),
      onSelected:(v)=>setState((){if(v){(row['goals'] as List).add(goal['id']);}else{(row['goals'] as List).remove(goal['id']);}}))])]);
  Widget statMap(Map row,String key,String label) => ExpansionTile(title:Text(label),children:[for(final stat in rows('stats'))
    Column(children:[SwitchListTile(title:Text(stat['name']),value:(row[key] as Map).containsKey(stat['id']),
      onChanged:(v)=>setState((){if(v){row[key][stat['id']]=0;}else{(row[key] as Map).remove(stat['id']);}})),
      if((row[key] as Map).containsKey(stat['id'])) number(row[key] as Map,stat['id'], label)])]);
  Widget block(String group,String label,int limit,Map<String,dynamic> Function() create, List<Widget> Function(Map) fields) => ExpansionTile(
    key:PageStorageKey(group),title:Text('$label (${rows(group).length})'),children:[
      for(final row in rows(group)) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text('${row['name']??row['title']??'Edit'}',style:const TextStyle(fontWeight:FontWeight.bold))),
          IconButton(tooltip:'Remove $label entry',onPressed:()=>setState(()=>rows(group).remove(row)),icon:const Icon(Icons.delete_outline))]),
        ...fields(row as Map)]))),
      TextButton.icon(onPressed:rows(group).length>=limit?null:()=>setState(()=>rows(group).add(create())),icon:const Icon(Icons.add),label:Text('Add $label'))]);
  Map<String,dynamic> action() => {'id':keyFor('action'),'label':'New choice','reply':'Describe what happens.','next':rows('scenes').isEmpty?'':rows('scenes').first['id'],'deltas':<String,int>{},'goals':<String>[],'minimum':<String,int>{},'ending':''};
  Widget actionEditor(Map scene,Map a) => Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    text(a,'label','Choice text'),text(a,'reply','Authored reply',lines:2),select(a,'next','Next scene',rows('scenes'),'title'),
    statMap(a,'deltas','Stat changes'),statMap(a,'minimum','Minimum stats to offer this choice'),goals(a),select(a,'ending','Attempt ending',rows('endings'),'name',optional:true),
    TextButton(onPressed:()=>setState(()=>(scene['actions'] as List).remove(a)),child:const Text('Remove choice'))])));
  void save() {
    if(!form.currentState!.validate()) {setState(()=>error='Fix the highlighted fields.');return;}
    try {
      final rules=AdventureRules.fromJson(data); final errors=rules.validate();
      if(errors.isNotEmpty){setState(()=>error=errors.join('\n'));return;}
      Navigator.pop(context,rules);
    } catch(_){setState(()=>error='Check the adventure settings.');}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Adventure rules'),actions:[TextButton(onPressed:save,child:const Text('Apply rules'))]),
    body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:Form(key:form,child:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Make choices matter',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:12),
      if (widget.rules == null) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Lighthouse example · replace the scenes, replies and rules to make your own adventure.')),
      const Text('Author each response and its effects. Endings require every selected objective and stat condition. Active lore is limited to the three highest-priority entries. Changes apply when you tap Apply rules.'),
      if(error!=null) Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
      block('stats','Stats',7,()=>{'id':keyFor('stat'),'name':'New stat','min':0,'max':5,'initial':0},(r)=>[text(r,'name','Stat name'),number(r,'min','Minimum'),number(r,'max','Maximum'),number(r,'initial','Starting value')]),
      block('goals','Objectives',20,()=>{'id':keyFor('goal'),'title':'New objective'},(r)=>[text(r,'title','Objective title')]),
      block('lore','Lore',30,()=>{'id':keyFor('lore'),'title':'New lore','body':'A rule of this world.','stat':'','atLeast':0,'priority':0,'scope':'World'},(r)=>[
        text(r,'title','Lore title'),text(r,'body','Lore text',lines:2),select(r,'stat','Activate at stat',rows('stats'),'name',optional:true),number(r,'atLeast','Trigger threshold'),number(r,'priority','Priority'),
        DropdownButton<String>(value:r['scope'],items:[for(final s in ['World','Companion']) DropdownMenuItem(value:s,child:Text(s))],onChanged:(v)=>setState(()=>r['scope']=v))]),
      block('endings','Endings',10,()=>{'id':keyFor('ending'),'name':'New ending','epilogue':'Write the final scene.','hint':'What should the player pursue?','minTurns':1,'minimum':<String,int>{},'maximum':<String,int>{},'goals':<String>[]},(r)=>[
        text(r,'name','Ending name'),text(r,'epilogue','Epilogue',lines:3),text(r,'hint','Player hint'),number(r,'minTurns','Minimum completed actions'),statMap(r,'minimum','Minimum ending stats'),statMap(r,'maximum','Maximum ending stats'),goals(r)]),
      block('scenes','Scenes',30,()=>{'id':keyFor('scene'),'title':'New scene','art':storyArt.first,'actions':[action()]},(r)=>[
        text(r,'title','Scene title'),DropdownButton<String>(isExpanded:true,value:r['art'],items:[for(var i=0;i<storyArt.length;i++) DropdownMenuItem(value:storyArt[i],child:Text(['Academy','Future city','Lantern town'][i]))],onChanged:(v)=>setState(()=>r['art']=v)),
        for(final a in r['actions'] as List) actionEditor(r,a as Map),
        TextButton.icon(onPressed:(r['actions'] as List).length>=8?null:()=>setState(()=>(r['actions'] as List).add(action())),icon:const Icon(Icons.add),label:const Text('Add choice'))]),
      block('starts','Starting scenarios',6,()=>{'id':keyFor('start'),'name':'New start','opening':'{player}, your adventure begins.','scene':rows('scenes').isEmpty?'':rows('scenes').first['id'],'stats':<String,int>{}},(r)=>[
        text(r,'name','Start name'),text(r,'opening','Opening for this start',lines:3),select(r,'scene','Starting scene',rows('scenes'),'title'),statMap(r,'stats','Starting stat overrides')]),
      const SizedBox(height:24),FilledButton(onPressed:save,child:const Text('Apply rules')),const SizedBox(height:24),
    ]))))));
}
