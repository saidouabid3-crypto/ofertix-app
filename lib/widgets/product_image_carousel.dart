import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_theme.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final String heroTag;
  final double height;

  const ProductImageCarousel({
    super.key,
    required this.images,
    required this.heroTag,
    this.height = 360,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  List<String> get _slides {
    final urls = widget.images.where((e) => e.startsWith('http')).toList();
    if (urls.isEmpty) return const [];
    return urls.length > 3 ? urls.take(3).toList() : urls;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;

    if (slides.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: AppColors.card,
          child: const Icon(Icons.image_not_supported_rounded, size: 64),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: widget.heroTag,
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return _NetworkImageWithShimmer(url: slides[index]);
              },
            ),
          ),
          if (slides.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkImageWithShimmer extends StatefulWidget {
  final String url;

  const _NetworkImageWithShimmer({required this.url});

  @override
  State<_NetworkImageWithShimmer> createState() =>
      _NetworkImageWithShimmerState();
}

class _NetworkImageWithShimmerState extends State<_NetworkImageWithShimmer> {
  bool _loaded = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: AppColors.card,
        child: const Icon(Icons.broken_image_outlined, size: 72),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_loaded)
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(color: Colors.white),
          ),
        Image.network(
          widget.url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loaded) setState(() => _loaded = true);
              });
              return child;
            }
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _failed = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
