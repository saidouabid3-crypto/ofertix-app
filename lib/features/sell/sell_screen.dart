import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import '../../services/country_service.dart';
import '../../services/profile_service.dart';
import '../profile/creator_profile_screen.dart';
import '../marketplace/marketplace_item_detail_screen.dart';
import '../marketplace/marketplace_my_listings_screen.dart';
import '../marketplace/marketplace_messages_screen.dart';

class SellScreen extends StatefulWidget {
  SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  late Future<List<MarketplaceItem>> _future;
  String _countryCode = 'global';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('[SellFlowVersion] 15C-D');
    _future = _loadItems();
  }

  Future<List<MarketplaceItem>> _loadItems() async {
    final country = await CountryService.instance.getCurrentCountry();
    final normalized = country.trim().isEmpty
        ? 'global'
        : country.trim().toLowerCase();
    if (mounted && _countryCode != normalized) {
      setState(() => _countryCode = normalized);
    }
    return MarketplaceService.instance.fetchItems(
      limit: 20,
      countryCode: normalized,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _loadItems());
    await _future;
  }

  Future<void> _openAddItem() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }
    final itemId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => AddMarketplaceItemScreen()),
    );
    if (!mounted || itemId == null || itemId.isEmpty) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('sell.sentForReview'.tr()),
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.green,
        action: SnackBarAction(
          label: 'marketplace.myListings'.tr(),
          textColor: Colors.white,
          onPressed: _openMyListings,
        ),
      ),
    );
  }

  void _openMyListings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MarketplaceMyListingsScreen()),
  );

  void _openMessages() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MarketplaceMessagesScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Scaffold(
      backgroundColor: ui.background,
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.orange,
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // ── Compact header ──────────────────────────────────────
                _MarketplaceHeader(ui: ui),
                const SizedBox(height: 18),
                // ── Action tiles: Vender / Mis anuncios / Mensajes ──────
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.add_business_rounded,
                        label: 'marketplace.sell'.tr(),
                        onTap: _openAddItem,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.list_alt_rounded,
                        label: 'marketplace.myListings'.tr(),
                        onTap: _openMyListings,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'marketplace.messages'.tr(),
                        onTap: _openMessages,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // ── Section header ───────────────────────────────────────
                _SectionTitle(
                  title: 'marketplace.availableListings'.tr(),
                  subtitle: _countryCode == 'global'
                      ? ''
                      : _countryCode.toUpperCase(),
                ),
                const SizedBox(height: 12),
                // ── Public listings grid ─────────────────────────────────
                FutureBuilder<List<MarketplaceItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _MarketplaceLoadError(onRetry: _reload);
                    }
                    final items = snapshot.data ?? const <MarketplaceItem>[];
                    if (items.isEmpty) return _EmptyMarketplace();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .72,
                          ),
                      itemBuilder: (_, i) => _MarketplaceCard(item: items[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddMarketplaceItemScreen extends StatefulWidget {
  AddMarketplaceItemScreen({super.key});

  @override
  State<AddMarketplaceItemScreen> createState() =>
      _AddMarketplaceItemScreenState();
}

class _AddMarketplaceItemScreenState extends State<AddMarketplaceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController(text: 'Barcelona');
  final _category = TextEditingController(text: 'General');
  final _picker = ImagePicker();

  final List<XFile> _selectedImages = [];
  bool _photosError = false;

  String _condition = 'used_good';
  bool _pickupOnly = true;
  String _sellerCountryCode = 'global';
  String _currency = 'EUR';
  bool _loadingCountry = true;
  bool _saving = false;
  bool _uploadingImages = false;

  @override
  void initState() {
    super.initState();
    _loadSellerCountry();
  }

  Future<void> _loadSellerCountry() async {
    final country = await CountryService.instance.getCurrentCountry();
    final normalized = country.trim().isEmpty
        ? 'global'
        : country.trim().toLowerCase();

    if (!mounted) return;
    setState(() {
      _sellerCountryCode = normalized == 'global' ? 'es' : normalized;
      _currency = CountryService.instance.getCountryCurrency(
        _sellerCountryCode,
      );
      _loadingCountry = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: 6);
    if (picked.isEmpty) return;
    setState(() {
      final remaining = 6 - _selectedImages.length;
      _selectedImages.addAll(picked.take(remaining));
      _photosError = false;
    });
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _photosError = _selectedImages.isEmpty);
    if (_selectedImages.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    if (kDebugMode) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'not-authenticated';
      debugPrint(
        '[SellSubmit] start  images=${_selectedImages.length}  user=$uid',
      );
    }
    setState(() => _saving = true);

    if (_loadingCountry) await _loadSellerCountry();
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }

    // Upload images through backend
    setState(() => _uploadingImages = true);
    String? token;
    try {
      token = await user.getIdToken();
    } catch (_) {}

    if (token == null) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _uploadingImages = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }

    final imageUrls = <String>[];
    for (final xFile in _selectedImages) {
      final result = await MarketplaceService.instance.uploadImage(
        xFile,
        token,
      );
      if (result.url == null) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _uploadingImages = false;
        });
        final msgKey = result.error == 'IMAGE_TOO_LARGE'
            ? 'sell.imageTooLarge'
            : 'sell.imageUploadFailed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msgKey.tr())));
        return;
      }
      imageUrls.add(result.url!);
    }
    setState(() => _uploadingImages = false);
    if (kDebugMode && imageUrls.isNotEmpty) {
      debugPrint(
        '[SellUpload] parsedUrl=${imageUrls.first}  total=${imageUrls.length}',
      );
    }

    final sellerProfile = await ProfileService.instance.getCurrentProfile();
    final sellerCountry = _sellerCountryCode == 'global'
        ? 'es'
        : _sellerCountryCode;

    final item = MarketplaceItem(
      id: '',
      sellerId: user.uid,
      sellerName: sellerProfile?.displayName.trim().isNotEmpty == true
          ? sellerProfile!.displayName.trim()
          : user.displayName ?? '',
      sellerUsername: sellerProfile?.username ?? '',
      sellerAvatarUrl: sellerProfile?.photoUrl ?? '',
      sellerVerified:
          sellerProfile?.sellerVerified == true ||
          sellerProfile?.isVerified == true,
      title: _title.text.trim(),
      description: _description.text.trim(),
      price: double.tryParse(_price.text.replaceAll(',', '.').trim()) ?? 0,
      currency: _currency,
      city: _city.text.trim(),
      country: sellerCountry,
      sellerCountryCode: sellerCountry,
      availableCountries: [sellerCountry],
      shipsTo: _pickupOnly ? [] : [sellerCountry],
      pickupOnly: _pickupOnly,
      condition: _condition,
      images: imageUrls,
      category: _category.text.trim(),
      isActive: false,
      isFeatured: false,
      isSponsored: false,
      views: 0,
      favorites: 0,
      createdAt: DateTime.now(),
    );

    try {
      final itemId = await MarketplaceService.instance.createItem(
        item,
        token: token,
      );
      if (kDebugMode) {
        debugPrint(
          '[SellSubmit] success  id=$itemId  status=pending  isActive=false  visibleToUsers=false',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, itemId);
    } catch (e) {
      if (kDebugMode) debugPrint('[SellSubmit] failed  error=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('sell.submitFailed'.tr())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    final isSubmitting = _saving || _uploadingImages;
    return Scaffold(
      backgroundColor: ui.background,
      appBar: AppBar(
        title: Text('auto.sell_sell_screen.vender_producto'.tr()),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
              children: [
                _FormHero(),
                const SizedBox(height: 16),
                _ImagePickerSection(
                  images: _selectedImages,
                  hasError: _photosError,
                  onAdd: isSubmitting ? null : _pickImages,
                  onRemove: isSubmitting ? null : _removeImage,
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _title,
                  label: 'sell.labelTitle'.tr(),
                  icon: Icons.title_rounded,
                  validator: (v) => v == null || v.trim().length < 3
                      ? 'sell.validatorTitle'.tr()
                      : null,
                ),
                _Field(
                  controller: _description,
                  label: 'sell.labelDescription'.tr(),
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().length < 8
                      ? 'sell.validatorDescription'.tr()
                      : null,
                ),
                _Field(
                  controller: _price,
                  label: 'sell.labelPrice'.tr(
                    namedArgs: {'currency': _currency},
                  ),
                  icon: Icons.euro_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <=
                          0
                      ? 'sell.validatorPrice'.tr()
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _city,
                        label: 'sell.labelCity'.tr(),
                        icon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _category,
                        label: 'sell.labelCategory'.tr(),
                        icon: Icons.category_rounded,
                      ),
                    ),
                  ],
                ),
                _CountryNotice(
                  countryCode: _sellerCountryCode,
                  currency: _currency,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _pickupOnly,
                  onChanged: isSubmitting
                      ? null
                      : (value) => setState(() => _pickupOnly = value),
                  activeThumbColor: AppColors.orange,
                  title: Text(
                    'auto.sell_sell_screen.solo_entrega_local_recogida'.tr(),
                  ),
                  subtitle: Text(
                    _pickupOnly
                        ? 'Este anuncio solo se mostrará en ${_sellerCountryCode.toUpperCase()}'
                        : 'Se mostrará en ${_sellerCountryCode.toUpperCase()} y países de envío configurados',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  items: [
                    DropdownMenuItem(
                      value: 'new',
                      child: Text('auto.sell_sell_screen.nuevo'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'used_like_new',
                      child: Text('auto.sell_sell_screen.como_nuevo'.tr()),
                    ),
                    DropdownMenuItem(
                      value: 'used_good',
                      child: Text(
                        'auto.sell_sell_screen.usado_buen_estado'.tr(),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'used_fair',
                      child: Text('auto.sell_sell_screen.usado_aceptable'.tr()),
                    ),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (v) => setState(() => _condition = v ?? 'used_good'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.verified_rounded),
                    labelText: 'auto.sell_sell_screen.estado'.tr(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _save,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _uploadingImages
                        ? 'sell.uploadingPhotos'.tr()
                        : _saving
                        ? 'sell.submittingListing'.tr()
                        : 'sell.submitListing'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                _PendingReviewNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Image picker grid ─────────────────────────────────────────────────────────

class _ImagePickerSection extends StatelessWidget {
  final List<XFile> images;
  final bool hasError;
  final VoidCallback? onAdd;
  final void Function(int index)? onRemove;

  const _ImagePickerSection({
    required this.images,
    required this.hasError,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_rounded,
              color: AppColors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'sell.addPhotos'.tr(),
              style: TextStyle(
                color: ui.text,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${images.length}/6)',
              style: TextStyle(color: ui.muted, fontSize: 13),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            'sell.photosRequired'.tr(),
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (images.length < 6)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError
                            ? Colors.red
                            : AppColors.orange.withValues(alpha: .40),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.orange,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'sell.addPhotos'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...List.generate(images.length, (i) {
                final isCover = i == 0;
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isCover
                            ? Border.all(color: AppColors.orange, width: 2)
                            : null,
                        image: DecorationImage(
                          image: FileImage(File(images[i].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isCover)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'sell.coverPhoto'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: onRemove != null ? () => onRemove!(i) : null,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pending review notice ─────────────────────────────────────────────────────

class _PendingReviewNotice extends StatelessWidget {
  const _PendingReviewNotice();

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'sell.sentForReviewSubtitle'.tr(),
              style: TextStyle(
                color: ui.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SellUi {
  final Color background;
  final Color text;
  final Color muted;
  final Color card;
  final Color border;
  final LinearGradient gradient;

  _SellUi({
    required this.background,
    required this.text,
    required this.muted,
    required this.card,
    required this.border,
    required this.gradient,
  });

  factory _SellUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SellUi(
      background: isDark ? AppColors.background : AppColors.lightBackground,
      text: isDark ? AppColors.white : AppColors.lightText,
      muted: isDark ? AppColors.gray : AppColors.lightGray,
      card: isDark ? AppColors.card : AppColors.lightCard,
      border: isDark ? Colors.white12 : AppColors.lightBorder,
      gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
    );
  }
}

// ── Marketplace hub widgets ───────────────────────────────────────────────────

class _MarketplaceHeader extends StatelessWidget {
  final _SellUi ui;
  const _MarketplaceHeader({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'marketplace.title'.tr(),
              style: TextStyle(
                color: ui.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'marketplace.subtitle'.tr(),
              style: TextStyle(
                color: ui.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: ui.card.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ui.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ui.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  final MarketplaceItem item;
  const _MarketplaceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketplaceItemDetailScreen(item: item),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ui.card.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ui.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.orange.withValues(alpha: .10),
                child: item.hasImage
                    ? Image.network(
                        item.mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.shopping_bag_rounded,
                          color: AppColors.orange,
                          size: 44,
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.orange,
                        size: 44,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ui.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    item.formattedPrice,
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  _SellerLine(item: item),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.green,
                        size: 14,
                      ),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.city.isEmpty ? 'España' : item.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ui.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // Container (child of GestureDetector)
    ); // GestureDetector
  }
}

class _EmptyMarketplace extends StatelessWidget {
  _EmptyMarketplace();

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ui.card.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ui.border),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_rounded, color: AppColors.orange, size: 46),
          SizedBox(height: 12),
          Text(
            'auto.sell_sell_screen.aun_no_hay_productos'.tr(),
            style: TextStyle(
              color: ui.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'auto.sell_sell_screen.se_el_primero_en_vender_algo_en_oferti'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: ui.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceLoadError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _MarketplaceLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: ui.muted, size: 42),
          const SizedBox(height: 10),
          Text(
            'marketplace.listingUnavailable'.tr(),
            style: TextStyle(color: ui.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
        ],
      ),
    );
  }
}

class _SellerLine extends StatelessWidget {
  const _SellerLine({required this.item});

  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    final name = item.sellerName.trim().isNotEmpty
        ? item.sellerName.trim()
        : 'profile.sellerUnavailable'.tr();

    return InkWell(
      onTap: item.sellerId.trim().isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatorProfileScreen(
                    creatorId: item.sellerId,
                    baseUrl: ApiConfig.baseUrl,
                  ),
                ),
              );
            },
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.orange.withValues(alpha: .22),
            backgroundImage: item.sellerAvatarUrl.startsWith('http')
                ? NetworkImage(item.sellerAvatarUrl)
                : null,
            child: item.sellerAvatarUrl.startsWith('http')
                ? null
                : Icon(Icons.person_rounded, size: 13, color: ui.muted),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              item.sellerUsername.trim().isNotEmpty
                  ? '@${item.sellerUsername.trim()}'
                  : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ui.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (item.sellerVerified)
            Icon(Icons.verified_rounded, color: AppColors.orange, size: 14),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: ui.text,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: ui.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FormHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ui.card.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ui.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.add_business_rounded, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auto.sell_sell_screen.nuevo_anuncio'.tr(),
                  style: TextStyle(
                    color: ui.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'sell.listingFormSubtitle'.tr(),
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryNotice extends StatelessWidget {
  _CountryNotice({required this.countryCode, required this.currency});

  final String countryCode;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.public_rounded, color: AppColors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Marketplace protegido por país: este producto se publica para ${countryCode.toUpperCase()} con moneda $currency.',
              style: TextStyle(
                color: ui.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }
}
