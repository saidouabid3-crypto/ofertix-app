import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_generated_deal_model.dart';
import '../../services/user_deal_service.dart';

class UserGeneratedDealsScreen extends StatefulWidget {
  UserGeneratedDealsScreen({super.key});

  @override
  State<UserGeneratedDealsScreen> createState() =>
      _UserGeneratedDealsScreenState();
}

class _UserGeneratedDealsScreenState extends State<UserGeneratedDealsScreen> {
  bool loading = true;
  List<UserGeneratedDealModel> deals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final items = await UserDealService.instance.listDeals();
      if (!mounted) return;
      setState(() => deals = items);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('auto.community_user_generated_deals_screen.community_deals'.tr(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDeal,
        icon: Icon(Icons.add_a_photo_rounded),
        label: Text('auto.community_user_generated_deals_screen.upload_deal'.tr(),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: deals.isEmpty
                  ? Center(
                      child: Text('auto.community_user_generated_deals_screen.no_community_deals_yet'.tr()
                            .tr(),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: deals.length,
                      itemBuilder: (context, index) =>
                          _DealCard(deal: deals[index]),
                    ),
            ),
    );
  }

  Future<void> _openCreateDeal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateDealSheet(),
    );
    if (created == true) _load();
  }
}

class _DealCard extends StatelessWidget {
  final UserGeneratedDealModel deal;

  _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${deal.rewardPoints} pts',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '${deal.store} · ${deal.city}',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            '${deal.currentPrice.toStringAsFixed(2)} ${deal.currency}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Status: ${deal.status} · Hot ${deal.hotScore}°',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CreateDealSheet extends StatefulWidget {
  _CreateDealSheet();

  @override
  State<_CreateDealSheet> createState() => _CreateDealSheetState();
}

class _CreateDealSheetState extends State<_CreateDealSheet> {
  final title = TextEditingController();
  final store = TextEditingController();
  final price = TextEditingController();
  final oldPrice = TextEditingController();
  final city = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    store.dispose();
    price.dispose();
    oldPrice.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = double.tryParse(price.text.replaceAll(',', '.'));
    final old = double.tryParse(oldPrice.text.replaceAll(',', '.'));
    if (current == null || current <= 0) return;
    setState(() => saving = true);
    try {
      await UserDealService.instance.createDeal(
        title: title.text,
        store: store.text,
        currentPrice: current,
        oldPrice: old,
        city: city.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('auto.community_user_generated_deals_screen.upload_local_deal'.tr()
                  .tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 14),
            TextField(
              controller: title,
              decoration: InputDecoration(
                labelText: 'auto.community_user_generated_deals_screen.title'.tr()
                    .tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: store,
              decoration: InputDecoration(
                labelText: 'auto.community_user_generated_deals_screen.store'.tr()
                    .tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'auto.community_user_generated_deals_screen.price'.tr()
                    .tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: oldPrice,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'auto.community_user_generated_deals_screen.old_price'.tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: city,
              decoration: InputDecoration(
                labelText: 'auto.community_user_generated_deals_screen.city'.tr()
                    .tr(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
