import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/product_repository.dart';
import '../domain/product_model.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});
  @override State<MarketplaceTab> createState()=>_MarketplaceTabState();
}
class _MarketplaceTabState extends State<MarketplaceTab>{
  final _search=TextEditingController(); final _repo=ProductRepository();
  @override Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث في السوق',border:OutlineInputBorder()))),
    Expanded(child:StreamBuilder<List<ProductModel>>(stream:_repo.watchProducts(query:_search.text),builder:(c,s){
      if(s.hasError)return const Center(child:Text('تعذر تحميل السوق'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.isEmpty)return const Center(child:Text('لا توجد منتجات'));
      return GridView.builder(padding:const EdgeInsets.all(10),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.72),itemCount:s.data!.length,itemBuilder:(_,i){
        final p=s.data![i]; return Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>context.push('/product/${p.productId}'),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Expanded(child:p.imageUrls.isEmpty?const Icon(Icons.inventory_2_outlined,size:50):CachedNetworkImage(imageUrl:p.imageUrls.first,fit:BoxFit.cover)),
          Padding(padding:const EdgeInsets.all(8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),Text('${p.price.toStringAsFixed(2)} ${p.currency}')]))
        ])));
      });
    }))
  ]);
  @override void dispose(){_search.dispose();super.dispose();}
}
