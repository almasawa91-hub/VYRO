import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String sellerId;
  final String sellerName;
  final String sellerPhoto;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<String> imageUrls;
  final String category;
  final String condition;
  final String location;
  final DateTime createdAt;

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhoto,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'SAR',
    this.imageUrls = const [],
    required this.category,
    required this.condition,
    required this.location,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhoto': sellerPhoto,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrls': imageUrls,
      'category': category,
      'condition': condition,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      productId: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhoto: map['sellerPhoto'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'SAR',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: map['category'] ?? 'أخرى',
      condition: map['condition'] ?? 'جديد',
      location: map['location'] ?? 'غير محدد',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
