import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_review.dart';
import '../../models/smart_reel_model.dart';
import '../../models/marketplace_item.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../messages/chat_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({
    super.key,
    required this.creatorId,
    required this.baseUrl,
  });

  final String creatorId;
  final String baseUrl;

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final ProfileService _profileService = ProfileService.instance;

  UserProfileModel? profile;
  List<SmartReelModel> reels = [];
  List<MarketplaceItem> sellItems = [];
  MarketplaceReviewSummary reviews = MarketplaceReviewSummary.empty;
  bool loading = true;
  bool following = false;
  String? error;

  bool get _isOwnProfile =>
      AuthService.instance.currentUserId == widget.creatorId.trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.creatorId.trim();
    setState(() {
      loading = true;
      error = null;
    });

    if (kDebugMode) {
      debugPrint(
        '[Marketplace16E-B] profile_load_start user=$userId '
        'screen=CreatorProfileScreen',
      );
    }

    try {
      final user = await _profileService.getPublicProfileById(userId);
      if (user == null) {
        throw const NotFoundException('Profile not found');
      }

      var items = <SmartReelModel>[];
      var marketplaceItems = <MarketplaceItem>[];

      try {
        items = await _profileService.getCreatorReels(creatorId: userId);
      } catch (e) {
        _logOptionalLoadFailure(userId, 'reels', e);
      }

      try {
        marketplaceItems = await _profileService.getSellItems(sellerId: userId);
      } catch (e) {
        _logOptionalLoadFailure(userId, 'sell_items', e);
      }

      var reviewSummary = MarketplaceReviewSummary.empty;
      try {
        reviewSummary = await _profileService.getProfileReviews(userId);
      } catch (e) {
        _logOptionalLoadFailure(userId, 'reviews', e);
      }

      if (!mounted) return;

      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E-B] profile_load_result user=$userId '
          'status=success reason=public_profile_loaded',
        );
      }

      setState(() {
        profile = user;
        reels = items;
        sellItems = marketplaceItems;
        reviews = reviewSummary;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[Marketplace16E-B] profile_load_result user=$userId '
          'status=${_profileStatus(e)} reason=${_profileReason(e)}',
        );
      }
      setState(() {
        loading = false;
        error = 'mkt.profile.loadFailed';
      });
    }
  }

  void _logOptionalLoadFailure(String userId, String section, Object error) {
    if (!kDebugMode) return;
    debugPrint(
      '[Marketplace16E-B] profile_load_result user=$userId '
      'status=success reason=${section}_optional_${_profileReason(error)}',
    );
  }

  String _profileStatus(Object error) {
    if (error is NotFoundException) return '404';
    if (error is ForbiddenException) return '403';
    if (error is NetworkException && error.statusCode != null) {
      return error.statusCode.toString();
    }
    return 'error';
  }

  String _profileReason(Object error) {
    if (error is AppException) {
      return error.code ?? error.runtimeType.toString();
    }
    return error.runtimeType.toString();
  }

  Future<void> _toggleFollow() async {
    if (AuthService.instance.currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile.loginRequired'.tr())));
      return;
    }

    try {
      final isFollowing = await _profileService.followProfile(widget.creatorId);
      if (!mounted) return;
      setState(() => following = isFollowing);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'auto.profile_creator_profile_screen.follow_pendiente_de_activar'
                .tr()
                .tr(),
          ),
        ),
      );
    }
  }

  void _openChat() {
    final p = profile;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          baseUrl: widget.baseUrl,
          recipientId: widget.creatorId,
          recipientName: p?.displayName.trim().isNotEmpty == true
              ? p!.displayName
              : 'profile.creatorFallback'.tr(),
          recipientAvatarUrl: p?.photoUrl ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('mkt.profile.publicProfile'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  color: Colors.white54,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  error!.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: _load,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: Text('mkt.profile.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = profile;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _load,
        color: Colors.white,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              expandedHeight: 250,
              title: Text(
                p?.username.isNotEmpty == true
                    ? '@${p!.username}'
                    : 'mkt.profile.publicProfile'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(
                  profile: p,
                  reelsCount: reels.length,
                  sellItemsCount: sellItems.length,
                  following: following,
                  isOwnProfile: _isOwnProfile,
                  onFollow: _toggleFollow,
                  onMessage: _openChat,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _TrustCard(profile: p, sellItemsCount: sellItems.length)),
            SliverToBoxAdapter(child: _ReviewsCard(summary: reviews)),
            SliverToBoxAdapter(child: _SafetyCard()),
            SliverToBoxAdapter(child: _SellItemsStrip(items: sellItems)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'auto.profile_creator_profile_screen.reels'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${reels.length}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reels.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'auto.profile_creator_profile_screen.este_creator_todavia_no_tiene_reels'
                        .tr()
                        .tr(),
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 110),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReelTile(reel: reels[index]),
                    childCount: reels.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.reelsCount,
    required this.sellItemsCount,
    required this.following,
    required this.isOwnProfile,
    required this.onFollow,
    required this.onMessage,
  });

  final UserProfileModel? profile;
  final int reelsCount;
  final int sellItemsCount;
  final bool following;
  final bool isOwnProfile;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final p = profile;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 92, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white12,
            backgroundImage: p?.photoUrl.trim().isNotEmpty == true
                ? CachedNetworkImageProvider(p!.photoUrl)
                : null,
            child: p?.photoUrl.trim().isNotEmpty == true
                ? null
                : Icon(Icons.person_rounded, color: Colors.white, size: 42),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p?.displayName.trim().isNotEmpty == true
                        ? p!.displayName
                        : 'profile.creatorFallback'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    p?.bio.trim().isNotEmpty == true
                        ? p!.bio
                        : 'mkt.profile.noPublicInfo'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 11),
                  Row(
                    children: [
                      _Stat(
                        label: 'auto.profile_creator_profile_screen.reels'.tr(),
                        value: reelsCount.toString(),
                      ),
                      _Stat(
                        label: 'profile.sellItems'.tr(),
                        value: sellItemsCount.toString(),
                      ),
                      _Stat(
                        label: 'profile.followers'.tr(),
                        value: '${p?.followersCount ?? 0}',
                      ),
                      _Stat(
                        label: 'profile.likes'.tr(),
                        value: '${p?.totalLikes ?? 0}',
                      ),
                    ],
                  ),
                  SizedBox(height: 13),
                  if (!isOwnProfile)
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileButton(
                            label: following
                                ? 'profile.following'.tr()
                                : 'profile.follow'.tr(),
                            filled: !following,
                            onTap: onFollow,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _ProfileButton(
                            label: 'profile.message'.tr(),
                            filled: false,
                            onTap: onMessage,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? Colors.white : Colors.white12,
          foregroundColor: filled ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: filled ? Colors.white : Colors.white24),
          ),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

String _trustLabelKey(String trustLevel) {
  switch (trustLevel) {
    case 'highly_rated_seller':
      return 'mkt.profile.trust.highlyRatedSeller';
    case 'verified_seller':
      return 'mkt.profile.trust.verifiedSeller';
    case 'active_seller':
      return 'mkt.profile.trust.activeSeller';
    case 'new_seller':
      return 'mkt.profile.trust.newSeller';
    default:
      return 'mkt.profile.trust.basicProfile';
  }
}

IconData _trustIcon(String trustLevel) {
  switch (trustLevel) {
    case 'highly_rated_seller':
      return Icons.workspace_premium_rounded;
    case 'verified_seller':
      return Icons.verified_rounded;
    case 'active_seller':
      return Icons.trending_up_rounded;
    default:
      return Icons.shield_outlined;
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.profile, required this.sellItemsCount});

  final UserProfileModel? profile;
  final int sellItemsCount;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return const SizedBox.shrink();
    final memberSince = p.createdAt;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _trustIcon(p.trustLevel),
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _trustLabelKey(p.trustLevel).tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _TrustStat(
                label: 'mkt.profile.publicListings'.tr(),
                value: '$sellItemsCount',
              ),
              if (memberSince != null)
                _TrustStat(
                  label: 'mkt.profile.memberSince'.tr(),
                  value: '${memberSince.year}',
                ),
              if (p.ratingCount > 0)
                _TrustStat(
                  label: 'mkt.profile.rating'.tr(),
                  value:
                      '${p.ratingAverage.toStringAsFixed(1)} (${p.ratingCount})',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  const _TrustStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.summary});

  final MarketplaceReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'mkt.profile.reviews'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (summary.count > 0)
                Text(
                  '${summary.average.toStringAsFixed(1)} ★ (${summary.count})',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.items.isEmpty)
            Text(
              'mkt.profile.noReviewsYet'.tr(),
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            )
          else
            ...summary.items.take(3).map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.reviewerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating} ★',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (review.comment.trim().isNotEmpty)
                      Text(
                        review.comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'mkt.profile.safetyTips'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'mkt.messages.safetyMeetPublic'.tr(),
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
          Text(
            'mkt.messages.safetyInspectBeforePaying'.tr(),
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
          Text(
            'mkt.messages.safetyNoAdvancePayment'.tr(),
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _SellItemsStrip extends StatelessWidget {
  const _SellItemsStrip({required this.items});

  final List<MarketplaceItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.sellerListings'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) =>
                  _SellItemTile(item: items[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: items.length.clamp(0, 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellItemTile extends StatelessWidget {
  const _SellItemTile({required this.item});

  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: item.hasImage
                ? CachedNetworkImage(
                    imageUrl: item.mainImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.shopping_bag, color: Colors.white54),
                  )
                : const Center(
                    child: Icon(Icons.shopping_bag, color: Colors.white54),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.reel});

  final SmartReelModel reel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (reel.thumbnailUrl.startsWith('http'))
            CachedNetworkImage(
              imageUrl: reel.thumbnailUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.white10),
            )
          else
            Container(color: Colors.white10),
          Positioned(
            right: 5,
            top: 5,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              reel.priceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black87, blurRadius: 7)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
