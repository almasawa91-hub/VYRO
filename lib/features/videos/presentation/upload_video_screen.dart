import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/video_repository.dart';

class UploadVideoScreen extends StatefulWidget {const UploadVideoScreen({super.key});@override State<UploadVideoScreen> createState()=>_UploadVideoScreenState();}
class _UploadVideoScreenState extends State<UploadVideoScreen>{final _desc=TextEditingController();final _repo=VideoRepository();File? _file;double _progress=0;bool _busy=false;
Future<void> _pick()async{final r=await FilePicker.platform.pickFiles(type:FileType.video);if(r?.files.single.path!=null)setState(()=>_file=File(r!.files.single.path!));}
Future<void> _upload()async{if(_file==null)return;setState(()=>_busy=true);try{await _repo.uploadVideo(videoFile:_file!,description:_desc.text,hashtags:const [],onProgress:(v){if(mounted)setState(()=>_progress=v);});if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل الرفع: $e')));}finally{if(mounted)setState(()=>_busy=false);}}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('رفع فيديو')),body:ListView(padding:const EdgeInsets.all(16),children:[OutlinedButton.icon(onPressed:_busy?null:_pick,icon:const Icon(Icons.video_library),label:Text(_file==null?'اختيار فيديو':_file!.path.split('/').last)),const SizedBox(height:12),TextField(controller:_desc,maxLines:4,decoration:const InputDecoration(labelText:'الوصف',border:OutlineInputBorder())),const SizedBox(height:16),if(_busy)LinearProgressIndicator(value:_progress),const SizedBox(height:16),FilledButton(onPressed:_busy||_file==null?null:_upload,child:Text(_busy?'جارٍ الرفع ${(100*_progress).toStringAsFixed(0)}%':'رفع الفيديو'))]);@override void dispose(){_desc.dispose();super.dispose();}}
