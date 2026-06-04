import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/smart_reel_model.dart';
import '../../models/ofertix_ad_model.dart';
import '../../services/smart_reel_service.dart';
import '../../services/admin_ads_service.dart';
import '../../services/auth_service.dart';
import 'add_smart_reel_screen.dart';
import '../messages/chat_screen.dart';
import '../profile/creator_profile_screen.dart';
import '../../widgets/ofertix_reels_video_ad.dart';

class _ReelsFeedEntry {
  _ReelsFeedEntry.reel(this.reel) : ad = null;
  _ReelsFeedEntry.ad(this.ad) : reel = null;

  final SmartReelModel? reel;
  final OfertixAdModel? ad;
  bool get isAd => ad != null;
}

class SmartReelsScreen extends StatefulWidget {
  SmartReelsScreen({super.key, required this.baseUrl, this.isVisible = true});

  final String baseUrl;
  final bool isVisible;

  @override
  State<SmartReelsScreen> createState() => _SmartReelsScreenState();
}

class _SmartReelsScreenState extends State<SmartReelsScreen>
    with WidgetsBindingObserver {
  late SmartReelService service;
  late final PageController pageController;
  final AuthService auth = AuthService.instance;

  List<SmartReelModel> reels = [];
  bool loading = true;
  bool refreshing = false;
  bool appIsActive = true;
  String? errorMessage;
  int currentIndex = 0;

  bool get canPlay => widget.isVisible && appIsActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service = SmartReelService(baseUrl: widget.baseUrl);
    pageController = PageController();
    loadInitial();
  }

  @override
  void didUpdateWidget(covariant SmartReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.baseUrl != widget.baseUrl) {
      service = SmartReelService(baseUrl: widget.baseUrl);
      loadInitial();
      return;
    }

    if (oldWidget.isVisible != widget.isVisible && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;

    if (active != appIsActive && mounted) {
      setState(() => appIsActive = active);
    }
  }

  Future<void> loadInitial() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final items = await service.getFeed(limit: 20);

      if (!mounted) return;

      setState(() {
        reels = items;
        loading = false;
        errorMessage = null;
        currentIndex = 0;
      });

      if (items.isNotEmpty) {
        service.trackView(items.first.id);
      }
    } catch (_) {
      if (!mounted) return;

      // Pro behavior:
      // If the backend reels feed fails, do not block the whole Reels screen.
      // Ads can still fill the feed through Firestore/AdminAdsService.
      setState(() {
        reels = [];
        loading = false;
        errorMessage = 'No se pudieron cargar los reels';
        currentIndex = 0;
      });
    }
  }

  Future<void> refreshFeed() async {
    if (refreshing) return;

    setState(() => refreshing = true);

    try {
      final items = await service.getFeed(limit: 20);

      if (!mounted) return;

      setState(() {
        reels = items;
        currentIndex = 0;
      });

      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }

      if (items.isNotEmpty) {
        service.trackView(items.first.id);
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> openAddReel() async {
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSmartReelScreen(baseUrl: widget.baseUrl),
      ),
    );

    if (uploaded == true) {
      await refreshFeed();
    }
  }

  bool _isValidReelsAd(OfertixAdModel ad) {
    final media = ad.mediaUrl.trim().toLowerCase();

    if (media.isEmpty) return false;

    final isImpactIframe =
        media.contains('/gen-ad-code/') ||
        media.contains('impactradius-go.com/gen-ad-code');

    final isDirectVideo =
        media.endsWith('.mp4') ||
        media.endsWith('.mov') ||
        media.endsWith('.m3u8') ||
        media.contains('cloudinary.com');

    return isImpactIframe || isDirectVideo;
  }

  List<_ReelsFeedEntry> _composeFeed(List<OfertixAdModel> ads) {
    final activeAds = ads.where(_isValidReelsAd).toList();

    if (reels.isEmpty || activeAds.isEmpty) {
      return reels.map((reel) => _ReelsFeedEntry.reel(reel)).toList();
    }

    final entries = <_ReelsFeedEntry>[];
    var adIndex = 0;

    for (var i = 0; i < reels.length; i++) {
      entries.add(_ReelsFeedEntry.reel(reels[i]));

      if ((i + 1) % 5 == 0) {
        entries.add(_ReelsFeedEntry.ad(activeAds[adIndex % activeAds.length]));
        adIndex++;
      }
    }

    return entries;
  }

  void onFeedPageChanged(int index, List<_ReelsFeedEntry> entries) {
    setState(() => currentIndex = index);
    if (index < 0 || index >= entries.length) return;
    final reel = entries[index].reel;
    if (reel != null) service.trackView(reel.id);
  }

  void replaceReel(SmartReelModel reel) {
    final index = reels.indexWhere((item) => item.id == reel.id);
    if (index == -1) return;

    setState(() {
      reels[index] = reel;
    });
  }

  Future<void> toggleLike(SmartReelModel reel) async {
    final nextLiked = !reel.isLiked;

    replaceReel(
      reel.copyWith(
        isLiked: nextLiked,
        likes: nextLiked ? reel.likes + 1 : (reel.likes - 1).clamp(0, 999999),
      ),
    );

    try {
      await service.like(reel.id);
    } catch (_) {
      replaceReel(reel);
      showSnack('No se pudo guardar el like');
    }
  }

  Future<void> toggleSave(SmartReelModel reel) async {
    final nextSaved = !reel.isSaved;

    replaceReel(
      reel.copyWith(
        isSaved: nextSaved,
        saves: nextSaved ? reel.saves + 1 : (reel.saves - 1).clamp(0, 999999),
      ),
    );

    try {
      await service.save(reel.id);
      showSnack(nextSaved ? 'Guardado' : 'Quitado de guardados');
    } catch (_) {
      replaceReel(reel);
      showSnack('No se pudo guardar');
    }
  }

  Future<void> followCreator(SmartReelModel reel) async {
    final nextFollowing = !reel.isFollowing;
    replaceReel(reel.copyWith(isFollowing: nextFollowing));

    try {
      await service.followCreator(reel.creatorId);
      showSnack(
        nextFollowing
            ? 'Siguiendo a ${reel.creatorName}'
            : 'Follow actualizado',
      );
    } catch (_) {
      replaceReel(reel);
      showSnack('Follow pendiente de activar en backend');
    }
  }

  Future<void> reportReel(SmartReelModel reel) async {
    try {
      await service.report(reel.id);
      replaceReel(reel.copyWith(reports: reel.reports + 1));
      showSnack('Gracias. Report guardado.');
    } catch (_) {
      showSnack('No se pudo enviar el report');
    }
  }

  Future<void> buyReel(SmartReelModel reel) async {
    if (!reel.hasAffiliate) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            baseUrl: widget.baseUrl,
            recipientId: reel.creatorId,
            recipientName: reel.creatorName,
            recipientAvatarUrl: reel.creatorAvatarUrl,
            sourceReelId: reel.id,
            sourceReelTitle: reel.title,
            sourceReelThumbnailUrl: reel.thumbnailUrl,
          ),
        ),
      );
      return;
    }

    try {
      await service.trackClick(reel.id);
    } catch (_) {}

    final uri = Uri.tryParse(reel.affiliateUrl);
    if (uri == null) {
      showSnack('Link no válido');
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) showSnack('smartReels.cannotOpenLink'.tr());
  }

  Future<void> shareReel(SmartReelModel reel) async {
    final buffer = StringBuffer()
      ..writeln('🔥 ${reel.title}')
      ..writeln('Precio: ${reel.priceLabel}')
      ..writeln('Tienda: ${reel.store}');

    if (reel.hasDiscount) {
      buffer.writeln('Antes: ${reel.oldPriceLabel} ${reel.discountLabel}');
    }

    if (reel.hasAffiliate) {
      buffer.writeln(reel.affiliateUrl);
    }

    await SharePlus.instance.share(
      ShareParams(text: buffer.toString().trim(), subject: reel.title),
    );
  }

  Future<void> openComments(SmartReelModel reel) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(reel: reel, service: service),
    );

    if (added == true) {
      replaceReel(reel.copyWith(comments: reel.comments + 1));
    }
  }

  Future<void> openCreatorProfile(SmartReelModel reel) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatorProfileScreen(
          creatorId: reel.creatorId,
          baseUrl: widget.baseUrl,
        ),
      ),
    );
  }

  Future<void> openReelMenu(SmartReelModel reel) async {
    final action = await showModalBottomSheet<_ReelMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReelOptionsSheet(reel: reel, isMine: _looksLikeMyReel(reel)),
    );

    if (action == null) return;

    switch (action) {
      case _ReelMenuAction.edit:
        await _openEditReelSheet(reel);
        break;
      case _ReelMenuAction.delete:
        final confirmed = await _confirmDelete(reel);
        if (confirmed) {
          await _deleteReel(reel);
        }
        break;
      case _ReelMenuAction.stats:
        showSnack('Vistas: ${reel.views} · Likes: ${reel.likes}');
        break;
      case _ReelMenuAction.report:
        await reportReel(reel);
        break;
      case _ReelMenuAction.notInterested:
        showSnack('Te mostraremos menos reels como este');
        break;
    }
  }

  bool _looksLikeMyReel(SmartReelModel reel) {
    final uid = auth.currentUserId;
    return uid != null && uid.trim().isNotEmpty && reel.creatorId == uid;
  }

  Future<void> _openEditReelSheet(SmartReelModel reel) async {
    final updated = await showModalBottomSheet<SmartReelModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditReelSheet(reel: reel, service: service),
    );

    if (updated == null) return;

    replaceReel(updated);
    showSnack('Reel actualizado');
  }

  Future<void> _deleteReel(SmartReelModel reel) async {
    try {
      await service.deleteSmartReel(reel.id);

      if (!mounted) return;

      setState(() {
        reels.removeWhere((item) => item.id == reel.id);
        if (currentIndex >= reels.length) {
          currentIndex = reels.isEmpty ? 0 : reels.length - 1;
        }
      });

      showSnack('Reel eliminado');
    } catch (e) {
      showSnack('No se pudo eliminar el reel. Revisa tu sesión.');
    }
  }

  Future<bool> _confirmDelete(SmartReelModel reel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF161616),
        title: Text('auto.smart_reels_smart_reels_screen.eliminar_reel'.tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'smartReels.confirmDelete'.tr(namedArgs: {'title': reel.title}),
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('auto.smart_reels_smart_reels_screen.cancelar'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('auto.smart_reels_smart_reels_screen.eliminar'.tr(),
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  void showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: refreshFeed,
            color: Colors.white,
            child: StreamBuilder<List<OfertixAdModel>>(
              stream: AdminAdsService.instance.watchLiveAds(
                placement: OfertixAdPlacement.reelsVideo,
                countryCode: 'es',
              ),
              builder: (context, adSnapshot) {
                final entries = _composeFeed(
                  adSnapshot.data ?? const <OfertixAdModel>[],
                );

                if (entries.isEmpty && errorMessage != null) {
                  return _ErrorState(
                    message: errorMessage!,
                    onRetry: loadInitial,
                  );
                }

                if (entries.isEmpty) {
                  return _EmptyState(onAdd: openAddReel, onRetry: loadInitial);
                }

                return PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: entries.length,
                  onPageChanged: (index) => onFeedPageChanged(index, entries),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final ad = entry.ad;

                    if (ad != null) {
                      return OfertixReelsVideoAd(
                        key: ValueKey('ad_${ad.id}'),
                        ad: ad,
                        isActive: canPlay && index == currentIndex,
                      );
                    }

                    final reel = entry.reel!;

                    return _SmartReelPage(
                      key: ValueKey(reel.id),
                      reel: reel,
                      isActive: canPlay && index == currentIndex,
                      onLike: () => toggleLike(reel),
                      onComment: () => openComments(reel),
                      onFollow: () => followCreator(reel),
                      onSave: () => toggleSave(reel),
                      onShare: () => shareReel(reel),
                      onMenu: () => openReelMenu(reel),
                      onBuy: () => buyReel(reel),
                      onOpenProfile: () => openCreatorProfile(reel),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Text('auto.smart_reels_smart_reels_screen.ofertix_reels'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      letterSpacing: -0.4,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                  ),
                  Spacer(),
                  _TopCircleButton(
                    icon: Icons.refresh_rounded,
                    onTap: refreshFeed,
                    loading: refreshing,
                  ),
                  SizedBox(width: 10),
                  _TopCircleButton(icon: Icons.add_rounded, onTap: openAddReel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartReelPage extends StatefulWidget {
  _SmartReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onLike,
    required this.onComment,
    required this.onFollow,
    required this.onSave,
    required this.onShare,
    required this.onMenu,
    required this.onBuy,
    required this.onOpenProfile,
  });

  final SmartReelModel reel;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onFollow;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onMenu;
  final VoidCallback onBuy;
  final VoidCallback onOpenProfile;

  @override
  State<_SmartReelPage> createState() => _SmartReelPageState();
}

class _SmartReelPageState extends State<_SmartReelPage> {
  VideoPlayerController? controller;
  bool initializing = true;
  bool failed = false;
  bool muted = false;

  @override
  void initState() {
    super.initState();
    initVideo();
  }

  @override
  void didUpdateWidget(covariant _SmartReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reel.bestVideoUrl != widget.reel.bestVideoUrl) {
      disposeController();
      initVideo();
      return;
    }

    syncPlayback();
  }

  Future<void> syncPlayback() async {
    final video = controller;
    if (video == null || !video.value.isInitialized) return;

    if (widget.isActive) {
      await video.play();
    } else {
      await video.pause();
    }
  }

  Future<void> initVideo() async {
    final url = widget.reel.bestVideoUrl.trim();

    if (url.isEmpty) {
      if (!mounted) return;
      setState(() {
        initializing = false;
        failed = true;
      });
      return;
    }

    try {
      final videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      controller = videoController;

      await videoController.initialize();
      await videoController.setLooping(true);
      await videoController.setVolume(muted ? 0 : 1);

      if (!mounted) {
        await videoController.dispose();
        return;
      }

      setState(() {
        initializing = false;
        failed = false;
      });

      if (widget.isActive) {
        await videoController.play();
      } else {
        await videoController.pause();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        initializing = false;
        failed = true;
      });
    }
  }

  Future<void> togglePlay() async {
    final video = controller;
    if (video == null || !video.value.isInitialized) return;

    if (!widget.isActive) {
      await video.pause();
      return;
    }

    if (video.value.isPlaying) {
      await video.pause();
    } else {
      await video.play();
    }

    if (mounted) setState(() {});
  }

  Future<void> toggleMute() async {
    final video = controller;
    if (video == null) return;

    setState(() => muted = !muted);
    await video.setVolume(muted ? 0 : 1);
  }

  Future<void> disposeController() async {
    final video = controller;
    controller = null;

    try {
      await video?.pause();
      await video?.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return GestureDetector(
      onTap: togglePlay,
      onLongPress: toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoBackground(
            reel: reel,
            controller: controller,
            initializing: initializing,
            failed: failed,
          ),
          _DarkGradientOverlay(),
          Positioned(
            right: 12,
            bottom: 116,
            child: _RightActions(
              reel: reel,
              onLike: widget.onLike,
              onComment: widget.onComment,
              onSave: widget.onSave,
              onShare: widget.onShare,
              onMenu: widget.onMenu,
            ),
          ),
          Positioned(
            left: 16,
            right: 82,
            bottom: 106,
            child: _ReelInfo(
              reel: reel,
              onBuy: widget.onBuy,
              onFollow: widget.onFollow,
              onOpenProfile: widget.onOpenProfile,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 68,
            child: _ProgressBar(controller: controller),
          ),
          Positioned(
            right: 16,
            top: 92,
            child: _MuteBadge(muted: muted, onTap: toggleMute),
          ),
        ],
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  _TopCircleButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: loading
            ? Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }
}

class _VideoBackground extends StatelessWidget {
  _VideoBackground({
    required this.reel,
    required this.controller,
    required this.initializing,
    required this.failed,
  });

  final SmartReelModel reel;
  final VideoPlayerController? controller;
  final bool initializing;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final video = controller;

    if (video != null && video.value.isInitialized && !failed) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (reel.thumbnailUrl.startsWith('http'))
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: Colors.black),
          )
        else
          Container(color: Colors.black),
        Container(color: Colors.black.withValues(alpha: 0.45)),
        Center(
          child: initializing
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white70,
                  size: 78,
                ),
        ),
      ],
    );
  }
}

class _DarkGradientOverlay extends StatelessWidget {
  _DarkGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.48),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.84),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.42, 1.0],
          ),
        ),
      ),
    );
  }
}

class _RightActions extends StatelessWidget {
  _RightActions({
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onMenu,
  });

  final SmartReelModel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: reel.isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: compact(reel.likes),
          active: reel.isLiked,
          activeColor: Colors.redAccent,
          onTap: onLike,
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: compact(reel.comments),
          onTap: onComment,
        ),
        _ActionButton(
          icon: reel.isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: compact(reel.saves),
          active: reel.isSaved,
          activeColor: Colors.white,
          onTap: onSave,
        ),
        _ActionButton(icon: Icons.send_rounded, label: 'product.share'.tr(), onTap: onShare),
        _ActionButton(icon: Icons.more_horiz_rounded, label: '', onTap: onMenu),
      ],
    );
  }

  String compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _ActionButton extends StatelessWidget {
  _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 31,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
            if (label.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReelInfo extends StatelessWidget {
  _ReelInfo({
    required this.reel,
    required this.onBuy,
    required this.onFollow,
    required this.onOpenProfile,
  });

  final SmartReelModel reel;
  final VoidCallback onBuy;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onOpenProfile,
              child: _CreatorAvatar(reel: reel),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '@${reel.creatorName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: onFollow,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  reel.isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          reel.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            height: 1.08,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
        if (reel.description.isNotEmpty) ...[
          SizedBox(height: 5),
          Text(
            reel.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
        ],
        SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _InfoPill(icon: Icons.storefront_rounded, label: reel.store),
            if (reel.hasDiscount)
              _InfoPill(
                icon: Icons.local_offer_rounded,
                label: reel.discountLabel,
              ),
          ],
        ),
        SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              reel.priceLabel,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 23,
                letterSpacing: -0.7,
                shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
              ),
            ),
            SizedBox(width: 9),
            if (reel.hasDiscount)
              Flexible(
                child: Text(
                  reel.oldPriceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white54,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 11),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onBuy,
            icon: Icon(Icons.shopping_bag_rounded, size: 20),
            label: Text('auto.smart_reels_smart_reels_screen.ver_oferta'.tr(),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 17),
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

class _CreatorAvatar extends StatelessWidget {
  _CreatorAvatar({required this.reel});

  final SmartReelModel reel;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      backgroundImage: reel.creatorAvatarUrl.startsWith('http')
          ? CachedNetworkImageProvider(reel.creatorAvatarUrl)
          : null,
      child: reel.creatorAvatarUrl.startsWith('http')
          ? null
          : Icon(Icons.person_rounded, color: Colors.white, size: 18),
    );
  }
}

class _InfoPill extends StatelessWidget {
  _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuteBadge extends StatelessWidget {
  _MuteBadge({required this.muted, required this.onTap});

  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 19,
        backgroundColor: Colors.black.withValues(alpha: 0.36),
        child: Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  _ProgressBar({required this.controller});

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final video = controller;

    if (video == null || !video.value.isInitialized) {
      return Container(
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, value, _) {
        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        final progress = duration <= 0
            ? 0.0
            : (position / duration).clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );
  }
}

enum _ReelMenuAction { edit, delete, stats, report, notInterested }

class _ReelOptionsSheet extends StatelessWidget {
  _ReelOptionsSheet({required this.reel, required this.isMine});

  final SmartReelModel reel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 14),
            if (isMine) ...[
              _MenuTile(
                icon: Icons.edit_rounded,
                title: 'smartReels.editReel'.tr(),
                subtitle: 'smartReels.editReelSubtitle'.tr(),
                onTap: () => Navigator.pop(context, _ReelMenuAction.edit),
              ),
              _MenuTile(
                icon: Icons.delete_outline_rounded,
                title: 'smartReels.deleteReel'.tr(),
                subtitle: 'smartReels.deleteReelSubtitle'.tr(),
                danger: true,
                onTap: () => Navigator.pop(context, _ReelMenuAction.delete),
              ),
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                title: 'smartReels.viewStats'.tr(),
                subtitle: 'smartReels.statsSubtitle'.tr(namedArgs: {'views': '${reel.views}', 'likes': '${reel.likes}'}),
                onTap: () => Navigator.pop(context, _ReelMenuAction.stats),
              ),
            ] else ...[
              _MenuTile(
                icon: Icons.flag_outlined,
                title: 'smartReels.report'.tr(),
                subtitle: 'smartReels.reportSubtitle'.tr(),
                danger: true,
                onTap: () => Navigator.pop(context, _ReelMenuAction.report),
              ),
              _MenuTile(
                icon: Icons.visibility_off_outlined,
                title: 'smartReels.notInterested'.tr(),
                subtitle: 'smartReels.notInterestedSubtitle'.tr(),
                onTap: () =>
                    Navigator.pop(context, _ReelMenuAction.notInterested),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : Colors.white;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white38),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  _CommentsSheet({required this.reel, required this.service});

  final SmartReelModel reel;
  final SmartReelService service;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController controller = TextEditingController();

  bool loading = true;
  bool sending = false;
  List<SmartReelComment> comments = [];

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadComments() async {
    try {
      final items = await widget.service.getComments(widget.reel.id);

      if (!mounted) return;

      setState(() {
        comments = items;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        comments = [];
        loading = false;
      });
    }
  }

  Future<void> sendComment() async {
    final text = controller.text.trim();

    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      final comment = await widget.service.addComment(
        reelId: widget.reel.id,
        text: text,
      );

      if (!mounted) return;

      if (comment != null) {
        setState(() {
          comments.insert(0, comment);
          controller.clear();
        });

        Navigator.pop(context, true);
      } else {
        setState(() {
          comments.insert(
            0,
            SmartReelComment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              reelId: widget.reel.id,
              userId: 'mobile_user',
              userName: 'Ofertix User',
              text: text,
              createdAt: DateTime.now(),
            ),
          );
          controller.clear();
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.smart_reels_smart_reels_screen.no_se_pudo_enviar_el_comentario'.tr()
                .tr(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: Color(0xFF101010),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 14),
            Text('auto.smart_reels_smart_reels_screen.comentarios'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : comments.isEmpty
                  ? Center(
                      child: Text('auto.smart_reels_smart_reels_screen.se_el_primero_en_comentar'.tr()
                            .tr(),
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final comment = comments[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.white12,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            comment.userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            comment.text,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'auto.smart_reels_smart_reels_screen.escribe_un_comentario'.tr()
                                .tr(),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: sending ? null : sendComment,
                      icon: sending
                          ? SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditReelSheet extends StatefulWidget {
  _EditReelSheet({required this.reel, required this.service});

  final SmartReelModel reel;
  final SmartReelService service;

  @override
  State<_EditReelSheet> createState() => _EditReelSheetState();
}

class _EditReelSheetState extends State<_EditReelSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController storeController;
  late final TextEditingController priceController;
  late final TextEditingController oldPriceController;
  late final TextEditingController currencyController;
  late final TextEditingController affiliateController;
  late final TextEditingController productIdController;

  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.reel.title);
    descriptionController = TextEditingController(
      text: widget.reel.description,
    );
    storeController = TextEditingController(text: widget.reel.store);
    priceController = TextEditingController(
      text: widget.reel.currentPrice.toStringAsFixed(2),
    );
    oldPriceController = TextEditingController(
      text: widget.reel.oldPrice == null
          ? ''
          : widget.reel.oldPrice!.toStringAsFixed(2),
    );
    currencyController = TextEditingController(text: widget.reel.currency);
    affiliateController = TextEditingController(text: widget.reel.affiliateUrl);
    productIdController = TextEditingController(text: widget.reel.productId);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    storeController.dispose();
    priceController.dispose();
    oldPriceController.dispose();
    currencyController.dispose();
    affiliateController.dispose();
    productIdController.dispose();
    super.dispose();
  }

  double? _parsePrice(String value) {
    final clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    final price = _parsePrice(priceController.text);
    final oldPrice = _parsePrice(oldPriceController.text);

    if (price == null || price <= 0) {
      setState(() => error = 'Precio inválido');
      return;
    }

    if (oldPrice != null && oldPrice > 0 && oldPrice < price) {
      setState(
        () => error = 'El precio anterior debe ser mayor o igual al actual',
      );
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final updated = await widget.service.updateSmartReel(
        reelId: widget.reel.id,
        title: titleController.text,
        description: descriptionController.text,
        store: storeController.text,
        currentPrice: price,
        oldPrice: oldPrice,
        currency: currencyController.text,
        affiliateUrl: affiliateController.text,
        productId: productIdController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = 'No se pudo actualizar. Revisa tu sesión o conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text('auto.smart_reels_smart_reels_screen.editar_reel'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 16),
                _EditInput(
                  controller: titleController,
                  label: 'smartReels.labelTitle'.tr(),
                  icon: Icons.title_rounded,
                  validator: (value) {
                    if ((value ?? '').trim().length < 3) {
                      return 'smartReels.minChars3'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                _EditInput(
                  controller: descriptionController,
                  label: 'smartReels.labelDescription'.tr(),
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                _EditInput(
                  controller: storeController,
                  label: 'smartReels.labelStore'.tr(),
                  icon: Icons.storefront_rounded,
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'smartReels.minChars2'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _EditInput(
                        controller: priceController,
                        label: 'smartReels.labelCurrentPrice'.tr(),
                        icon: Icons.euro_rounded,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _EditInput(
                        controller: oldPriceController,
                        label: 'smartReels.labelOldPrice'.tr(),
                        icon: Icons.local_offer_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _EditInput(
                  controller: currencyController,
                  label: 'smartReels.labelCurrency'.tr(),
                  icon: Icons.payments_rounded,
                ),
                SizedBox(height: 12),
                _EditInput(
                  controller: affiliateController,
                  label: 'smartReels.labelBuyLink'.tr(),
                  icon: Icons.link_rounded,
                ),
                SizedBox(height: 12),
                _EditInput(
                  controller: productIdController,
                  label: 'smartReels.labelProductId'.tr(),
                  icon: Icons.qr_code_2_rounded,
                ),
                if (error != null) ...[
                  SizedBox(height: 12),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(Icons.save_rounded),
                    label: Text(
                      saving ? 'Guardando...' : 'Guardar cambios',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditInput extends StatelessWidget {
  _EditInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        errorStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  _EmptyState({required this.onAdd, required this.onRetry});

  final VoidCallback onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_rounded, color: Colors.white, size: 72),
              SizedBox(height: 16),
              Text('auto.smart_reels_smart_reels_screen.no_hay_reels_todavia'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 8),
              Text('auto.smart_reels_smart_reels_screen.publica_el_primer_smart_reel_de_oferti'.tr()
                    .tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded),
                label: Text('auto.smart_reels_smart_reels_screen.anadir_reel'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text('auto.smart_reels_smart_reels_screen.reintentar'.tr(),
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 72),
              SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                ),
              ),
              SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded),
                label: Text('auto.smart_reels_smart_reels_screen.reintentar'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
