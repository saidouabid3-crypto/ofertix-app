import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/currency_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/product_service.dart';
import 'product_details_screen.dart';

/// Deep-link entry: `/product/:id` loads Firestore/API then opens details.
class ProductDetailsLoaderScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsLoaderScreen({super.key, required this.productId});

  @override
  State<ProductDetailsLoaderScreen> createState() =>
      _ProductDetailsLoaderScreenState();
}

class _ProductDetailsLoaderScreenState extends State<ProductDetailsLoaderScreen> {
  Product? _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseService.instance.firestore
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists && doc.data() != null) {
        if (!mounted) return;
        setState(() {
          _product = Product.fromMap(doc.data()!, doc.id);
        });
        return;
      }

      final list = await ProductService.instance.getProductsOnce(limit: 400);
      final match = list.where((p) => p.id == widget.productId).toList();

      if (!mounted) return;

      if (match.isNotEmpty) {
        setState(() => _product = match.first);
      } else {
        setState(() => _error = 'Product not found');
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Failed to load product');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_product != null) {
      final symbol = context.watch<CurrencyProvider>().symbol;
      return ProductDetailsScreen(
        product: _product!,
        currencySymbol: symbol,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
      ),
    );
  }
}
