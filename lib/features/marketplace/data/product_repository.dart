import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Stream<List<ProductModel>> watchProducts({String? query}) {
    return _db.collection('products').orderBy('createdAt', descending: true).limit(50).snapshots().map((s) {
      final q = (query ?? '').trim().toLowerCase();
      return s.docs.map((d)=>ProductModel.fromMap(d.data(),d.id)).where((p)=>
        q.isEmpty || p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<String> createProduct({
    required String name, required String description, required double price,
    required String category, required String condition, required String location, List<File> images=const [],
  }) async {
    final u=_auth.currentUser; if(u==null) throw StateError('يجب تسجيل الدخول');
    final id=_db.collection('products').doc().id;
    final user=(await _db.collection('users').doc(u.uid).get()).data()??{};
    final urls=<String>[];
    for(var i=0;i<images.length;i++){
      final ref=_storage.ref('products/${u.uid}/$id/$i.jpg');
      await ref.putFile(images[i], SettableMetadata(contentType:'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    await _db.collection('products').doc(id).set({
      'productId':id,'sellerId':u.uid,'sellerName':user['displayName']??'مستخدم VYRO',
      'sellerPhoto':user['photoUrl']??'','name':name.trim(),'description':description.trim(),
      'price':price,'currency':'SAR','imageUrls':urls,'category':category,
      'condition':condition,'location':location,'createdAt':FieldValue.serverTimestamp(),
    });
    return id;
  }
}
