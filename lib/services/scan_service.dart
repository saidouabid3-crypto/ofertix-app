import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'product_service.dart';

// ─── Scan service — barcode → product name → Ofertix search ─────────────────

class ScanService {
  final ProductService _productService = ProductService();

  static final _barcodeRe = RegExp(r'^\d{8,14}$');

  Future<List<Product>> findByCode(String code) async {
    final clean = code.trim();

    // Barcode (EAN-8, EAN-13, UPC-A, etc.) — resolve via Open Food Facts first
    if (_barcodeRe.hasMatch(clean)) {
      final name = await _nameFromBarcode(clean);
      if (name != null && name.trim().isNotEmpty) {
        final results = await _productService.searchProducts(name.trim());
        if (results.isNotEmpty) return results;
      }
      // Fall through to raw code search if name lookup or search fails
    }

    return await _productService.searchProducts(clean);
  }

  /// Calls Open Food Facts (free, no key) to get the product name for a barcode.
  Future<String?> _nameFromBarcode(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'Ofertix/1.0'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>? ?? {};

      // Prefer localized Spanish name → generic name → brand + generic
      final nameEs = (product['product_name_es'] ?? '').toString().trim();
      final nameGen = (product['product_name'] ?? '').toString().trim();
      final brand   = (product['brands'] ?? '').toString().trim().split(',').first.trim();

      if (nameEs.isNotEmpty) return nameEs;
      if (nameGen.isNotEmpty) return nameGen;
      if (brand.isNotEmpty)   return brand;
      return null;
    } catch (_) {
      return null;
    }
  }
}
