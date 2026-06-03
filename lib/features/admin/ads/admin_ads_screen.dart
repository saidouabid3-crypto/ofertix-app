import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ofertix_ad_model.dart';
import '../../../services/admin_ads_service.dart';
import 'admin_ad_form_screen.dart';

class AdminAdsScreen extends StatelessWidget {
  AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('auto.admin_ads_admin_ads_screen.ads_manager'.tr()),
          bottom: TabBar(
            indicatorColor: AppColors.orange,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.gray,
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'Sell'),
              Tab(text: 'Reels'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdsPlacementList(placement: OfertixAdPlacement.homeTop),
            _AdsPlacementList(placement: OfertixAdPlacement.sellTop),
            _AdsPlacementList(placement: OfertixAdPlacement.reelsVideo),
          ],
        ),
      ),
    );
  }
}

class _AdsPlacementList extends StatelessWidget {
  _AdsPlacementList({required this.placement});

  final OfertixAdPlacement placement;

  @override
  Widget build(BuildContext context) {
    final service = AdminAdsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  AdminAdFormScreen(initialAd: OfertixAdModel.empty(placement)),
            ),
          );
        },
        icon: Icon(Icons.add_rounded),
        label: Text('auto.admin_ads_admin_ads_screen.crear_anuncio'.tr()),
      ),
      body: StreamBuilder<List<OfertixAdModel>>(
        stream: service.watchAds(placement: placement),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          if (snapshot.hasError) {
            return _StatePanel(
              icon: Icons.error_outline_rounded,
              title: 'adsManager.loadErrorTitle'.tr(),
              text: snapshot.error.toString(),
            );
          }

          final ads = snapshot.data ?? const <OfertixAdModel>[];
          if (ads.isEmpty) {
            return _StatePanel(
              icon: Icons.campaign_outlined,
              title: 'adsManager.noAdsTitle'.tr(),
              text:
                  'Create the first ${OfertixAdModel.placementLabel(placement)} ad from this admin panel.',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 110),
            itemCount: ads.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) => _AdAdminCard(ad: ads[index]),
          );
        },
      ),
    );
  }
}

class _AdAdminCard extends StatefulWidget {
  _AdAdminCard({required this.ad});

  final OfertixAdModel ad;

  @override
  State<_AdAdminCard> createState() => _AdAdminCardState();
}

class _AdAdminCardState extends State<_AdAdminCard> {
  final _service = AdminAdsService.instance;
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      await _service.setActive(widget.ad.id, value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auto.admin_ads_admin_ads_screen.delete_anuncio'.tr()),
        content: Text('adsManager.confirmDelete'.tr(namedArgs: {'title': widget.ad.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('auto.admin_ads_admin_ads_screen.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('auto.admin_ads_admin_ads_screen.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _service.deleteAd(widget.ad.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final statusColor = ad.isLiveNow ? AppColors.green : AppColors.gray;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  ad.isVideo
                      ? Icons.play_circle_fill_rounded
                      : Icons.campaign_rounded,
                  color: AppColors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title.isEmpty ? 'adsManager.untitledAd'.tr() : ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${OfertixAdModel.typeKey(ad.type)} • ${ad.countryCode.toUpperCase()} • priority ${ad.priority}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.gray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(
                text: ad.isLiveNow ? 'LIVE' : 'PAUSED',
                color: statusColor,
              ),
            ],
          ),
          if (ad.description.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              ad.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.gray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: 'product.clicks'.tr(), value: ad.clicks.toString()),
              SizedBox(width: 10),
              _Metric(label: 'product.views'.tr(), value: ad.impressions.toString()),
              Spacer(),
              if (_busy)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                )
              else
                Switch(
                  value: ad.isActive,
                  onChanged: _toggle,
                  activeColor: AppColors.orange,
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminAdFormScreen(initialAd: ad),
                          ),
                        ),
                  icon: Icon(Icons.edit_rounded),
                  label: Text('auto.admin_ads_admin_ads_screen.edit'.tr()),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                onPressed: _busy ? null : _delete,
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  _StatePanel({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.orange, size: 42),
              SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
