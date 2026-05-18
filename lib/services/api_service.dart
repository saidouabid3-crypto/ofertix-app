import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductsPage {
  final List<Product> products;
  final bool hasMore;
  final int count;

  ProductsPage({
    required this.products,
    required this.hasMore,
    required this.count,
  });
}

class ApiService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<ProductsPage> getProductsPage({
    int limit = 50,
    int page = 1,
    required String countryCode,
  }) async {
    try {
      final country = countryCode.toLowerCase();

      // ONLINE: يبان للعالم كامل
      final onlineSnapshot = await firestore
          .collection('products')
          .where('isOnline', isEqualTo: true)
          .limit(limit)
          .get();

      // LOCAL / TIENDAS: غير ديال البلاد ديال المستخدم
      final localSnapshot = await firestore
          .collection('products')
          .where('isOnline', isEqualTo: false)
          .where('country', isEqualTo: country)
          .limit(limit)
          .get();

      final onlineProducts = onlineSnapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromMap(data, doc.id);
      }).toList();

      final localProducts = localSnapshot.docs.map((doc) {
        final data = doc.data();
        return Product.fromMap(data, doc.id);
      }).toList();

      final products = [...onlineProducts, ...localProducts];

      print('COUNTRY: $country');
      print('ONLINE PRODUCTS: ${onlineProducts.length}');
      print('LOCAL PRODUCTS: ${localProducts.length}');
      print('TOTAL PRODUCTS: ${products.length}');

      return ProductsPage(
        products: products,
        hasMore: false,
        count: products.length,
      );
    } catch (e) {
      print('FIRESTORE ERROR: $e');
      return ProductsPage(products: [], hasMore: false, count: 0);
    }
  }

  Future<List<Product>> getProducts({required String countryCode}) async {
    final result = await getProductsPage(
      countryCode: countryCode,
      page: 1,
      limit: 100,
    );

    return result.products;
  }

  Future<List<Product>> searchWithAI(
    String query, {
    String countryCode = 'es',
  }) async {
    try {
      final country = countryCode.toLowerCase();

      final onlineSnapshot = await firestore
          .collection('products')
          .where('isOnline', isEqualTo: true)
          .limit(150)
          .get();

      final localSnapshot = await firestore
          .collection('products')
          .where('isOnline', isEqualTo: false)
          .where('country', isEqualTo: country)
          .limit(150)
          .get();

      final allDocs = [...onlineSnapshot.docs, ...localSnapshot.docs];

      final q = query.toLowerCase();

      final products = allDocs
          .map((doc) {
            final data = doc.data();
            return Product.fromMap(data, doc.id);
          })
          .where((p) {
            final text = '${p.name} ${p.description} ${p.category} ${p.store}'
                .toLowerCase();

            return text.contains(q);
          })
          .toList();

      return products;
    } catch (e) {
      print('AI SEARCH ERROR: $e');
      return [];
    }
  }

  void resetPagination() {
    // دابا ما بقيناش محتاجين pagination هنا
  }
}
