import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';

import 'scan_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, ScanProvider provider) {
    final barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;

    if (code == null || code.isEmpty) return;

    provider.scanCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanProvider(),
      child: Consumer<ScanProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Smart Scanner'),
              actions: [
                IconButton(
                  onPressed: () {
                    scannerController.toggleTorch();
                  },
                  icon: const Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.orange,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    scannerController.switchCamera();
                  },
                  icon: const Icon(
                    Icons.cameraswitch_rounded,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: scannerController,
                        onDetect: (capture) => _onDetect(capture, provider),
                      ),

                      Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.orange,
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            provider.lastCode.isEmpty
                                ? 'Point camera at barcode or QR code'
                                : 'Detected: ${provider.lastCode}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.orange,
                            ),
                          )
                        : provider.results.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                color: AppColors.orange,
                                size: 52,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                provider.lastCode.isEmpty
                                    ? 'Scan a product to search deals'
                                    : 'No products found for this code',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.gray,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (provider.hasScanned) ...[
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: provider.resetScanner,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Scan again'),
                                ),
                              ],
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${provider.results.length} results',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: provider.resetScanner,
                                    child: const Text(
                                      'Scan again',
                                      style: TextStyle(color: AppColors.orange),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: GridView.builder(
                                  itemCount: provider.results.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.68,
                                      ),
                                  itemBuilder: (context, index) {
                                    final product = provider.results[index];

                                    return ProductGridCard(
                                      product: product,
                                      isFavorite: false,
                                      onFavorite: () {},
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailsScreen(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
