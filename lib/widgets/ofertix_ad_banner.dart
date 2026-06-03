import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ad_banner_model.dart';
import '../services/ad_service.dart';

/// Reusable affiliate ad banner.
///
/// WHY:
/// - Firestore controls visibility and content.
/// - UI never crashes when there is no ad.
/// - Click opens trackingLink first for affiliate attribution.
class OfertixAdBanner extends StatelessWidget {
  const OfertixAdBanner({
    super.key,
    this.placement = 'home_top',
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 8),
  });

  final String placement;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdBannerModel>>(
      stream: AdService().watchActiveAds(placement: placement, limit: 1),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // WHY: Ads must never break the shopping experience.
          return const SizedBox.shrink();
        }

        final ads = snapshot.data ?? const <AdBannerModel>[];
        if (ads.isEmpty) return const SizedBox.shrink();

        return _AdCard(ad: ads.first, margin: margin);
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad, required this.margin});

  final AdBannerModel ad;
  final EdgeInsetsGeometry margin;

  Future<void> _openAd(BuildContext context) async {
    final uri = Uri.tryParse(ad.trackingLink.trim());

    if (uri == null) {
      _showSnack(context, 'رابط الإعلان غير صالح');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      _showSnack(context, 'ماقدرناش نفتح الإعلان');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Sponsored offer: ${ad.title}',
      child: Padding(
        padding: margin,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openAd(context),
          child: Ink(
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.campaign_rounded, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _AdText(ad: ad)),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdText extends StatelessWidget {
  const _AdText({required this.ad});

  final AdBannerModel ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ad.title.isEmpty ? 'Offre sponsorisée' : ad.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ad.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
