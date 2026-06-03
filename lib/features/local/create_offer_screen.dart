import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/local_offer_model.dart';
import '../../providers/local_engine_provider.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final formKey = GlobalKey<FormState>();
  final storeId = TextEditingController();
  final storeName = TextEditingController();
  final title = TextEditingController();
  final description = TextEditingController();
  final oldPrice = TextEditingController();
  final newPrice = TextEditingController();
  final currency = TextEditingController(text: 'EUR');
  final city = TextEditingController(text: 'Barcelona');
  final country = TextEditingController(text: 'es');
  final lat = TextEditingController();
  final lng = TextEditingController();
  final whatsapp = TextEditingController();
  final image = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    storeId.dispose(); storeName.dispose(); title.dispose(); description.dispose(); oldPrice.dispose(); newPrice.dispose(); currency.dispose(); city.dispose(); country.dispose(); lat.dispose(); lng.dispose(); whatsapp.dispose(); image.dispose();
    super.dispose();
  }

  double _money(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final oldValue = _money(oldPrice);
    final newValue = _money(newPrice);
    final discount = oldValue > 0 && newValue > 0 && oldValue > newValue ? (((oldValue - newValue) / oldValue) * 100).round() : 0;
    setState(() => saving = true);
    final offer = LocalOfferModel.empty().copyWithFromForm(
      storeId: storeId.text.trim(),
      storeName: storeName.text.trim(),
      title: title.text.trim(),
      description: description.text.trim(),
      image: image.text.trim(),
      oldPrice: oldValue,
      newPrice: newValue,
      currency: currency.text.trim().isEmpty ? 'EUR' : currency.text.trim(),
      discountPercent: discount,
      city: city.text.trim(),
      countryCode: country.text.trim().toLowerCase(),
      latitude: double.tryParse(lat.text.trim().replaceAll(',', '.')) ?? 0,
      longitude: double.tryParse(lng.text.trim().replaceAll(',', '.')) ?? 0,
      whatsapp: whatsapp.text.trim(),
      status: 'pending',
    );
    try {
      await LocalEngineProvider().createOffer(offer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('local.offerSubmitted'.tr())));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, title: Text('local.addOffer'.tr(), style: const TextStyle(fontWeight: FontWeight.w900))),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _Field(controller: storeId, label: 'Store ID'),
              _Field(controller: storeName, label: 'local.storeName'.tr(), requiredField: true),
              _Field(controller: title, label: 'local.offerTitle'.tr(), requiredField: true),
              _Field(controller: description, label: 'common.description'.tr(), maxLines: 3),
              Row(children: [Expanded(child: _Field(controller: oldPrice, label: 'local.oldPrice'.tr())), const SizedBox(width: 10), Expanded(child: _Field(controller: newPrice, label: 'local.newPrice'.tr(), requiredField: true))]),
              Row(children: [Expanded(child: _Field(controller: currency, label: 'common.currency'.tr())), const SizedBox(width: 10), Expanded(child: _Field(controller: city, label: 'common.city'.tr()))]),
              _Field(controller: country, label: 'common.country'.tr()),
              Row(children: [Expanded(child: _Field(controller: lat, label: 'Latitude')), const SizedBox(width: 10), Expanded(child: _Field(controller: lng, label: 'Longitude'))]),
              _Field(controller: whatsapp, label: 'WhatsApp'),
              _Field(controller: image, label: 'Image URL'),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: saving ? null : save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded), label: Text('common.save'.tr()), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15))),
            ],
          ),
        ),
      );
}

extension _LocalOfferFormCopy on LocalOfferModel {
  LocalOfferModel copyWithFromForm({String? storeId, String? storeName, String? title, String? description, String? image, double? oldPrice, double? newPrice, String? currency, int? discountPercent, String? city, String? countryCode, double? latitude, double? longitude, String? whatsapp, String? status}) => LocalOfferModel(
        id: id,
        storeId: storeId ?? this.storeId,
        storeName: storeName ?? this.storeName,
        title: title ?? this.title,
        description: description ?? this.description,
        image: image ?? this.image,
        category: category,
        oldPrice: oldPrice ?? this.oldPrice,
        newPrice: newPrice ?? this.newPrice,
        currency: currency ?? this.currency,
        discountPercent: discountPercent ?? this.discountPercent,
        city: city ?? this.city,
        countryCode: countryCode ?? this.countryCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        whatsapp: whatsapp ?? this.whatsapp,
        status: status ?? this.status,
        source: source,
        riskLevel: riskLevel,
        riskScore: riskScore,
        views: views,
        clicks: clicks,
        startsAt: startsAt,
        endsAt: endsAt,
        createdAt: createdAt,
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  const _Field({required this.controller, required this.label, this.requiredField = false, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800), decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)), validator: requiredField ? (value) => (value == null || value.trim().isEmpty) ? 'common.required'.tr() : null : null));
}
