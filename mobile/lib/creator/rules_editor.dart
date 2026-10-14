import 'dart:convert';
import 'package:flutter/material.dart';
import '../adventure_rules.dart';

class RulesEditor extends StatefulWidget {
  const RulesEditor({super.key,this.rules});
  final AdventureRules? rules;
  @override State<RulesEditor> createState()=>_RulesEditorState();
}
class _Issue {
  const _Issue(this.group,this.owner,this.row,this.field,this.message);
  final String group,field,message;
  final Map owner,row;
}
class _RulesEditorState extends State<RulesEditor> {
  late Map<String,dynamic> data=object(jsonDecode(jsonEncode((widget.rules??lighthouseRules()).toJson())));
  final scroll=ScrollController();
  final fieldScroll=<String,ScrollController>{};
  final fieldKeys=<String,GlobalKey>{};
  String group='stats';
  bool dirty=false,leaving=false;
  String? error,focusId;
  int sequence=0;
  static const labels={'stats':'Stats','goals':'Objectives','lore':'Lore','endings':'Endings','scenes':'Scenes','starts':'Starting scenarios'};
  static const limits={'stats':7,'goals':20,'lore':30,'endings':10,'scenes':30,'starts':6};
  List<dynamic> rows(String name)=>data[name] as List;
  String identity(Map row,String field)=>'${identityHashCode(row)}-$field';
  GlobalKey fieldKey(Map row,String field)=>fieldKeys.putIfAbsent(identity(row,field),()=>GlobalKey());
  ScrollController scroller(Map row,String field)=>fieldScroll.putIfAbsent(identity(row,field),()=>ScrollController(keepScrollOffset:false));
  String keyFor(String kind)=>'$kind-${DateTime.now().microsecondsSinceEpoch}-${sequence++}';
  void markDirty(){if(!dirty && mounted)setState(()=>dirty=true);}
  @override void dispose(){scroll.dispose();for(final c in fieldScroll.values){c.dispose();}super.dispose();}
  void clearFieldCache(){final old=fieldScroll.values.toList();fieldScroll.clear();fieldKeys.clear();WidgetsBinding.instance.addPostFrameCallback((_){for(final c in old){c.dispose();}});}
  void changeGroup(String value){FocusManager.instance.primaryFocus?.unfocus();setState((){group=value;focusId=null;});WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&scroll.hasClients)scroll.jumpTo(0);});}
  Widget text(Map row,String key,String label,{int lines=1})=>Padding(key:fieldKey(row,key),padding:const EdgeInsets.only(bottom:12),child:TextFormField(
    key:ValueKey(identity(row,key)),scrollController:scroller(row,key),initialValue:row[key] as String? ?? '',minLines:lines,maxLines:lines+2,maxLength:4000,
    decoration:InputDecoration(labelText:label),onChanged:(v){row[key]=v;markDirty();}));
  Widget number(Map row,String key,String label)=>Padding(key:fieldKey(row,key),padding:const EdgeInsets.only(bottom:12),child:TextFormField(
    key:ValueKey(identity(row,key)),scrollController:scroller(row,key),initialValue:'${row[key]??''}',keyboardType:const TextInputType.numberWithOptions(signed:true),
    decoration:InputDecoration(labelText:label),onChanged:(v){row[key]=int.tryParse(v);markDirty();}));
  Widget select(Map row,String key,String label,List<dynamic> options,String name,{bool optional=false}){
    final ids=options.map((e)=>e['id']).toSet();final value=ids.contains(row[key])?row[key] as String:'';
    return Padding(key:fieldKey(row,key),padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label),DropdownButton<String>(isExpanded:true,value:value.isEmpty?null:value,hint:Text(optional?'None':'Choose one'),
      items:[if(optional)const DropdownMenuItem(value:'',child:Text('None')),for(final r in options)DropdownMenuItem(value:r['id'] as String,child:Text('${r[name]}',maxLines:1,overflow:TextOverflow.ellipsis))],
      onChanged:(v)=>setState((){row[key]=v??'';dirty=true;}))]));
  }
  Widget goals(Map row)=>Column(key:fieldKey(row,'goals'),crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Objectives'),Wrap(spacing:6,children:[for(final g in rows('goals'))FilterChip(label:Text(g['title']),selected:(row['goals'] as List).contains(g['id']),onSelected:(v)=>setState((){dirty=true;if(v){(row['goals'] as List).add(g['id']);}else{(row['goals'] as List).remove(g['id']);}}))])]);
  Widget statMap(Map row,String key,String label)=>ExpansionTile(key:fieldKey(row,key),title:Text(label),children:[for(final s in rows('stats'))Column(children:[SwitchListTile(title:Text(s['name']),value:(row[key] as Map).containsKey(s['id']),onChanged:(v)=>setState((){dirty=true;if(v){row[key][s['id']]=0;}else{(row[key] as Map).remove(s['id']);}})),if((row[key] as Map).containsKey(s['id']))number(row[key] as Map,s['id'],label)])]);
  Map<String,dynamic> action()=>{'id':keyFor('action'),'label':'New choice','reply':'Describe what happens.','next':rows('scenes').isEmpty?'':rows('scenes').first['id'],'deltas':<String,int>{},'goals':<String>[],'minimum':<String,int>{},'ending':''};
  Map<String,dynamic> create(String g)=>switch(g){
    'stats'=>{'id':keyFor('stat'),'name':'New stat','min':0,'max':5,'initial':0},
    'goals'=>{'id':keyFor('goal'),'title':'New objective'},
    'lore'=>{'id':keyFor('lore'),'title':'New lore','body':'A rule of this world.','stat':'','atLeast':0,'priority':0,'scope':'World'},
    'endings'=>{'id':keyFor('ending'),'name':'New ending','epilogue':'Write the final scene.','hint':'What should the player pursue?','minTurns':1,'minimum':<String,int>{},'maximum':<String,int>{},'goals':<String>[]},
    'scenes'=>{'id':keyFor('scene'),'title':'New scene','art':storyArt.first,'actions':[action()]},
    _=>{'id':keyFor('start'),'name':'New start','opening':'{player}, your adventure begins.','scene':rows('scenes').isEmpty?'':rows('scenes').first['id'],'stats':<String,int>{}};
  Future<void> remove(String g,Map row,{Map? scene})async{
    final confirmed=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('Remove this entry?'),content:Text(g=='stats'||g=='goals'?'Related conditions and effects will also be removed. You can undo this deletion.':'Other entries may need updated references. You can undo this deletion.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Remove'))]));
    if(confirmed!=true||!mounted)return;
    final before=jsonEncode(data);
    setState((){dirty=true;final list=scene==null?rows(g):scene['actions'] as List;list.remove(row);if(g=='stats'||g=='goals')prune(data,row['id'] as String,g);});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:const Text('Entry removed'),action:SnackBarAction(label:'Undo',onPressed:(){if(!mounted)return;clearFieldCache();setState((){data=object(jsonDecode(before));dirty=true;error=null;});})));
  }
  void prune(dynamic value,String id,String g){
    if(value is Map){for(final key in value.keys.toList()){final v=value[key];if(g=='stats' && ['minimum','maximum','deltas','stats'].contains(key) && v is Map)v.remove(id);if(g=='stats'&&key=='stat'&&v==id)value[key]='';if(g=='goals'&&key=='goals'&&v is List)v.remove(id);prune(v,id,g);}}
    else if(value is List){for(final child in value){prune(child,id,g);}}
  }
  Widget actionEditor(Map scene,Map a)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[text(a,'label','Choice text'),text(a,'reply','Authored reply',lines:2),select(a,'next','Next scene',rows('scenes'),'title'),statMap(a,'deltas','Stat changes'),statMap(a,'minimum','Minimum stats to offer this choice'),goals(a),select(a,'ending','Attempt ending',rows('endings'),'name',optional:true),TextButton(onPressed:()=>remove('actions',a,scene:scene),child:const Text('Remove choice'))])));
  List<Widget> fields(String g,Map r)=>switch(g){
    'stats'=>[text(r,'name','Stat name'),number(r,'min','Minimum'),number(r,'max','Maximum'),number(r,'initial','Starting value')],
    'goals'=>[text(r,'title','Objective title')],
    'lore'=>[text(r,'title','Lore title'),text(r,'body','Lore text',lines:2),select(r,'stat','Activate at stat',rows('stats'),'name',optional:true),number(r,'atLeast','Trigger threshold'),number(r,'priority','Priority'),DropdownButton<String>(value:r['scope'],items:[for(final s in ['World','Companion'])DropdownMenuItem(value:s,child:Text(s))],onChanged:(v)=>setState((){r['scope']=v;dirty=true;}))],
    'endings'=>[text(r,'name','Ending name'),text(r,'epilogue','Epilogue',lines:3),text(r,'hint','Player hint'),number(r,'minTurns','Minimum completed actions'),statMap(r,'minimum','Minimum ending stats'),statMap(r,'maximum','Maximum ending stats'),goals(r)],
    'scenes'=>[text(r,'title','Scene title'),DropdownButton<String>(isExpanded:true,value:r['art'],items:[for(var i=0;i<storyArt.length;i++)DropdownMenuItem(value:storyArt[i],child:Text(['Academy','Future city','Lantern town'][i]))],onChanged:(v)=>setState((){r['art']=v;dirty=true;})),for(final a in r['actions'] as List)actionEditor(r,a as Map),TextButton.icon(onPressed:(r['actions'] as List).length>=8?null:()=>setState((){(r['actions'] as List).add(action());dirty=true;}),icon:const Icon(Icons.add),label:const Text('Add choice'))],
    _=>[text(r,'name','Start name'),text(r,'opening','Opening for this start',lines:3),select(r,'scene','Starting scene',rows('scenes'),'title'),statMap(r,'stats','Starting stat overrides')]};
  _Issue? issue(){
    final statIds=rows('stats').map((x)=>x['id']).toSet(),sceneIds=rows('scenes').map((x)=>x['id']).toSet(),endingIds=rows('endings').map((x)=>x['id']).toSet();
    for(final g in labels.keys){for(final value in rows(g)){
      final r=value as Map;
      final required=switch(g){'stats'=>['name'],'goals'=>['title'],'lore'=>['title','body'],'endings'=>['name','epilogue','hint'],'scenes'=>['title'],_=>['name','opening']};
      for(final key in required){if((r[key] as String? ?? '').trim().isEmpty)return _Issue(g,r,r,key,'Add ${labels[g]} ${key=='name'?'name':key}.');}
      final ints=switch(g){'stats'=>['min','max','initial'],'lore'=>['atLeast','priority'],'endings'=>['minTurns'],_=> <String>[]};
      for(final key in ints){if(r[key] is! int)return _Issue(g,r,r,key,'Use a whole number for $key.');}
      if(g=='stats'&&(r['min']>=r['max']||r['initial']<r['min']||r['initial']>r['max']))return _Issue(g,r,r,'initial','Starting value must be inside a valid minimum/maximum range.');
      if(g=='lore'&&r['stat']!=''&&!statIds.contains(r['stat']))return _Issue(g,r,r,'stat','Choose an existing trigger stat.');
      if(g=='starts'&&!sceneIds.contains(r['scene']))return _Issue(g,r,r,'scene','Choose an existing starting scene.');
      for(final key in ['minimum','maximum','stats']){if(r[key] is Map){for(final v in (r[key] as Map).values){if(v is! int)return _Issue(g,r,r,key,'Use whole numbers in stat conditions.');}}}
      if(g=='scenes'){
        if((r['actions'] as List).isEmpty)return _Issue(g,r,r,'title','Add at least one choice to this scene.');
        for(final a in r['actions'] as List){for(final key in ['label','reply']){if((a[key] as String).trim().isEmpty)return _Issue(g,r,a as Map,key,'Add the choice text and its reply.');}
          if(!sceneIds.contains(a['next']))return _Issue(g,r,a as Map,'next','Choose an existing next scene.');
          if(a['ending']!=''&&!endingIds.contains(a['ending']))return _Issue(g,r,a as Map,'ending','Choose an existing ending or None.');
          for(final key in ['deltas','minimum']){if((a[key] as Map).values.any((v)=>v is! int))return _Issue(g,r,a as Map,key,'Use whole numbers for stat changes and conditions.');}
        }
      }
    }}return null;
  }
  void showIssue(_Issue issue){
    FocusManager.instance.primaryFocus?.unfocus();setState((){error=issue.message;group=issue.group;focusId=issue.owner['id'] as String;});
    WidgetsBinding.instance.addPostFrameCallback((_){if(!mounted||!scroll.hasClients)return;scroll.jumpTo(0);WidgetsBinding.instance.addPostFrameCallback((_){if(!mounted)return;final target=fieldKeys[identity(issue.row,issue.field)]?.currentContext;if(target!=null)Scrollable.ensureVisible(target,alignment:.15,duration:const Duration(milliseconds:200));});});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(issue.message)));
  }
  bool save(){
    final found=issue();if(found!=null){showIssue(found);return false;}
    try{final rules=AdventureRules.fromJson(data);final errors=rules.validate();if(errors.isNotEmpty){setState(()=>error=errors.join('\n'));if(scroll.hasClients)scroll.animateTo(0,duration:const Duration(milliseconds:200),curve:Curves.easeOut);return false;}leave(rules);return true;}
    catch(_){setState(()=>error='Check the highlighted adventure settings.');return false;}
  }
  void leave(AdventureRules? rules){setState((){dirty=false;leaving=true;});WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)Navigator.pop(context,rules);});}
  Future<void> back()async{
    if(leaving)return;
    final choice=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Keep your rule changes?'),content:const Text('These edits have not been applied to your draft.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,'keep'),child:const Text('Keep editing')),TextButton(onPressed:()=>Navigator.pop(context,'discard'),child:const Text('Discard')),FilledButton(onPressed:()=>Navigator.pop(context,'save'),child:const Text('Apply & leave'))]));
    if(!mounted)return;if(choice=='discard')leave(null);if(choice=='save')save();
  }
  @override Widget build(BuildContext context){
    final ordered=List<dynamic>.of(rows(group));if(focusId!=null){ordered.sort((a,b)=>a['id']==focusId?-1:b['id']==focusId?1:0);}
    return PopScope(canPop:!dirty,onPopInvokedWithResult:(didPop,result){if(!didPop)back();},child:Scaffold(appBar:AppBar(title:const Text('Adventure rules'),actions:[TextButton(onPressed:leaving?null:save,child:const Text('Apply rules'))]),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:CustomScrollView(controller:scroll,slivers:[
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Make choices matter',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:12),
        Text(dirty?'Unapplied changes':'Rules match this draft',style:const TextStyle(fontSize:12)),
        if(widget.rules==null)const Text('Lighthouse example · replace the scenes, replies and rules to make your own adventure.'),
        const SizedBox(height:12),const Text('Author responses and effects. Endings require all selected conditions. Apply rules to save them to the draft.'),const SizedBox(height:16),
        Wrap(spacing:8,runSpacing:8,children:[for(final g in labels.keys)ChoiceChip(label:Text('${labels[g]} (${rows(g).length})'),selected:g==group,onSelected:(_)=>changeGroup(g))]),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:16),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
      ]))),
      SliverList.builder(itemCount:ordered.length,itemBuilder:(context,index){final r=ordered[index] as Map;return Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),child:Card(key:ValueKey(r['id']),color:r['id']==focusId?Theme.of(context).colorScheme.errorContainer:null,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${r['name']??r['title']??'Edit'}',style:const TextStyle(fontWeight:FontWeight.bold))),IconButton(tooltip:'Remove ${labels[group]} entry',onPressed:()=>remove(group,r),icon:const Icon(Icons.delete_outline))]),...fields(group,r)]))));}),
      SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[TextButton.icon(onPressed:rows(group).length>=limits[group]!?null:()=>setState((){rows(group).add(create(group));dirty=true;}),icon:const Icon(Icons.add),label:Text('Add ${labels[group]}')),const SizedBox(height:16),FilledButton(onPressed:leaving?null:save,child:const Text('Apply rules'))]))),
    ]))))));
  }
}
