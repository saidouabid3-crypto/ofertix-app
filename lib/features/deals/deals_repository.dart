import '../../models/product.dart';
import '../../repositories/product_repository.dart';

class DealsRepository {
  final ProductRepository _repository = ProductRepository();

  Stream<List<Product>> getDeals({String countryCode = 'es'}) {
    return _repository.getProducts(countryCode: countryCode).map((products) {
      final deals = products.where((p) {
        return p.hasRealDiscount || p.discount > 0 || p.isHot;
      }).toList();

      deals.sort((a, b) => b.discount.compareTo(a.discount));

      return deals;
    });
  }
}
