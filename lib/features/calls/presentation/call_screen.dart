import 'package:flutter/material.dart';
class CallScreen extends StatelessWidget {
 final String channelId; final bool isAudioOnly; final String otherUserName;
 const CallScreen({super.key,required this.channelId,required this.isAudioOnly,required this.otherUserName});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(isAudioOnly?'مكالمة صوتية':'مكالمة فيديو')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
 const Icon(Icons.phone_in_talk_outlined,size:64),const SizedBox(height:16),Text(otherUserName.isEmpty?'مكالمة':otherUserName,style:Theme.of(context).textTheme.titleLarge),
 const SizedBox(height:12),const Text('واجهة الاتصال جاهزة للإشارة، لكن نقل الصوت/الفيديو يحتاج مزود WebRTC/RTC فعليًا. لم يتم تمثيل مكالمة وهمية على أنها اتصال حقيقي.'),
 const SizedBox(height:20),OutlinedButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق'))
]))));
}
