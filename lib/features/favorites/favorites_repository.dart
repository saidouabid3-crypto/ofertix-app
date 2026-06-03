import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';

class FavoritesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getFavorites({required Set<String> ids}) {
    if (ids.isEmpty) {
      return Stream.value([]);
    }

    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            return Product.fromMap(doc.data(), doc.id);
          })
          .where((product) => ids.contains(product.id))
          .toList();
    });
  }
}
