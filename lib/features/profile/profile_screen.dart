import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/app_routes.dart';
import '../../services/profile_service.dart';
import '../alerts/alerts_screen.dart';
import '../favorites/favorites_screen.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';
import '../watchlist/watchlist_screen.dart';
import 'creator_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_provider.dart';

// ─── Premium profile screen ───────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..initialize(),
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF050D11),
              body: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          final user     = provider.user;
          final profile  = provider.profile;
          final isDark   = Theme.of(context).brightness == Brightness.dark;
          final bg       = isDark ? const Color(0xFF050D11) : AppColors.lightBackground;
          final textColor = isDark ? AppColors.text : AppColors.lightText;

          final displayName = profile?.displayName.trim().isNotEmpty == true
              ? profile!.displayName.trim()
              : user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : 'profile.guestUser'.tr();

          final locationParts = [
            if (profile?.city.trim().isNotEmpty == true) profile!.city.trim().toUpperCase(),
            (profile?.country ?? provider.country).trim().toUpperCase(),
          ].where((s) => s.isNotEmpty).toList();

          final locationLabel = locationParts.isNotEmpty
              ? locationParts.join(' · ')
              : 'GLOBAL';

          final currencyLabel = (profile?.currency ?? provider.currency).trim().toUpperCase();
          final pillLabel     = '$locationLabel · $currencyLabel';

          final isVerified = profile?.isVerified == true || profile?.sellerVerified == true;
          final rating     = profile?.ratingAverage ?? 0.0;
          final hasRating  = (profile?.ratingCount ?? 0) > 0;

          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'auto.profile_profile_screen.profile'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: textColor, size: 22),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 40,
              ),
              children: [
                // ── Header card ──────────────────────────────────────────────
                _HeaderCard(
                  displayName:     displayName,
                  username:        profile?.username ?? '',
                  avatarUrl:       profile?.photoUrl ?? '',
                  pillLabel:       pillLabel,
                  isVerified:      isVerified,
                  rating:          rating,
                  hasRating:       hasRating,
                  reelsCount:      profile?.reelsCount ?? 0,
                  sellItemsCount:  profile?.sellItemsCount ?? 0,
                  followersCount:  profile?.followersCount ?? 0,
                  isDark:          isDark,
                  onEdit: profile == null
                      ? null
                      : () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: EditProfileScreen(profile: profile),
                              ),
                            ),
                          );
                          if (changed == true && context.mounted) {
                            await provider.initialize();
                          }
                        },
                  onViewPublic: user == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatorProfileScreen(
                                creatorId: user.uid,
                                baseUrl: ApiConfig.baseUrl,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 22),

                // ── Mi actividad ─────────────────────────────────────────────
                _SectionLabel(label: 'Mi actividad', isDark: isDark),
                const SizedBox(height: 8),
                _SectionCard(
                  isDark: isDark,
                  tiles: [
                    _SectionTile(
                      icon: Icons.favorite_rounded,
                      title: 'profile.favorites'.tr(),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FavoritesScreen(
                            favoriteIds: const {},
                            onFavorite: (_) {},
                          ),
                        ),
                      ),
                    ),
                    _SectionTile(
                      icon: Icons.remove_red_eye_rounded,
                      title: 'profile.watchlist'.tr(),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WatchlistScreen(
                            productIds: const {},
                            onToggleWatch: (_) {},
                          ),
                        ),
                      ),
                    ),
                    _SectionTile(
                      icon: Icons.notifications_rounded,
                      title: 'profile.priceAlerts'.tr(),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlertsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Cuenta ───────────────────────────────────────────────────
                _SectionLabel(label: 'Cuenta', isDark: isDark),
                const SizedBox(height: 8),
                _SectionCard(
                  isDark: isDark,
                  tiles: [
                    _SectionTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'profile.rewards'.tr(),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RewardsScreen()),
                      ),
                    ),
                    _SectionTile(
                      icon: Icons.settings_rounded,
                      title: 'profile.settings'.tr(),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    _SectionTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y soporte',
                      isDark: isDark,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ayuda y soporte — próximamente')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Admin ────────────────────────────────────────────────────
                FutureBuilder<bool>(
                  future: ProfileService.instance.isCurrentUserAdmin(),
                  builder: (ctx, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SectionLabel(label: 'Admin', isDark: isDark),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.orange.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'ADMIN ONLY',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SectionCard(
                          isDark: isDark,
                          tiles: [
                            _SectionTile(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'admin.title'.tr(),
                              isDark: isDark,
                              onTap: () => Navigator.pushNamed(
                                ctx, AppRoutes.adminCommandCenter,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // ── Cerrar sesión ────────────────────────────────────────────
                const SizedBox(height: 4),
                _LogoutButton(
                  isDark: isDark,
                  onTap: () async {
                    await provider.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final String displayName;
  final String username;
  final String avatarUrl;
  final String pillLabel;
  final bool isVerified;
  final double rating;
  final bool hasRating;
  final int reelsCount;
  final int sellItemsCount;
  final int followersCount;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onViewPublic;

  const _HeaderCard({
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.pillLabel,
    required this.isVerified,
    required this.rating,
    required this.hasRating,
    required this.reelsCount,
    required this.sellItemsCount,
    required this.followersCount,
    required this.isDark,
    required this.onEdit,
    required this.onViewPublic,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final border = isDark ? Colors.white.withValues(alpha: 0.10) : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with orange ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: isDark ? const Color(0xFF13262E) : AppColors.lightCard2,
              backgroundImage: avatarUrl.startsWith('http')
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl.startsWith('http')
                  ? null
                  : Icon(Icons.person_rounded,
                      color: isDark ? AppColors.gray : AppColors.lightGray, size: 46),
            ),
          ),
          const SizedBox(height: 14),

          // Display name
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.text : AppColors.lightText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (username.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '@${username.trim()}',
              style: const TextStyle(
                color: AppColors.gray,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Pill: location · currency
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppColors.lightCard2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.lightBorder,
              ),
            ),
            child: Text(
              pillLabel,
              style: TextStyle(
                color: isDark ? AppColors.gray : AppColors.lightGray,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Verified + rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isVerified) ...[
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.green, size: 16),
                const SizedBox(width: 5),
                Text(
                  'Verificado',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (isVerified && hasRating) ...[
                Container(
                  width: 1,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.lightBorder,
                ),
              ],
              if (hasRating) ...[
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? AppColors.text : AppColors.lightText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC857), size: 16),
              ],
            ],
          ),

          const SizedBox(height: 18),

          // Stats row
          Row(
            children: [
              _StatBox(
                label: 'profile.reels'.tr(),
                value: reelsCount,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'profile.sellItems'.tr(),
                value: sellItemsCount,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'profile.followers'.tr(),
                value: followersCount,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_rounded,
                  label: 'profile.editProfile'.tr(),
                  onTap: onEdit,
                  isDark: isDark,
                ),
              ),
              if (onViewPublic != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.remove_red_eye_rounded,
                    label: 'Ver perfil público',
                    onTap: onViewPublic,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final bool isDark;

  const _StatBox({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A1820) : AppColors.lightCard2;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.lightBorder;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: isDark ? AppColors.text : AppColors.lightText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.gray : AppColors.lightGray,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action button (Editar / Ver público) ─────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isDark ? AppColors.text : AppColors.lightText, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.text : AppColors.lightText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: isDark ? AppColors.gray : AppColors.lightGray,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}

// ─── Section card (grouped tiles) ────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<_SectionTile> tiles;
  final bool isDark;

  const _SectionCard({required this.tiles, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0D1A20) : AppColors.lightCard;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : AppColors.lightBorder;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              Divider(height: 1, thickness: 1, color: divider,
                  indent: 54, endIndent: 0),
          ],
        ],
      ),
    );
  }
}

// ─── Section tile ─────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: isDark ? 0.13 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.text : AppColors.lightText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.muted : AppColors.lightGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _LogoutButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                color: AppColors.red.withValues(alpha: 0.90), size: 19),
            const SizedBox(width: 8),
            Text(
              'auto.profile_profile_screen.logout'.tr(),
              style: TextStyle(
                color: AppColors.red.withValues(alpha: 0.90),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
