import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../models/geo_alert_model.dart';
import '../../services/geo_alert_service.dart';

class GeoAlertsScreen extends StatefulWidget {
  GeoAlertsScreen({super.key});
  @override
  State<GeoAlertsScreen> createState() => _GeoAlertsScreenState();
}

class _GeoAlertsScreenState extends State<GeoAlertsScreen> {
  bool loading = false;
  String? error;
  List<NearbyDealModel> items = [];
  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission required');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final data = await GeoAlertService.instance.nearbyDeals(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('features.geo'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(18),
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_searching_rounded,
                    color: AppColors.orange,
                    size: 34,
                  ),
                  SizedBox(height: 12),
                  Text('geo.title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('geo.subtitle'.tr(),
                    style: TextStyle(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : load,
                      icon: loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.radar_rounded),
                      label: Text(
                        loading ? 'common.loading'.tr() : 'geo.scan'.tr(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            SizedBox(height: 16),
            if (items.isEmpty && !loading)
              Text('geo.empty'.tr(),
                style: TextStyle(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ...items.map(
              (e) => Card(
                color: AppColors.card,
                child: ListTile(
                  title: Text(
                    e.productTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    e.store,
                    style: TextStyle(color: AppColors.gray),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
