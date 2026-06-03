import 'product.dart';

class ProductsPage {
  final List<Product> products;
  final int count;
  final bool hasMore;

  const ProductsPage({
    required this.products,
    required this.count,
    required this.hasMore,
  });
}
