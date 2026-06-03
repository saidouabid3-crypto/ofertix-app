import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/coupon_model.dart';
import '../../services/community_service.dart';
import '../../services/coupon_service.dart';
import '../../widgets/coupon_ticket_card.dart';

class CouponsScreen extends StatefulWidget {
  CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _service = CouponService.instance;
  final _community = CommunityService.instance;

  bool loading = true;
  List<CouponModel> coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final items = await _service.listCoupons();
      if (!mounted) return;
      setState(() => coupons = items);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verify(CouponModel coupon, bool works) async {
    try {
      await _service.verifyCoupon(couponId: coupon.id, works: works);
      await _community.vote(
        targetType: 'coupon',
        targetId: coupon.id,
        vote: works ? 'hot' : 'cold',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
        title: Text('auto.coupons_coupons_screen.coupons'.tr()),
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCoupon,
        icon: Icon(Icons.add_rounded),
        label: Text('auto.coupons_coupons_screen.add_coupon'.tr()),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: coupons.isEmpty
                  ? Center(
                      child: Text('auto.coupons_coupons_screen.no_coupons_yet'.tr(),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        return CouponTicketCard(
                          coupon: coupon,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: coupon.code),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('auto.coupons_coupons_screen.coupon_copied'.tr()
                                      .tr(),
                                ),
                              ),
                            );
                          },
                          onWorks: () => _verify(coupon, true),
                          onFails: () => _verify(coupon, false),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _openCreateCoupon() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateCouponSheet(),
    );
    if (created == true) _load();
  }
}

class _CreateCouponSheet extends StatefulWidget {
  _CreateCouponSheet();

  @override
  State<_CreateCouponSheet> createState() => _CreateCouponSheetState();
}

class _CreateCouponSheetState extends State<_CreateCouponSheet> {
  final title = TextEditingController();
  final code = TextEditingController();
  final store = TextEditingController();
  final discount = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    title.dispose();
    code.dispose();
    store.dispose();
    discount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await CouponService.instance.createCoupon(
        title: title.text,
        code: code.text,
        store: store.text,
        discountLabel: discount.text,
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
            Text('auto.coupons_coupons_screen.add_coupon'.tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 14),
            TextField(
              controller: title,
              decoration: InputDecoration(
                labelText: 'auto.coupons_coupons_screen.title'.tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: code,
              decoration: InputDecoration(
                labelText: 'auto.coupons_coupons_screen.code'.tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: store,
              decoration: InputDecoration(
                labelText: 'auto.coupons_coupons_screen.store'.tr(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: discount,
              decoration: InputDecoration(
                labelText: 'auto.coupons_coupons_screen.discount_label'.tr(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Saving...' : 'Save coupon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
