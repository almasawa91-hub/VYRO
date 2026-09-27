import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget { const SearchScreen({super.key}); @override State<SearchScreen> createState()=>_SearchScreenState(); }
class _SearchScreenState extends State<SearchScreen>{
 final _q=TextEditingController(); List<QueryDocumentSnapshot<Map<String,dynamic>>> _results=[]; bool _busy=false;
 Future<void> _search()async{final q=_q.text.trim().toLowerCase();if(q.isEmpty){setState(()=>_results=[]);return;}setState(()=>_busy=true);final s=await FirebaseFirestore.instance.collection('users').limit(50).get();setState(()=>_results=s.docs.where((d){final m=d.data();return (m['displayName']??'').toString().toLowerCase().contains(q)||(m['username']??'').toString().toLowerCase().contains(q);}).toList());setState(()=>_busy=false);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:TextField(controller:_q,textInputAction:TextInputAction.search,onSubmitted:(_)=>_search(),decoration:const InputDecoration(hintText:'ابحث عن مستخدم',border:InputBorder.none))),body:_busy?const Center(child:CircularProgressIndicator()):ListView.builder(itemCount:_results.length,itemBuilder:(_,i){final d=_results[i],m=d.data();return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(m['displayName']??''),subtitle:Text('@${m['username']??''}'),onTap:()=>c.push('/profile/${d.id}'));}));
 @override void dispose(){_q.dispose();super.dispose();}
}
