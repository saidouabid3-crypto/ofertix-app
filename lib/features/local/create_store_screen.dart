import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/local_store_model.dart';
import '../../providers/local_engine_provider.dart';

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final category = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController(text: 'Barcelona');
  final country = TextEditingController(text: 'es');
  final lat = TextEditingController();
  final lng = TextEditingController();
  final whatsapp = TextEditingController();
  final website = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    category.dispose();
    address.dispose();
    city.dispose();
    country.dispose();
    lat.dispose();
    lng.dispose();
    whatsapp.dispose();
    website.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final store = LocalStoreModel.empty().copyWith(
      name: name.text.trim(),
      description: description.text.trim(),
      category: category.text.trim().isEmpty ? 'general' : category.text.trim(),
      address: address.text.trim(),
      city: city.text.trim(),
      countryCode: country.text.trim().toLowerCase(),
      latitude: double.tryParse(lat.text.trim().replaceAll(',', '.')) ?? 0,
      longitude: double.tryParse(lng.text.trim().replaceAll(',', '.')) ?? 0,
      whatsapp: whatsapp.text.trim(),
      website: website.text.trim(),
      active: true,
    );
    try {
      await LocalEngineProvider().createStore(store);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('local.storeSubmitted'.tr())));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocalEngineProvider(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, title: Text('local.addStore'.tr(), style: const TextStyle(fontWeight: FontWeight.w900))),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _Field(controller: name, label: 'local.storeName'.tr(), requiredField: true),
              _Field(controller: description, label: 'common.description'.tr(), maxLines: 3),
              _Field(controller: category, label: 'common.category'.tr()),
              _Field(controller: address, label: 'local.address'.tr(), requiredField: true),
              Row(children: [Expanded(child: _Field(controller: city, label: 'common.city'.tr(), requiredField: true)), const SizedBox(width: 10), Expanded(child: _Field(controller: country, label: 'common.country'.tr(), requiredField: true))]),
              Row(children: [Expanded(child: _Field(controller: lat, label: 'Latitude')), const SizedBox(width: 10), Expanded(child: _Field(controller: lng, label: 'Longitude'))]),
              _Field(controller: whatsapp, label: 'WhatsApp'),
              _Field(controller: website, label: 'Website'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: saving ? null : save,
                icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
                label: Text('common.save'.tr()),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  const _Field({required this.controller, required this.label, this.requiredField = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
          validator: requiredField ? (value) => (value == null || value.trim().isEmpty) ? 'common.required'.tr() : null : null,
        ),
      );
}
