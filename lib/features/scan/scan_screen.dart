import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';
import 'scan_provider.dart';

// ─── Smart Scanner — immersive deal checker ───────────────────────────────────

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _urlCtrl = TextEditingController();
  final FocusNode _urlFocus = FocusNode();
  late final AnimationController _lineCtrl;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _urlCtrl.dispose();
    _urlFocus.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, ScanProvider provider) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    HapticFeedback.mediumImpact();
    provider.scanCode(code);
  }

  void _submitUrl(ScanProvider provider) {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    _urlFocus.unfocus();
    provider.scanCode(url);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanProvider(),
      child: Consumer<ScanProvider>(
        builder: (context, provider, _) {
          final hasResults = provider.results.isNotEmpty;
          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'scan.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _scanner.toggleTorch,
                  icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                  tooltip: 'scan.torch'.tr(),
                ),
                IconButton(
                  onPressed: _scanner.switchCamera,
                  icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: hasResults
                ? _ResultsView(
                    provider: provider,
                    onScanAgain: () {
                      provider.resetScanner();
                      _urlCtrl.clear();
                    },
                  )
                : _ScannerView(
                    scanner: _scanner,
                    lineCtrl: _lineCtrl,
                    urlCtrl: _urlCtrl,
                    urlFocus: _urlFocus,
                    provider: provider,
                    onDetect: _onDetect,
                    onSubmitUrl: _submitUrl,
                  ),
          );
        },
      ),
    );
  }
}

// ─── Scanner view ─────────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController scanner;
  final AnimationController lineCtrl;
  final TextEditingController urlCtrl;
  final FocusNode urlFocus;
  final ScanProvider provider;
  final void Function(BarcodeCapture, ScanProvider) onDetect;
  final void Function(ScanProvider) onSubmitUrl;

  const _ScannerView({
    required this.scanner,
    required this.lineCtrl,
    required this.urlCtrl,
    required this.urlFocus,
    required this.provider,
    required this.onDetect,
    required this.onSubmitUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen camera
        MobileScanner(
          controller: scanner,
          onDetect: (c) => onDetect(c, provider),
        ),

        // Dark overlay outside frame
        IgnorePointer(
          child: CustomPaint(
            painter: _OverlayPainter(),
          ),
        ),

        // Animated scan line
        AnimatedBuilder(
          animation: lineCtrl,
          builder: (_, __) {
            final frac = lineCtrl.value;
            return Positioned(
              left: (MediaQuery.of(context).size.width - 256) / 2,
              top: MediaQuery.of(context).size.height * 0.24 +
                  256 * frac,
              child: Container(
                width: 256,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.orange.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        ),

        // Corner guides
        Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: CustomPaint(painter: _CornerPainter()),
          ),
        ),

        // Status label
        Positioned(
          bottom: 200 + bottom,
          left: 32,
          right: 32,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: provider.isLoading
                ? const _StatusChip(
                    icon: Icons.search_rounded,
                    text: 'Buscando...',
                    accent: true,
                  )
                : provider.lastCode.isNotEmpty
                    ? _StatusChip(
                        icon: Icons.check_circle_rounded,
                        text: 'scan.detected'.tr(),
                        accent: true,
                      )
                    : _StatusChip(
                        icon: Icons.qr_code_scanner_rounded,
                        text: 'scan.hint'.tr(),
                        accent: false,
                      ),
          ),
        ),

        // Bottom sheet: URL input
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
            decoration: BoxDecoration(
              color: const Color(0xFF071318).withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  'scan.orPasteLink'.tr(),
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1B22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: TextField(
                          controller: urlCtrl,
                          focusNode: urlFocus,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onSubmitted: (_) => onSubmitUrl(provider),
                          decoration: InputDecoration(
                            hintText: 'scan.urlHint'.tr(),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.link_rounded,
                              color: AppColors.gray,
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => onSubmitUrl(provider),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Loading overlay
        if (provider.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.orange,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analizando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Results view ─────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final ScanProvider provider;
  final VoidCallback onScanAgain;

  const _ResultsView({required this.provider, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top    = MediaQuery.of(context).padding.top;

    return Container(
      color: const Color(0xFF050D11),
      child: Column(
        children: [
          // Results header
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 70, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.results.length} ${'scan.results'.tr()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.orange, size: 18),
                  label: Text(
                    'scan.scanAgain'.tr(),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 20),
              itemCount: provider.results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, i) {
                final product = provider.results[i];
                return ProductGridCard(
                  product: product,
                  isFavorite: false,
                  onFavorite: () {},
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool accent;

  const _StatusChip({required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.orange.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent
                ? AppColors.orange
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 7),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overlay painter (darkens outside the scan frame) ────────────────────────

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 256.0;
    final cx = size.width / 2;
    final cy = size.height * 0.37;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: frameSize,
      height: frameSize,
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.56),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Corner guides painter ────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 22.0;
    const len = 34.0;
    const w = 3.0;
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // TL
    canvas.drawLine(Offset(r, 0), Offset(r + len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, r + len), paint);
    // TR
    canvas.drawLine(Offset(size.width - r, 0), Offset(size.width - r - len, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    // BL
    canvas.drawLine(Offset(r, size.height), Offset(r + len, size.height), paint);
    canvas.drawLine(Offset(0, size.height - r), Offset(0, size.height - r - len), paint);
    // BR
    canvas.drawLine(Offset(size.width - r, size.height),
        Offset(size.width - r - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - r),
        Offset(size.width, size.height - r - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
