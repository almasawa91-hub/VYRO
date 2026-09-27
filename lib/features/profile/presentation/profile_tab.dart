import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../auth/data/auth_repository.dart';

class ProfileTab extends StatelessWidget {
 const ProfileTab({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Center(child:Text('يجب تسجيل الدخول'));return FutureBuilder(future:AuthRepository().getUserProfile(uid),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final p=s.data;if(p==null)return const Center(child:Text('أكمل إنشاء ملفك الشخصي'));return ListView(padding:const EdgeInsets.all(20),children:[CircleAvatar(radius:45,backgroundImage:p.photoUrl.isEmpty?null:NetworkImage(p.photoUrl),child:p.photoUrl.isEmpty?const Icon(Icons.person,size:45):null),const SizedBox(height:12),Center(child:Text(p.displayName,style:Theme.of(context).textTheme.headlineSmall)),Center(child:Text('@${p.username}')),if(p.bio.isNotEmpty)Padding(padding:const EdgeInsets.all(16),child:Center(child:Text(p.bio))),Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[_Stat('المتابعون',p.followersCount),_Stat('يتابع',p.followingCount),_Stat('الأصدقاء',p.friendsCount)]),const SizedBox(height:20),const SizedBox.shrink()]);});}
}
class _Stat extends StatelessWidget{final String label;final int value;const _Stat(this.label,this.value);@override Widget build(BuildContext c)=>Column(children:[Text('$value',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text(label)]);}
