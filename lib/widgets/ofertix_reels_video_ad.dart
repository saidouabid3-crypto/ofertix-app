import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/ofertix_ad_model.dart';
import '../services/admin_ads_service.dart';

class OfertixReelsVideoAd extends StatefulWidget {
  const OfertixReelsVideoAd({
    super.key,
    required this.ad,
    required this.isActive,
  });

  final OfertixAdModel ad;
  final bool isActive;

  @override
  State<OfertixReelsVideoAd> createState() => _OfertixReelsVideoAdState();
}

class _OfertixReelsVideoAdState extends State<OfertixReelsVideoAd> {
  final AdminAdsService _service = AdminAdsService.instance;

  VideoPlayerController? _videoController;
  WebViewController? _webController;

  bool _tracked = false;
  bool _loading = true;
  bool _failed = false;

  bool get _isIframeAd {
    final raw = widget.ad.mediaUrl.trim().toLowerCase();
    final url = _extractIframeSrc(widget.ad.mediaUrl).toLowerCase();

    return raw.contains('<iframe') ||
        url.contains('/gen-ad-code/') ||
        url.contains('impactradius-go.com/gen-ad-code');
  }

  bool get _isDirectVideo {
    final url = widget.ad.mediaUrl.trim().toLowerCase();

    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.m3u8') ||
        url.endsWith('.webm') ||
        url.contains('cloudinary.com') ||
        url.contains('firebasestorage.googleapis.com');
  }

  @override
  void initState() {
    super.initState();
    _initAd();
  }

  @override
  void didUpdateWidget(covariant OfertixReelsVideoAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.ad.id != widget.ad.id ||
        oldWidget.ad.mediaUrl != widget.ad.mediaUrl) {
      _tracked = false;
      _initAd();
      return;
    }

    _syncPlayback();
  }

  Future<void> _initAd() async {
    await _disposeVideo();

    if (!mounted) return;

    setState(() {
      _loading = true;
      _failed = false;
      _webController = null;
    });

    final mediaUrl = _normalizeUrl(_extractIframeSrc(widget.ad.mediaUrl));

    if (mediaUrl.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    if (_isIframeAd) {
      _initIframe(mediaUrl);
      return;
    }

    if (_isDirectVideo) {
      await _initVideo(mediaUrl);
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
      _failed = true;
    });
  }

  void _initIframe(String url) {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) return;

              setState(() {
                _loading = true;
                _failed = false;
              });
            },
            onPageFinished: (_) {
              if (!mounted) return;

              setState(() {
                _loading = false;
                _failed = false;
              });

              _trackImpressionIfNeeded();
            },
            onWebResourceError: (_) {
              if (!mounted) return;

              // Impact can return sub-resource errors while the ad is still visible.
              // Do not show a bad fallback card.
              setState(() {
                _loading = false;
                _failed = false;
              });
            },
          ),
        )
        ..loadHtmlString(_buildIframeHtml(url));

      if (!mounted) return;

      setState(() {
        _webController = controller;
        _loading = true;
        _failed = false;
      });

      // Safety timeout: some Impact creatives never trigger onPageFinished.
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        if (!_isIframeAd) return;

        setState(() {
          _loading = false;
          _failed = false;
        });

        _trackImpressionIfNeeded();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _buildIframeHtml(String url) {
    final safeUrl = _normalizeUrl(url);
    final dimensions = _extractIframeDimensions(widget.ad.mediaUrl);
    final width = dimensions.width;
    final height = dimensions.height;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: #000000;
      overflow: hidden;
      touch-action: manipulation;
    }

    .stage {
      position: fixed;
      inset: 0;
      width: 100vw;
      height: 100vh;
      background: #000000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    iframe {
      width: ${width}px;
      height: ${height}px;
      border: 0;
      margin: 0;
      padding: 0;
      background: #000000;
      transform-origin: center center;
    }
  </style>
</head>
<body>
  <div class="stage">
    <iframe
      id="adFrame"
      src="$safeUrl"
      width="$width"
      height="$height"
      scrolling="no"
      frameborder="0"
      marginheight="0"
      marginwidth="0"
      allow="autoplay; fullscreen; encrypted-media; picture-in-picture; clipboard-write"
      allowfullscreen>
    </iframe>
  </div>

  <script>
    function fitContain() {
      const frame = document.getElementById('adFrame');
      if (!frame) return;

      const baseW = $width;
      const baseH = $height;

      const screenW = window.innerWidth;
      const screenH = window.innerHeight;

      const scale = Math.min(screenW / baseW, screenH / baseH);

      frame.style.transform = 'scale(' + scale + ')';
    }

    window.addEventListener('load', fitContain);
    window.addEventListener('resize', fitContain);
    window.addEventListener('orientationchange', fitContain);
    setInterval(fitContain, 600);
    fitContain();
  </script>
</body>
</html>
''';
  }

  Future<void> _initVideo(String url) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;

      await controller.initialize();
      await controller.setLooping(true);

      // Keep muted so autoplay works on mobile without the user tapping first.
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _loading = false;
        _failed = false;
      });

      if (widget.isActive) {
        await controller.play();
        _trackImpressionIfNeeded();
      } else {
        await controller.pause();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _syncPlayback() {
    if (_isIframeAd) {
      if (widget.isActive) {
        _trackImpressionIfNeeded();
      }
      return;
    }

    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) return;

    if (widget.isActive) {
      controller.play();
      _trackImpressionIfNeeded();
    } else {
      controller.pause();
    }
  }

  void _trackImpressionIfNeeded() {
    if (!widget.isActive) return;
    if (_tracked) return;
    if (widget.ad.id.trim().isEmpty) return;

    _tracked = true;
    _service.registerImpression(widget.ad.id);
  }

  Future<void> _open() async {
    if (widget.ad.id.trim().isNotEmpty) {
      await _service.registerClick(widget.ad.id);
    }

    final rawUrl = widget.ad.trackingUrl.trim().isNotEmpty
        ? widget.ad.trackingUrl.trim()
        : _extractIframeSrc(widget.ad.mediaUrl);

    final uri = Uri.tryParse(_normalizeUrl(rawUrl));

    if (uri == null || !uri.hasScheme) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _extractIframeSrc(String value) {
    final clean = value.trim();

    if (!clean.toLowerCase().contains('<iframe')) {
      return clean;
    }

    final srcMatch = RegExp(
      r'''src\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(clean);

    return srcMatch?.group(1)?.trim() ?? clean;
  }

  _IframeDimensions _extractIframeDimensions(String value) {
    final width = _extractPositiveIntAttribute(value, 'width') ?? 720;
    final height = _extractPositiveIntAttribute(value, 'height') ?? 1280;

    return _IframeDimensions(width: width, height: height);
  }

  int? _extractPositiveIntAttribute(String html, String attribute) {
    final escapedAttribute = RegExp.escape(attribute);
    final match = RegExp(
      "$escapedAttribute\\s*=\\s*[\"']?(\\d+)[\"']?",
      caseSensitive: false,
    ).firstMatch(html);

    final rawValue = match?.group(1);
    if (rawValue == null) return null;

    final parsed = int.tryParse(rawValue);
    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }

  String _normalizeUrl(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '';

    if (clean.startsWith('//')) {
      return 'https:$clean';
    }

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    return clean;
  }

  Future<void> _disposeVideo() async {
    final controller = _videoController;
    _videoController = null;

    try {
      await controller?.pause();
      await controller?.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncPlayback();

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildYouTubeStyleAd(),
        const _ReelsAdGradient(),
        Positioned(
          left: 16,
          right: 82,
          bottom: 158,
          child: _ReelsStyleAdInfo(ad: widget.ad, onOpen: _open),
        ),
        if (_loading)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          ),
        if (_failed)
          Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _ReelsAdGradient(),
                Positioned(
                  left: 16,
                  right: 82,
                  bottom: 158,
                  child: _ReelsStyleAdInfo(ad: widget.ad, onOpen: _open),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildYouTubeStyleAd() {
    final webController = _webController;
    final videoController = _videoController;

    if (_isIframeAd && webController != null && !_failed) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: WebViewWidget(controller: webController),
      );
    }

    if (videoController != null &&
        videoController.value.isInitialized &&
        !_failed) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: videoController.value.aspectRatio == 0
              ? 9 / 16
              : videoController.value.aspectRatio,
          child: VideoPlayer(videoController),
        ),
      );
    }

    final thumbnail = widget.ad.thumbnailUrl.trim();

    if (thumbnail.startsWith('http')) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Image.network(
          thumbnail,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}

class _IframeDimensions {
  const _IframeDimensions({required this.width, required this.height});

  final int width;
  final int height;
}

class _ReelsAdGradient extends StatelessWidget {
  const _ReelsAdGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.28),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.76),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class _ReelsStyleAdInfo extends StatelessWidget {
  const _ReelsStyleAdInfo({required this.ad, required this.onOpen});

  final OfertixAdModel ad;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final title = ad.title.trim().isEmpty ? 'Sponsored Video Ad' : ad.title;
    final description = ad.description.trim().isEmpty
        ? 'Oferta patrocinada'
        : ad.description.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text('auto_sweep.widgets_ofertix_reels_video_ad.sponsored'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            height: 1.06,
            shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.shopping_bag_rounded, size: 20),
            label: Text('auto_sweep.widgets_ofertix_reels_video_ad.ver_oferta'.tr(),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
