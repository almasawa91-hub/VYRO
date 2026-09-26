import 'package:flutter_test/flutter_test.dart';
import 'package:vyro/features/users/domain/user_model.dart';
import 'package:vyro/features/feed/domain/post_model.dart';
import 'package:vyro/features/marketplace/domain/product_model.dart';

void main() {
  group('VYRO Core Domain Models Tests', () {
    test('UserModel serialization and deserialization', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'user_123',
        phone: '+966500000000',
        displayName: 'محمد علي',
        username: 'mohammed_vyro',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['username'], 'mohammed_vyro');

      final deserialized = UserModel.fromMap(map, 'user_123');
      expect(deserialized.displayName, 'محمد علي');
      expect(deserialized.username, 'mohammed_vyro');
    });

    test('PostModel serialization and default values', () {
      final post = PostModel(
        postId: 'post_001',
        ownerId: 'user_123',
        ownerName: 'محمد علي',
        ownerPhoto: '',
        text: 'مرحباً بجميع مستخدمي VYRO!',
        createdAt: DateTime.now(),
      );

      final map = post.toMap();
      expect(map['privacy'], 'public');
      expect(map['likesCount'], 0);

      final deserialized = PostModel.fromMap(map, 'post_001');
      expect(deserialized.text, 'مرحباً بجميع مستخدمي VYRO!');
    });

    test('ProductModel price and currency formatting', () {
      final product = ProductModel(
        productId: 'prod_999',
        sellerId: 'user_123',
        sellerName: 'محمد علي',
        sellerPhoto: '',
        name: 'آيفون 15 بروماكس',
        description: 'جهاز ممتاز مع العلبة',
        price: 4500.0,
        category: 'إلكترونيات',
        condition: 'جديد',
        location: 'الرياض',
        createdAt: DateTime.now(),
      );

      expect(product.price, 4500.0);
      expect(product.currency, 'SAR');
    });
  });
}
