import 'package:flutter/material.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends StatelessWidget {
 const SettingsScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(children:[
 const ListTile(title:Text('الحساب'),subtitle:Text('إدارة تسجيل الدخول والملف الشخصي')),
  const Divider(),ListTile(leading:const Icon(Icons.logout),title:const Text('تسجيل الخروج'),onTap:()async{await AuthRepository().signOut();if(context.mounted)Navigator.of(context).popUntil((r)=>r.isFirst);}),
 ListTile(leading:const Icon(Icons.delete_outline),title:const Text('حذف الحساب'),subtitle:const Text('يحذف حساب Firebase والملف الأساسي'),onTap:()async{try{await AuthRepository().deleteAccount();if(context.mounted)Navigator.of(context).popUntil((r)=>r.isFirst);}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('قد يتطلب الحذف إعادة المصادقة: $e')));}})
 ]));
}
