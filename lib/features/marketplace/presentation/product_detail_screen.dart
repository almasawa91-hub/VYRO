import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId; const ProductDetailScreen({super.key,required this.productId});
  @override Widget build(BuildContext context)=>FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    future:FirebaseFirestore.instance.collection('products').doc(productId).get(),
    builder:(c,s){if(!s.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));final d=s.data!;if(!d.exists)return const Scaffold(body:Center(child:Text('المنتج غير موجود')));final m=d.data()!;final imgs=List<String>.from(m['imageUrls']??[]);
      return Scaffold(appBar:AppBar(title:Text(m['name']??'المنتج')),body:ListView(children:[
        if(imgs.isNotEmpty)SizedBox(height:280,child:PageView(children:imgs.map((u)=>CachedNetworkImage(imageUrl:u,fit:BoxFit.cover)).toList())),
        Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(m['name']??'',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),
          Text('${m['price']??0} ${m['currency']??''}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
          const SizedBox(height:16),Text(m['description']??''),const SizedBox(height:16),Text('الموقع: ${m['location']??'غير محدد'}'),Text('البائع: ${m['sellerName']??''}')
        ]))
      ]);});
}
