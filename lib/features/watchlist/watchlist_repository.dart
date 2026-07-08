import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';

class WatchlistRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getWatchlist({required Set<String> ids}) {
    if (ids.isEmpty) return Stream.value([]);

    return Stream.fromFuture(_loadProductsById(ids));
  }

  Future<List<Product>> _loadProductsById(Set<String> ids) async {
    final docs = await Future.wait(
      ids.take(60).map((id) => _db.collection('products').doc(id).get()),
    );
    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => Product.fromMap(doc.data()!, doc.id))
        .where((product) => product.image.isNotEmpty && product.newPrice > 0)
        .toList();
  }
}
