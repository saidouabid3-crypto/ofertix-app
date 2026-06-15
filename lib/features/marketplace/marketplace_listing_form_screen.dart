import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/country_service.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_listing_options.dart';

class MarketplaceListingFormScreen extends StatefulWidget {
  final MarketplaceItem? existingItem;

  const MarketplaceListingFormScreen({super.key, this.existingItem});

  @override
  State<MarketplaceListingFormScreen> createState() =>
      _MarketplaceListingFormScreenState();
}

class _MarketplaceListingFormScreenState
    extends State<MarketplaceListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _area = TextEditingController();
  final _approximateLocation = TextEditingController();
  final _picker = ImagePicker();
  final List<_ListingImage> _images = [];

  String _countryCode = 'ES';
  String _currencyCode = 'EUR';
  String _categoryKey = 'other';
  String _conditionKey = 'good';
  String _deliveryMethodKey = 'pickup';
  int _coverIndex = 0;
  bool _customCity = false;
  bool _photosError = false;
  bool _loadingCountry = true;
  bool _saving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _title.text = item.title;
      _description.text = item.description;
      _price.text = item.price.toString();
      _city.text = item.city;
      _postalCode.text = item.postalCode;
      _area.text = item.area;
      _approximateLocation.text = item.approximateLocationLabel;
      _countryCode = item.countryCode.toUpperCase();
      if (!MarketplaceListingOptions.countries.any(
        (country) => country['code'] == _countryCode,
      )) {
        _countryCode = 'OTHER';
      }
      _currencyCode = item.currencyCode;
      _categoryKey =
          MarketplaceListingOptions.categories.contains(item.categoryKey)
          ? item.categoryKey
          : 'other';
      _conditionKey =
          MarketplaceListingOptions.conditions.contains(item.conditionKey)
          ? item.conditionKey
          : 'good';
      _deliveryMethodKey =
          MarketplaceListingOptions.deliveryMethods.contains(
            item.deliveryMethodKey,
          )
          ? item.deliveryMethodKey
          : 'pickup';
      _images.addAll(item.images.map(_ListingImage.remote));
      final cover = _images.indexWhere((image) => image.url == item.coverImage);
      _coverIndex = cover < 0 ? 0 : cover;
      _customCity =
          !(MarketplaceListingOptions.popularCities[_countryCode] ??
                  const <String>[])
              .contains(item.city);
      _loadingCountry = false;
    } else {
      _loadCountry();
    }
  }

  Future<void> _loadCountry() async {
    final country = (await CountryService.instance.getCurrentCountry())
        .toUpperCase();
    final supported = MarketplaceListingOptions.countries.any(
      (entry) => entry['code'] == country,
    );
    if (!mounted) return;
    setState(() {
      _countryCode = supported ? country : 'OTHER';
      _currencyCode = MarketplaceListingOptions.currencyFor(_countryCode);
      _loadingCountry = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _postalCode.dispose();
    _area.dispose();
    _approximateLocation.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 10 - _images.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(
      imageQuality: 82,
      limit: remaining,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _images.addAll(picked.take(remaining).map(_ListingImage.local));
      _photosError = false;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) {
        _coverIndex = 0;
      } else if (index < _coverIndex) {
        _coverIndex--;
      } else if (_coverIndex >= _images.length) {
        _coverIndex = _images.length - 1;
      }
    });
  }

  void _setCover(int index) => setState(() => _coverIndex = index);

  Future<void> _chooseCity() async {
    final cities =
        MarketplaceListingOptions.popularCities[_countryCode] ??
        const <String>[];
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CityPicker(cities: cities),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customCity = selected == _CityPicker.otherValue;
      _city.text = _customCity ? '' : selected;
    });
  }

  void _changeCountry(String? value) {
    if (value == null) return;
    setState(() {
      _countryCode = value;
      _currencyCode = MarketplaceListingOptions.currencyFor(value);
      _city.clear();
      _customCity = value == 'OTHER';
    });
  }

  Future<void> _validateAndPreview() async {
    FocusScope.of(context).unfocus();
    setState(() => _photosError = _images.isEmpty);
    final valid =
        _formKey.currentState?.validate() == true && _images.isNotEmpty;
    if (!valid) return;
    if (kDebugMode) {
      debugPrint('[Sell16A] structured validation passed');
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ListingPreviewDialog(
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: _price.text.trim(),
        currencyCode: _currencyCode,
        city: _city.text.trim(),
        countryCode: _countryCode,
        categoryKey: _categoryKey,
        conditionKey: _conditionKey,
        deliveryMethodKey: _deliveryMethodKey,
        cover: _images[_coverIndex],
        imageCount: _images.length,
      ),
    );
    if (confirmed != true || !mounted) return;
    if (kDebugMode) debugPrint('[Sell16A] preview confirmed');
    await _submit();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }
    setState(() => _saving = true);
    try {
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw StateError('Missing authentication token');
      }
      final uploadedUrls = <String>[];
      for (var index = 0; index < _images.length; index++) {
        final image = _images[index];
        if (image.url != null) {
          uploadedUrls.add(image.url!);
          continue;
        }
        final result = await MarketplaceService.instance.uploadImage(
          image.file!,
          token,
        );
        if (result.url == null) {
          throw StateError(result.error ?? 'UPLOAD_FAILED');
        }
        uploadedUrls.add(result.url!);
        if (kDebugMode) {
          debugPrint(
            '[Sell16A] image uploaded index=${index + 1}/${_images.length}',
          );
        }
      }

      final payload = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'price': double.parse(_price.text.replaceAll(',', '.').trim()),
        'currencyCode': _currencyCode,
        'countryCode': _countryCode,
        'countryName': 'sell16.country.${_countryCode.toLowerCase()}'.tr(),
        'city': _city.text.trim(),
        'postalCode': _postalCode.text.trim(),
        'area': _area.text.trim(),
        'approximateLocationLabel': _approximateLocation.text.trim(),
        'categoryKey': _categoryKey,
        'conditionKey': _conditionKey,
        'deliveryMethodKey': _deliveryMethodKey,
        'images': uploadedUrls,
        'coverImage': uploadedUrls[_coverIndex],
        'imageCount': uploadedUrls.length,
      };

      final MarketplaceItem result;
      if (_isEditing) {
        result = await MarketplaceService.instance.updateMyItem(
          widget.existingItem!.id,
          payload,
        );
      } else {
        result = await MarketplaceService.instance.createItem(
          payload,
          token: token,
        );
        if (kDebugMode) {
          debugPrint(
            '[Sell16A] item created id=${result.id} status=${result.status}',
          );
        }
      }
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'sell16.editFailed'.tr() : 'sell.submitFailed'.tr(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.background
        : AppColors.lightBackground;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(
          _isEditing ? 'sell16.editTitle'.tr() : 'sell16.createTitle'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
          children: [
            _PhotoEditor(
              images: _images,
              coverIndex: _coverIndex,
              hasError: _photosError,
              enabled: !_saving,
              onAdd: _pickImages,
              onRemove: _removeImage,
              onSetCover: _setCover,
            ),
            const SizedBox(height: 18),
            _TextField(
              controller: _title,
              labelKey: 'sell.labelTitle',
              icon: Icons.title_rounded,
              validator: (value) => (value ?? '').trim().length < 3
                  ? 'sell.validatorTitle'.tr()
                  : null,
            ),
            _TextField(
              controller: _description,
              labelKey: 'sell.labelDescription',
              icon: Icons.description_rounded,
              maxLines: 4,
              validator: (value) => (value ?? '').trim().length < 8
                  ? 'sell.validatorDescription'.tr()
                  : null,
            ),
            _TextField(
              controller: _price,
              labelKey: 'sell16.price',
              labelArgs: {'currency': _currencyCode},
              icon: Icons.payments_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  (double.tryParse((value ?? '').replaceAll(',', '.').trim()) ??
                          0) <=
                      0
                  ? 'sell.validatorPrice'.tr()
                  : null,
            ),
            _Dropdown(
              value: _countryCode,
              labelKey: 'sell16.country',
              icon: Icons.public_rounded,
              values: MarketplaceListingOptions.countries
                  .map((country) => country['code']!)
                  .toList(),
              labelFor: (value) => 'sell16.country.${value.toLowerCase()}'.tr(),
              onChanged: _saving ? null : _changeCountry,
            ),
            _TextField(
              controller: _city,
              labelKey: 'sell.labelCity',
              icon: Icons.location_city_rounded,
              readOnly: !_customCity,
              onTap: _customCity ? null : _chooseCity,
              suffixIcon: IconButton(
                onPressed: _saving ? null : _chooseCity,
                icon: const Icon(Icons.search_rounded),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'sell16.cityRequired'.tr()
                  : null,
            ),
            Row(
              children: [
                Expanded(
                  child: _TextField(
                    controller: _postalCode,
                    labelKey: 'sell16.postalCode',
                    icon: Icons.markunread_mailbox_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TextField(
                    controller: _area,
                    labelKey: 'sell16.area',
                    icon: Icons.map_outlined,
                  ),
                ),
              ],
            ),
            _TextField(
              controller: _approximateLocation,
              labelKey: 'sell16.approximateLocation',
              icon: Icons.near_me_outlined,
            ),
            _Dropdown(
              value: _categoryKey,
              labelKey: 'sell.labelCategory',
              icon: Icons.category_rounded,
              values: MarketplaceListingOptions.categories,
              labelFor: (value) => 'sell16.category.$value'.tr(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _categoryKey = value!),
            ),
            _Dropdown(
              value: _conditionKey,
              labelKey: 'sell16.condition',
              icon: Icons.verified_rounded,
              values: MarketplaceListingOptions.conditions,
              labelFor: (value) => 'sell16.condition.$value'.tr(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _conditionKey = value!),
            ),
            _Dropdown(
              value: _deliveryMethodKey,
              labelKey: 'sell16.delivery',
              icon: Icons.local_shipping_outlined,
              values: MarketplaceListingOptions.deliveryMethods,
              labelFor: (value) => 'sell16.delivery.$value'.tr(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _deliveryMethodKey = value!),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving || _loadingCountry
                  ? null
                  : _validateAndPreview,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.preview_rounded),
              label: Text(
                _saving ? 'sell.submittingListing'.tr() : 'sell16.preview'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'sell.sentForReviewSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage {
  final String? url;
  final XFile? file;

  const _ListingImage._({this.url, this.file});

  factory _ListingImage.remote(String url) => _ListingImage._(url: url);
  factory _ListingImage.local(XFile file) => _ListingImage._(file: file);

  ImageProvider get provider =>
      url != null ? NetworkImage(url!) : FileImage(File(file!.path));
}

class _PhotoEditor extends StatelessWidget {
  final List<_ListingImage> images;
  final int coverIndex;
  final bool hasError;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSetCover;

  const _PhotoEditor({
    required this.images,
    required this.coverIndex,
    required this.hasError,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_rounded, color: AppColors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'sell.addPhotos'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text('${images.length}/10'),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'sell.photosRequired'.tr(),
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (images.length < 10)
                InkWell(
                  onTap: enabled ? onAdd : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError ? AppColors.red : AppColors.orange,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ...List.generate(images.length, (index) {
                final cover = index == coverIndex;
                return GestureDetector(
                  onTap: enabled ? () => onSetCover(index) : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 106,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cover
                                ? AppColors.orange
                                : Colors.transparent,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: images[index].provider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (cover)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: _PhotoBadge(label: 'sell.coverPhoto'.tr()),
                        ),
                      if (!cover)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: _PhotoBadge(label: 'sell16.setCover'.tr()),
                        ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          onPressed: enabled ? () => onRemove(index) : null,
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  final String label;

  const _PhotoBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelKey;
  final Map<String, String>? labelArgs;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _TextField({
    required this.controller,
    required this.labelKey,
    required this.icon,
    this.labelArgs,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        labelText: labelKey.tr(namedArgs: labelArgs),
      ),
    ),
  );
}

class _Dropdown extends StatelessWidget {
  final String value;
  final String labelKey;
  final IconData icon;
  final List<String> values;
  final String Function(String) labelFor;
  final ValueChanged<String?>? onChanged;

  const _Dropdown({
    required this.value,
    required this.labelKey,
    required this.icon,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: labelKey.tr(),
      ),
      items: values
          .map(
            (entry) =>
                DropdownMenuItem(value: entry, child: Text(labelFor(entry))),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

class _CityPicker extends StatefulWidget {
  static const otherValue = '__other__';
  final List<String> cities;

  const _CityPicker({required this.cities});

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.cities
        .where((city) => city.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText: 'sell16.searchCity'.tr(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ...filtered.map(
                  (city) => ListTile(
                    leading: const Icon(Icons.location_city_rounded),
                    title: Text(city),
                    onTap: () => Navigator.pop(context, city),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_location_alt_outlined),
                  title: Text('sell16.otherCity'.tr()),
                  onTap: () => Navigator.pop(context, _CityPicker.otherValue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingPreviewDialog extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final String city;
  final String countryCode;
  final String categoryKey;
  final String conditionKey;
  final String deliveryMethodKey;
  final _ListingImage cover;
  final int imageCount;

  const _ListingPreviewDialog({
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.city,
    required this.countryCode,
    required this.categoryKey,
    required this.conditionKey,
    required this.deliveryMethodKey,
    required this.cover,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('sell16.previewTitle'.tr()),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image(image: cover.provider, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text('$price $currencyCode'),
            const SizedBox(height: 8),
            Text('$city, $countryCode'),
            Text('sell16.category.$categoryKey'.tr()),
            Text('sell16.condition.$conditionKey'.tr()),
            Text('sell16.delivery.$deliveryMethodKey'.tr()),
            Text('sell16.photoCount'.tr(args: ['$imageCount'])),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 12),
            Text(
              'sell.sentForReviewSubtitle'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('common.cancel'.tr()),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('sell16.confirmSubmit'.tr()),
      ),
    ],
  );
}
