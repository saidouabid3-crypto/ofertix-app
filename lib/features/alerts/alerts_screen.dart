import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/price_utils.dart';
import 'alerts_provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlertsProvider()..initialize(),
      child: const _AlertsBody(),
    );
  }
}

class _AlertsBody extends StatelessWidget {
  const _AlertsBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'auto.alerts_alerts_screen.mis_alertas'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _body(context, provider),
    );
  }

  Widget _body(BuildContext context, AlertsProvider provider) {
    if (provider.isLoading && provider.alerts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    if (provider.error != null && provider.alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.gray, size: 42),
            const SizedBox(height: 12),
            Text(
              'common.error'.tr(),
              style: const TextStyle(color: AppColors.gray, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.orange),
              label: Text(
                'common.retry'.tr(),
                style: const TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_off_rounded,
                color: AppColors.gray,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                'auto.alerts_alerts_screen.no_tienes_alertas_todavia'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'auto.alerts_alerts_screen.crea_alertas_desde_los_detalles_del_pr'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () async {
        await provider.checkAlerts();
        await provider.refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: provider.alerts.length,
        itemBuilder: (context, index) {
          final doc = provider.alerts[index];
          return _AlertCard(
            key: ValueKey(doc.id),
            doc: doc,
            provider: provider,
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final AlertsProvider provider;

  const _AlertCard({super.key, required this.doc, required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final alertId = doc.id;

    final name = (data['productName'] ?? data['name'] ?? data['productId'] ?? '').toString();
    final image = (data['productImage'] ?? data['image'] ?? '').toString();
    final store = (data['store'] ?? '').toString();
    final currency = (data['currency'] ?? 'EUR').toString();
    final targetPrice = (data['targetPrice'] as num?)?.toDouble() ?? 0;
    final currentPrice = (data['currentPrice'] ?? data['newPrice'] as num?)?.toDouble() ?? 0;
    final isActive = data['active'] == true;
    final isTriggered = data['triggered'] == true;

    final statusLabel = isTriggered
        ? 'alerts.statusTriggered'.tr()
        : isActive
            ? 'alerts.statusActive'.tr()
            : 'alerts.statusOff'.tr();
    final statusColor = isTriggered
        ? AppColors.green
        : isActive
            ? AppColors.orange
            : AppColors.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 66,
                height: 66,
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFF161E24)),
                        errorWidget: (_, __, ___) => _imageFallback(),
                      )
                    : _imageFallback(),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Product name
                  Text(
                    name.isNotEmpty ? name : '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),

                  if (store.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      store.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Prices row
                  Row(
                    children: [
                      if (currentPrice > 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'product.priceAlert.currentPrice'.tr(),
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              PriceUtils.formatPrice(currentPrice, currency),
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'product.priceAlert.targetPrice'.tr(),
                            style: const TextStyle(
                              color: AppColors.gray,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            PriceUtils.formatPrice(targetPrice, currency),
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Last checked timestamp
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 10,
                        color: AppColors.gray.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _lastCheckedLabel(data['lastCheckedAt']),
                        style: TextStyle(
                          color: AppColors.gray.withValues(alpha: 0.7),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action column
            Column(
              children: [
                // Active toggle
                _SmallToggle(
                  value: isActive && !isTriggered,
                  onChanged: (val) => provider.setAlertActive(
                    alertId: alertId,
                    active: val,
                  ),
                ),
                const SizedBox(height: 4),
                // Edit price button
                _ActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.orange,
                  onTap: () => _showEditSheet(context, alertId, targetPrice, currency),
                ),
                const SizedBox(height: 4),
                // Delete button
                _ActionButton(
                  icon: Icons.delete_rounded,
                  color: AppColors.red,
                  onTap: () => _confirmDelete(context, alertId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _lastCheckedLabel(dynamic value) {
    if (value == null) return 'alerts.neverChecked'.tr();
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is String && value.isNotEmpty) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return 'alerts.neverChecked'.tr();
    final diff = DateTime.now().difference(dt);
    final prefix = 'alerts.lastChecked'.tr();
    if (diff.inSeconds < 60) return '$prefix: ${'common.justNow'.tr()}';
    if (diff.inMinutes < 60) return '$prefix: ${diff.inMinutes}m';
    if (diff.inHours < 24) return '$prefix: ${diff.inHours}h';
    return '$prefix: ${diff.inDays}d';
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFF161E24),
      child: const Icon(
        Icons.notifications_rounded,
        color: AppColors.gray,
        size: 28,
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    String alertId,
    double currentTarget,
    String currency,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTargetSheet(
        alertId: alertId,
        currentTarget: currentTarget,
        currency: currency,
        provider: provider,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'auto.alerts_alerts_screen.eliminar_alerta'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'auto.alerts_alerts_screen.seguro_que_quieres_eliminar_esta_alert'.tr(),
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'auto.alerts_alerts_screen.cancelar'.tr(),
              style: const TextStyle(color: AppColors.gray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'auto.alerts_alerts_screen.eliminar'.tr(),
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.deleteAlert(alertId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'alerts.deleteSuccess'.tr() : 'alerts.deleteFailed'.tr(),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ─── Edit target price bottom sheet ──────────────────────────────────────────

class _EditTargetSheet extends StatefulWidget {
  final String alertId;
  final double currentTarget;
  final String currency;
  final AlertsProvider provider;

  const _EditTargetSheet({
    required this.alertId,
    required this.currentTarget,
    required this.currency,
    required this.provider,
  });

  @override
  State<_EditTargetSheet> createState() => _EditTargetSheetState();
}

class _EditTargetSheetState extends State<_EditTargetSheet> {
  late final TextEditingController _ctrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentTarget > 0 ? widget.currentTarget.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _ctrl.text.replaceAll('€', '').replaceAll(r'$', '').replaceAll(',', '.').trim();
    final price = double.tryParse(raw);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.priceAlert.invalidPrice'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.provider.updateTargetPrice(
      alertId: widget.alertId,
      targetPrice: price,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.priceAlert.created'.tr()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('product.priceAlert.error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.orange, size: 22),
                const SizedBox(width: 10),
                Text(
                  'product.priceAlert.targetPrice'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'product.priceAlert.targetPrice'.tr(),
                labelStyle: const TextStyle(color: AppColors.gray),
                suffixText: widget.currency,
                suffixStyle: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray,
                      side: BorderSide(color: AppColors.gray.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text('product.priceAlert.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'product.priceAlert.setAlert'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SmallToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SmallToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.72,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.orange,
        inactiveThumbColor: AppColors.gray,
        inactiveTrackColor: AppColors.gray.withValues(alpha: 0.2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
