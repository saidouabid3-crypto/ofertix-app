import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class TrendingRepository {
  final ProductRepository _repository = ProductRepository();

  Stream<List<Product>> getTrending({String countryCode = 'es'}) {
    return _repository.getProducts(countryCode: countryCode).map((products) {
      // Phase 1: products with real engagement signals.
      var trending = products.where((p) => p.isTrending).toList();

      trending.sort((a, b) {
        final scoreA = a.views + a.clicks + a.sales;
        final scoreB = b.views + b.clicks + b.sales;
        return scoreB.compareTo(scoreA);
      });

      if (trending.isNotEmpty) return trending;

      // Phase 2 fallback: no engagement data yet (new catalog).
      // Surface the highest-discount hot/featured products so the screen
      // is never empty while the catalog is bootstrapping.
      final fallback = products
          .where((p) => p.isHot || p.featured || p.discount >= 30)
          .toList();
      fallback.sort((a, b) => b.discount.compareTo(a.discount));
      if (fallback.isNotEmpty) return fallback.take(40).toList();

      // Phase 3: absolute fallback — top 40 by discount.
      final all = [...products];
      all.sort((a, b) => b.discount.compareTo(a.discount));
      return all.take(40).toList();
    });
  }
}
