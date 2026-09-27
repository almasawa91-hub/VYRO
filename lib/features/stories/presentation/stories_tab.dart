import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoriesTab extends StatelessWidget {
 const StoriesTab({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('stories').where('privacy',isEqualTo:'public').limit(30).snapshots(),builder:(c,s){if(s.hasError)return const Center(child:Text('تعذر تحميل القصص'));if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.docs.isEmpty)return const Center(child:Text('لا توجد قصص حاليًا'));return ListView.separated(padding:const EdgeInsets.all(12),itemCount:s.data!.docs.length,separatorBuilder:(_,_)=>const SizedBox(height:10),itemBuilder:(_,i){final m=s.data!.docs[i].data();return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.auto_stories)),title:Text(m['ownerName']??'مستخدم'),subtitle:Text(m['text']??'قصة'),trailing:Text(m['expiresAt']==null?'': 'متاحة'));});});}
}
