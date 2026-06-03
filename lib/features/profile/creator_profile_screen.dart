import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/smart_reel_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../services/smart_reel_service.dart';
import '../messages/chat_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  CreatorProfileScreen({
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

  late final SmartReelService _reelService;

  UserProfileModel? profile;
  List<SmartReelModel> reels = [];
  bool loading = true;
  bool following = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _reelService = SmartReelService(baseUrl: widget.baseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = await _profileService.getProfileById(widget.creatorId);
      final items = await _profileService.getCreatorReels(
        creatorId: widget.creatorId,
      );

      if (!mounted) return;

      setState(() {
        profile = user;
        reels = items;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'No se pudo cargar el perfil';
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      await _reelService.followCreator(widget.creatorId);
      if (!mounted) return;
      setState(() => following = !following);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.profile_creator_profile_screen.follow_pendiente_de_activar'.tr()
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
          recipientName: p?.displayName ?? 'Ofertix User',
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
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Text(
            error!,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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
                p?.username.isNotEmpty == true ? '@${p!.username}' : 'Creator',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(
                  profile: p,
                  reelsCount: reels.length,
                  following: following,
                  onFollow: _toggleFollow,
                  onMessage: _openChat,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Text('auto.profile_creator_profile_screen.reels'.tr(),
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
                  child: Text('auto.profile_creator_profile_screen.este_creator_todavia_no_tiene_reels'.tr()
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
  _ProfileHeader({
    required this.profile,
    required this.reelsCount,
    required this.following,
    required this.onFollow,
    required this.onMessage,
  });

  final UserProfileModel? profile;
  final int reelsCount;
  final bool following;
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
                        : 'Ofertix Creator',
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
                        : 'Deals, reels y ofertas verificadas.',
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
                      _Stat(label: 'auto.profile_creator_profile_screen.reels'.tr(), value: reelsCount.toString()),
                      _Stat(
                        label: 'Followers',
                        value: '${p?.followersCount ?? 0}',
                      ),
                      _Stat(label: 'Likes', value: '${p?.totalLikes ?? 0}'),
                    ],
                  ),
                  SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileButton(
                          label: following ? 'Following' : 'Follow',
                          filled: !following,
                          onTap: onFollow,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _ProfileButton(
                          label: 'Message',
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
  _Stat({required this.label, required this.value});

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
  _ProfileButton({
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

class _ReelTile extends StatelessWidget {
  _ReelTile({required this.reel});

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
