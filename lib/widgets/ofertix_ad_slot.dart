import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/ofertix_ad_model.dart';
import '../services/admin_ads_service.dart';

class OfertixAdSlot extends StatefulWidget {
  const OfertixAdSlot({
    super.key,
    required this.placement,
    this.countryCode = 'es',
    this.fallback,
  }) : _previewAd = null;

  const OfertixAdSlot.preview({super.key, required OfertixAdModel ad})
    : placement = OfertixAdPlacement.homeTop,
      countryCode = 'global',
      fallback = null,
      _previewAd = ad;

  final OfertixAdPlacement placement;
  final String countryCode;
  final Widget? fallback;
  final OfertixAdModel? _previewAd;

  @override
  State<OfertixAdSlot> createState() => _OfertixAdSlotState();
}

class _OfertixAdSlotState extends State<OfertixAdSlot> {
  final AdminAdsService _service = AdminAdsService.instance;
  final Set<String> _trackedImpressions = <String>{};

  Timer? _rotationTimer;
  int _currentIndex = 0;
  int _latestAdsLength = 0;

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _syncRotation(List<OfertixAdModel> ads) {
    _latestAdsLength = ads.length;

    if (_currentIndex >= ads.length) {
      _currentIndex = 0;
    }

    if (ads.length <= 1) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      return;
    }

    if (_rotationTimer != null) return;

    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _latestAdsLength <= 1) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _latestAdsLength;
      });
    });
  }

  void _trackImpression(OfertixAdModel ad) {
    if (ad.id.trim().isEmpty) return;
    if (_trackedImpressions.contains(ad.id)) return;

    _trackedImpressions.add(ad.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.registerImpression(ad.id);
    });
  }

  Future<void> _openAd(OfertixAdModel ad) async {
    if (ad.id.trim().isNotEmpty) {
      await _service.registerClick(ad.id);
    }

    final uri = Uri.tryParse(ad.trackingUrl.trim());
    if (uri == null || !uri.hasScheme) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget._previewAd;

    if (preview != null) {
      return _AnimatedAdCard(ad: preview, onTap: () {});
    }

    return StreamBuilder<List<OfertixAdModel>>(
      stream: _service.watchLiveAds(
        placement: widget.placement,
        countryCode: widget.countryCode,
      ),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? const <OfertixAdModel>[];

        if (ads.isEmpty) {
          _rotationTimer?.cancel();
          _rotationTimer = null;
          _currentIndex = 0;
          _latestAdsLength = 0;
          return widget.fallback ?? const SizedBox.shrink();
        }

        _syncRotation(ads);

        final safeIndex = _currentIndex.clamp(0, ads.length - 1);
        final ad = ads[safeIndex];

        _trackImpression(ad);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            final slide = Tween<Offset>(
              begin: const Offset(0.08, 0.0),
              end: Offset.zero,
            ).animate(fade);

            final scale = Tween<double>(begin: 0.965, end: 1.0).animate(fade);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
          child: _AnimatedAdCard(
            key: ValueKey<String>('ad_${ad.id}_$safeIndex'),
            ad: ad,
            onTap: () => _openAd(ad),
          ),
        );
      },
    );
  }
}

class _AnimatedAdCard extends StatelessWidget {
  const _AnimatedAdCard({super.key, required this.ad, required this.onTap});

  final OfertixAdModel ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSell = ad.placement == OfertixAdPlacement.sellTop;
    final isHome = ad.placement == OfertixAdPlacement.homeTop;

    if (isHome) {
      return _HomeImageBannerAd(ad: ad, onTap: onTap);
    }

    if (isSell) {
      return _SellSponsoredCard(ad: ad, onTap: onTap);
    }

    return _CompactSponsoredCard(ad: ad, onTap: onTap);
  }
}

class _HomeImageBannerAd extends StatelessWidget {
  const _HomeImageBannerAd({required this.ad, required this.onTap});

  final OfertixAdModel ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad.thumbnailUrl.trim().isNotEmpty
        ? ad.thumbnailUrl.trim()
        : ad.mediaUrl.trim();

    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6EAEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 3.2, // 320x100
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    color: const Color(0xFFF4F6F8),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellSponsoredCard extends StatelessWidget {
  const _SellSponsoredCard({required this.ad, required this.onTap});

  final OfertixAdModel ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _AdImageBox(ad: ad, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: _AdTextBlock(
                  ad: ad,
                  dark: true,
                  titleSize: 15,
                  descriptionSize: 12.3,
                ),
              ),
              const SizedBox(width: 10),
              _AdBadge(dark: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSponsoredCard extends StatelessWidget {
  const _CompactSponsoredCard({required this.ad, required this.onTap});

  final OfertixAdModel ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _AdIconBox(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: _AdTextBlock(
                  ad: ad,
                  dark: true,
                  titleSize: 14,
                  descriptionSize: 11.5,
                ),
              ),
              const SizedBox(width: 8),
              _AdBadge(dark: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdImageBox extends StatelessWidget {
  const _AdImageBox({required this.ad, required this.size});

  final OfertixAdModel ad;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = ad.thumbnailUrl.trim().isNotEmpty
        ? ad.thumbnailUrl.trim()
        : ad.mediaUrl.trim();

    if (url.isEmpty) return _AdIconBox(size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFF4F6F8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _AdIconBox(size: size),
        ),
      ),
    );
  }
}

class _AdIconBox extends StatelessWidget {
  const _AdIconBox({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 25),
    );
  }
}

class _AdTextBlock extends StatelessWidget {
  const _AdTextBlock({
    required this.ad,
    required this.dark,
    required this.titleSize,
    required this.descriptionSize,
  });

  final OfertixAdModel ad;
  final bool dark;
  final double titleSize;
  final double descriptionSize;

  @override
  Widget build(BuildContext context) {
    final title = ad.title.trim().isEmpty
        ? 'Oferta patrocinada'
        : ad.title.trim();

    final description = ad.description.trim().isEmpty
        ? 'Anuncio patrocinado'
        : ad.description.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _AdBadge(dark: dark),
            const SizedBox(width: 7),
            Expanded(
              child: Text('auto_sweep.widgets_ofertix_ad_slot.patrocinado'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark ? AppColors.gray : const Color(0xFF7C848E),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF1E2022),
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? AppColors.gray : const Color(0xFF6E7580),
            fontSize: descriptionSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: dark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: dark ? 0.28 : 0.18),
          ),
        ),
        child: Text(
          'AD',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
