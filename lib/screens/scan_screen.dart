import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanned = false;

  Future<void> scanBarcode(String barcode) async {
    if (scanned) return;

    setState(() {
      scanned = true;
    });

    try {
      String productName = 'Unknown product';
      String productImage = '';

      final productResponse = await http.get(
        Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
        ),
      );

      if (productResponse.statusCode == 200) {
        final data = jsonDecode(productResponse.body);

        if (data['status'] == 1) {
          final product = data['product'];

          productName = product['product_name'] ?? 'Unknown product';

          productImage = product['image_url'] ?? '';
        }
      }

      final pricesResponse = await http.get(
        Uri.parse(
          'https://prices.openfoodfacts.org/api/v1/prices?product_code=$barcode',
        ),
      );

      List prices = [];

      if (pricesResponse.statusCode == 200) {
        final pricesData = jsonDecode(pricesResponse.body);

        if (pricesData['items'] != null) {
          prices = pricesData['items'];
        }
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF121212),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (productImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        productImage,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 18),

                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Barcode: $barcode',
                    style: const TextStyle(color: AppColors.gray),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Store Prices',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 16),

                  if (prices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        'No real prices found yet for this barcode.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),

                  ...prices.map((price) {
                    final store = price['location_osm_name'] ?? 'Unknown Store';

                    final amount = price['price']?.toString() ?? '?';

                    final currency = price['currency'] ?? 'EUR';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              store,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          Text(
                            '$amount $currency',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        scanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Text(
                  'Smart Scan',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final barcode = capture.barcodes.first.rawValue;

                        if (barcode != null) {
                          scanBarcode(barcode);
                        }
                      },
                    ),

                    Center(
                      child: Container(
                        width: 240,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.orange, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              'Scan a real barcode to compare real store prices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray),
            ),
          ),
        ],
      ),
    );
  }
}
