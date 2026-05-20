import '../models/product.dart';
import 'product_service.dart';

class ScanService {
  final ProductService _productService = ProductService();

  Future<List<Product>> findByCode(String code) async {
    return await _productService.searchProducts(code);
  }
}
