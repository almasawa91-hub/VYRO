import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المنتج'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final document = snapshot.data;
          if (document == null || !document.exists) return const Center(child: Text('المنتج غير موجود'));

          final data = document.data() ?? <String, dynamic>{};
          final imageUrls = _stringList(data['imageUrls']);
          final name = _stringValue(data['name'], fallback: 'منتج');
          final description = _stringValue(data['description']);
          final currency = _stringValue(data['currency']);
          final location = _stringValue(data['location'], fallback: 'غير محدد');
          final sellerName = _stringValue(data['sellerName'], fallback: 'البائع');
          final sellerPhoto = _stringValue(data['sellerPhoto']);
          final price = _numberValue(data['price']);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: imageUrls[index],
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                      placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                )
              else
                const SizedBox(height: 220, child: Center(child: Icon(Icons.image_not_supported_outlined, size: 64))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      '${price.toStringAsFixed(2)}${currency.isEmpty ? '' : ' $currency'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(description, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: sellerPhoto.isEmpty
                          ? const CircleAvatar(child: Icon(Icons.person))
                          : CircleAvatar(backgroundImage: CachedNetworkImageProvider(sellerPhoto)),
                      title: const Text('البائع'),
                      subtitle: Text(sellerName),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('الموقع'),
                      subtitle: Text(location),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
  }
}