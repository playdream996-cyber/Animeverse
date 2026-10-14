import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

const maxStoryFileBytes=600000;
Future<String> readBoundedStory(Stream<List<int>> stream) async {
  final bytes=BytesBuilder(copy:false);
  await for(final chunk in stream.timeout(const Duration(seconds:20))){
    if(bytes.length+chunk.length>maxStoryFileBytes)throw const FormatException('Story file is too large. Maximum size is 600 KB.');
    bytes.add(chunk);
  }
  final text=utf8.decode(bytes.takeBytes());
  if(text.length>150000)throw const FormatException('Story text exceeds 150,000 characters.');
  return text;
}
abstract interface class StoryFileGateway {
  Future<String?> pick();
  Future<bool> save(String text,String name);
  Future<void> share(String text,String name,Rect origin);
}
class NativeStoryFiles implements StoryFileGateway {
  @override Future<String?> pick()async{
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json'],allowMultiple:false,withData:false,withReadStream:true);
    if(result==null)return null;
    final file=result.files.single;
    if(!file.name.toLowerCase().endsWith('.json'))throw const FormatException('Choose an Animeverse .json story file.');
    if(file.size>maxStoryFileBytes)throw const FormatException('Story file is too large. Maximum size is 600 KB.');
    return readBoundedStory(file.readStream??file.xFile.openRead(0,maxStoryFileBytes+1));
  }
  @override Future<bool> save(String text,String name)async=>await FilePicker.platform.saveFile(dialogTitle:'Save original story',fileName:name,type:FileType.custom,allowedExtensions:['json'],bytes:Uint8List.fromList(utf8.encode(text)))!=null;
  @override Future<void> share(String text,String name,Rect origin)async{
    await SharePlus.instance.share(ShareParams(files:[XFile.fromData(Uint8List.fromList(utf8.encode(text)),mimeType:'application/json')],fileNameOverrides:[name],sharePositionOrigin:origin));
  }
}
String storyFilename(String title){final name=title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'),'_');return '${name.isEmpty?'Animeverse_story':name.substring(0,name.length.clamp(0,70))}.json';}
