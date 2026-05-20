import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class TrendingRepository {
  final ProductRepository _repository = ProductRepository();

  Stream<List<Product>> getTrending({String countryCode = 'es'}) {
    return _repository.getProducts(countryCode: countryCode).map((products) {
      final trending = products.where((p) => p.isTrending).toList();

      trending.sort((a, b) {
        final scoreA = a.views + a.clicks + a.sales;
        final scoreB = b.views + b.clicks + b.sales;
        return scoreB.compareTo(scoreA);
      });

      return trending;
    });
  }
}
