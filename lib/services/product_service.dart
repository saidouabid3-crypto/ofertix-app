import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getProducts({String countryCode = 'es'}) {
    final country = countryCode.toLowerCase();

    return _db.collection('products').snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Product.fromMap(data, doc.id);
          })
          .where((product) {
            // Online products: يبانُو للجميع
            if (product.isOnline) return true;

            // Local tiendas: غير حسب بلاد المستخدم
            return product.country.toLowerCase() == country;
          })
          .toList();

      products.sort((a, b) {
        if (a.isHot && !b.isHot) return -1;
        if (!a.isHot && b.isHot) return 1;
        return b.discount.compareTo(a.discount);
      });

      return products;
    });
  }

  Stream<List<Product>> getHotProducts({String countryCode = 'es'}) {
    return getProducts(countryCode: countryCode).map((products) {
      return products.where((p) => p.isHot).toList();
    });
  }

  Stream<List<Product>> getOnlineProducts() {
    return _db
        .collection('products')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<Product>> getLocalProducts({String countryCode = 'es'}) {
    return _db
        .collection('products')
        .where('isOnline', isEqualTo: false)
        .where('country', isEqualTo: countryCode.toLowerCase())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
