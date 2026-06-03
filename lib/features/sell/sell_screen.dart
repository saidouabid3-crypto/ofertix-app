import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_item.dart';
import '../../models/ofertix_ad_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/country_service.dart';
import '../../widgets/pro_max/ofertix_logo_mark.dart';
import '../../widgets/ofertix_ad_slot.dart';

class SellScreen extends StatefulWidget {
  SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final MarketplaceService _service = MarketplaceService.instance;
  late Future<List<MarketplaceItem>> _future;
  String _countryCode = 'global';

  @override
  void initState() {
    super.initState();
    _future = _loadItems();
  }

  Future<List<MarketplaceItem>> _loadItems() async {
    final country = await CountryService.instance.getCurrentCountry();
    final normalizedCountry = country.trim().isEmpty
        ? 'global'
        : country.trim().toLowerCase();

    if (mounted && _countryCode != normalizedCountry) {
      setState(() => _countryCode = normalizedCountry);
    }

    return _service.fetchItems(limit: 20, countryCode: normalizedCountry);
  }

  Future<void> _reload() async {
    setState(() => _future = _loadItems());
    await _future;
  }

  Future<void> _openAddItem() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddMarketplaceItemScreen()),
    );
    if (created == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Scaffold(
      backgroundColor: ui.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddItem,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_business_rounded),
        label: Text('auto.sell_sell_screen.vender'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.orange,
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                OfertixLogoMark(subtitle: 'Marketplace real'),
                SizedBox(height: 18),
                _SellerHero(onAdd: _openAddItem),
                SizedBox(height: 16),
                OfertixAdSlot(placement: OfertixAdPlacement.sellTop),
                SizedBox(height: 22),
                _SectionTitle(
                  title: 'Marketplace Ofertix',
                  subtitle: _countryCode == 'global'
                      ? 'sell.marketplaceSubtitleGlobal'.tr()
                      : 'Solo anuncios disponibles para ${_countryCode.toUpperCase()}',
                ),
                SizedBox(height: 12),
                FutureBuilder<List<MarketplaceItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.orange,
                          ),
                        ),
                      );
                    }
                    final items = snapshot.data ?? const <MarketplaceItem>[];
                    if (items.isEmpty) return _EmptyMarketplace();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .66,
                      ),
                      itemBuilder: (_, index) =>
                          _MarketplaceCard(item: items[index]),
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
  final _imageUrl = TextEditingController();
  String _condition = 'used_good';
  bool _pickupOnly = true;
  String _sellerCountryCode = 'global';
  String _currency = 'EUR';
  bool _loadingCountry = true;
  bool _saving = false;

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
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    if (_loadingCountry) {
      await _loadSellerCountry();
    }

    final user = FirebaseAuth.instance.currentUser;
    final sellerCountry = _sellerCountryCode == 'global'
        ? 'es'
        : _sellerCountryCode;
    final availableCountries = <String>[sellerCountry];
    final shipsTo = _pickupOnly ? <String>[] : <String>[sellerCountry];

    final item = MarketplaceItem(
      id: '',
      sellerId: user?.uid ?? 'guest_seller',
      sellerName: user?.displayName ?? user?.email ?? 'Vendedor Ofertix',
      title: _title.text.trim(),
      description: _description.text.trim(),
      price: double.tryParse(_price.text.replaceAll(',', '.').trim()) ?? 0,
      currency: _currency,
      city: _city.text.trim(),
      country: sellerCountry,
      sellerCountryCode: sellerCountry,
      availableCountries: availableCountries,
      shipsTo: shipsTo,
      pickupOnly: _pickupOnly,
      condition: _condition,
      images: _imageUrl.text.trim().isEmpty ? [] : [_imageUrl.text.trim()],
      category: _category.text.trim(),
      isActive: true,
      isFeatured: false,
      isSponsored: false,
      views: 0,
      favorites: 0,
      createdAt: DateTime.now(),
    );
    try {
      await MarketplaceService.instance.createItem(item);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.sell_sell_screen.producto_publicado_en_ofertix'.tr(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error publicando producto: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
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
              padding: EdgeInsets.fromLTRB(18, 12, 18, 120),
              children: [
                _FormHero(),
                SizedBox(height: 16),
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
                  label: 'sell.labelPrice'.tr(namedArgs: {'currency': _currency}),
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
                    SizedBox(width: 12),
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
                SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _pickupOnly,
                  onChanged: (value) => setState(() => _pickupOnly = value),
                  activeThumbColor: AppColors.orange,
                  title: Text('auto.sell_sell_screen.solo_entrega_local_recogida'.tr(),
                  ),
                  subtitle: Text(
                    _pickupOnly
                        ? 'Este anuncio solo se mostrará en ${_sellerCountryCode.toUpperCase()}'
                        : 'Se mostrará en ${_sellerCountryCode.toUpperCase()} y países de envío configurados',
                  ),
                ),
                SizedBox(height: 12),
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
                      child: Text('auto.sell_sell_screen.usado_buen_estado'.tr(),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'used_fair',
                      child: Text('auto.sell_sell_screen.usado_aceptable'.tr()),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _condition = v ?? 'used_good'),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.verified_rounded),
                    labelText: 'auto.sell_sell_screen.estado'.tr(),
                  ),
                ),
                SizedBox(height: 12),
                _Field(
                  controller: _imageUrl,
                  label: 'Imagen URL (temporal hasta Cloudinary)',
                  icon: Icons.image_rounded,
                ),
                SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.publish_rounded),
                  label: Text(_saving ? 'sell.publishing'.tr() : 'sell.publishProduct'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _SellerHero extends StatelessWidget {
  final VoidCallback onAdd;
  _SellerHero({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: .25),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('auto.sell_sell_screen.vende_en_ofertix'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text('auto.sell_sell_screen.publica_productos_recibe_mensajes_y_cr'.tr()
                      .tr(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  final MarketplaceItem item;
  _MarketplaceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ui = _SellUi.of(context);
    return Container(
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
                SizedBox(height: 4),
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
    );
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
          Text('auto.sell_sell_screen.aun_no_hay_productos'.tr(),
            style: TextStyle(
              color: ui.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text('auto.sell_sell_screen.se_el_primero_en_vender_algo_en_oferti'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: ui.muted, fontWeight: FontWeight.w700),
          ),
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
                Text('auto.sell_sell_screen.nuevo_anuncio'.tr(),
                  style: TextStyle(
                    color: ui.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text('auto.sell_sell_screen.backend_render_primero_firebase_fallba'.tr()
                      .tr(),
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
