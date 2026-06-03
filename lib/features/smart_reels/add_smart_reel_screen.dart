import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/smart_reel_service.dart';

class AddSmartReelScreen extends StatefulWidget {
  AddSmartReelScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<AddSmartReelScreen> createState() => _AddSmartReelScreenState();
}

class _AddSmartReelScreenState extends State<AddSmartReelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final SmartReelService _service;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final storeController = TextEditingController();
  final currentPriceController = TextEditingController();
  final oldPriceController = TextEditingController();
  final affiliateController = TextEditingController();

  File? selectedVideo;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _service = SmartReelService(baseUrl: widget.baseUrl);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    storeController.dispose();
    currentPriceController.dispose();
    oldPriceController.dispose();
    affiliateController.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    if (uploading) return;

    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: 60),
    );

    if (picked == null) return;

    final file = File(picked.path);
    final sizeMb = await file.length() / (1024 * 1024);

    if (sizeMb > 120) {
      _showMessage('reels.videoTooLarge'.tr());
      return;
    }

    setState(() {
      selectedVideo = file;
    });
  }

  Future<void> uploadReel() async {
    if (uploading) return;
    if (!_formKey.currentState!.validate()) return;

    if (selectedVideo == null) {
      _showMessage('reels.selectVideoFirst'.tr());
      return;
    }

    final currentPrice = _parsePrice(currentPriceController.text);
    final oldPrice = oldPriceController.text.trim().isEmpty
        ? null
        : _parsePrice(oldPriceController.text);

    if (currentPrice <= 0) {
      _showMessage('reels.invalidPrice'.tr());
      return;
    }

    setState(() => uploading = true);

    try {
      await _service.uploadSmartReel(
        videoFile: selectedVideo!,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        store: storeController.text.trim(),
        currentPrice: currentPrice,
        oldPrice: oldPrice == 0 ? null : oldPrice,
        currency: 'EUR',
        affiliateUrl: affiliateController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('reels.uploadSuccess'.tr());
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('reels.uploadError'.tr());
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  double _parsePrice(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Color(0xFFFF7A1A)),
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Color(0xFFFF7A1A), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050505),
      appBar: AppBar(
        title: Text(
          'auto.smart_reels_add_smart_reel_screen.anadir_smart_reel'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Color(0xFF050505),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: uploading,
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _HeroUploadCard(
                selectedVideo: selectedVideo,
                uploading: uploading,
                onTap: pickVideo,
              ),
              SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Título del producto',
                        hint: 'Ej: iPhone 13 reacondicionado',
                        icon: Icons.sell_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Título obligatorio';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      style: TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: _inputDecoration(
                        label: 'Descripción',
                        hint: 'Explica por qué es una buena oferta',
                        icon: Icons.description_rounded,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: storeController,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Tienda',
                        hint: 'Amazon, Zara, MediaMarkt...',
                        icon: Icons.storefront_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Tienda obligatoria';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: currentPriceController,
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              label: 'Precio actual',
                              hint: '299.99',
                              icon: Icons.euro_rounded,
                            ),
                            validator: (value) {
                              final price = _parsePrice(value ?? '');
                              if (price <= 0) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: oldPriceController,
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              label: 'Antes',
                              hint: '399.99',
                              icon: Icons.local_offer_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: affiliateController,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        label: 'Link de compra',
                        hint: 'https://...',
                        icon: Icons.link_rounded,
                      ),
                    ),
                    SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: uploading ? null : uploadReel,
                        icon: uploading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          uploading
                              ? 'Subiendo reel...'
                              : 'Publicar Smart Reel',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF7A1A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroUploadCard extends StatelessWidget {
  _HeroUploadCard({
    required this.selectedVideo,
    required this.uploading,
    required this.onTap,
  });

  final File? selectedVideo;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasVideo = selectedVideo != null;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF7A1A).withValues(alpha: 0.24),
              Colors.white.withValues(alpha: 0.07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: hasVideo ? Color(0xFFFF7A1A) : Colors.white24,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF7A1A).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasVideo
                    ? Icons.check_circle_rounded
                    : Icons.video_call_rounded,
                color: Color(0xFFFF7A1A),
                size: 52,
              ),
              SizedBox(height: 12),
              Text(
                hasVideo ? 'Video seleccionado ✅' : 'Elegir video del móvil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'auto.smart_reels_add_smart_reel_screen.recomendado_vertical_maximo_60_segundo'
                    .tr()
                    .tr(),
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
