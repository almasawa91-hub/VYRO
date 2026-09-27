import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
 const NotificationsScreen({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('يجب تسجيل الدخول')));
 return Scaffold(appBar:AppBar(title:const Text('الإشعارات')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('notifications').where('userId',isEqualTo:uid).limit(50).snapshots(),builder:(c,s){if(s.hasError)return const Center(child:Text('تعذر تحميل الإشعارات'));if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.docs.isEmpty)return const Center(child:Text('لا توجد إشعارات'));return ListView(children:s.data!.docs.map((d){final m=d.data();return ListTile(leading:const Icon(Icons.notifications_outlined),title:Text(m['title']??'إشعار'),subtitle:Text(m['body']??''));}).toList());}));
 }
}
