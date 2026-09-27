import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/product_repository.dart';

class CreateProductScreen extends StatefulWidget { const CreateProductScreen({super.key}); @override State<CreateProductScreen> createState()=>_CreateProductScreenState(); }
class _CreateProductScreenState extends State<CreateProductScreen>{
 final _form=GlobalKey<FormState>(); final _name=TextEditingController(),_desc=TextEditingController(),_price=TextEditingController(),_location=TextEditingController();
 final _repo=ProductRepository(); final _picker=ImagePicker(); List<File> _images=[]; bool _busy=false;
 Future<void> _pick()async{final x=await _picker.pickMultiImage(imageQuality:85);setState(()=>_images=x.map((e)=>File(e.path)).take(6).toList());}
 Future<void> _save()async{if(!_form.currentState!.validate())return;setState(()=>_busy=true);try{await _repo.createProduct(name:_name.text,description:_desc.text,price:double.parse(_price.text),category:'عام',condition:'جديد',location:_location.text,images:_images);if(mounted)Navigator.pop(context);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إضافة المنتج: $e')));}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('إضافة منتج')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(16),children:[
 TextFormField(controller:_name,decoration:const InputDecoration(labelText:'اسم المنتج',border:OutlineInputBorder()),validator:(v)=>v!.trim().isEmpty?'أدخل اسم المنتج':null),
 const SizedBox(height:10),TextFormField(controller:_price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'السعر',border:OutlineInputBorder()),validator:(v)=>double.tryParse(v??'')==null?'السعر غير صحيح':null),
 const SizedBox(height:10),TextFormField(controller:_desc,maxLines:4,decoration:const InputDecoration(labelText:'الوصف',border:OutlineInputBorder())),
 const SizedBox(height:10),TextFormField(controller:_location,decoration:const InputDecoration(labelText:'الموقع',border:OutlineInputBorder())),
 const SizedBox(height:10),OutlinedButton.icon(onPressed:_pick,icon:const Icon(Icons.photo_library),label:const Text('صور المنتج')),
 if(_images.isNotEmpty)Wrap(children:_images.map((f)=>Padding(padding:const EdgeInsets.all(4),child:Image.file(f,width:80,height:80,fit:BoxFit.cover))).toList()),
 const SizedBox(height:18),FilledButton(onPressed:_busy?null:_save,child:_busy?const CircularProgressIndicator():const Text('حفظ المنتج'))
 ])));
 @override void dispose(){_name.dispose();_desc.dispose();_price.dispose();_location.dispose();super.dispose();}
}
