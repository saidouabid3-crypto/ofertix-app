import '../../models/product.dart';

import '../../repositories/product_repository.dart';

class HomeRepository {
  final ProductRepository _productRepository = ProductRepository();

  Stream<List<Product>> getProducts({String countryCode = 'es'}) {
    return _productRepository.getProducts(countryCode: countryCode);
  }

  Stream<List<Product>> getHotProducts({String countryCode = 'es'}) {
    return _productRepository.getHotProducts(countryCode: countryCode);
  }

  Stream<List<Product>> getFeaturedProducts({String countryCode = 'es'}) {
    return _productRepository.getFeaturedProducts(countryCode: countryCode);
  }
}
