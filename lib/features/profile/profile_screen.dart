import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../alerts/alerts_screen.dart';
import '../favorites/favorites_screen.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../../core/navigation/app_routes.dart';
import '../../services/profile_service.dart';
import 'edit_profile_screen.dart';
import 'profile_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..initialize(),
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          final user = provider.user;
          final profile = provider.profile;
          final displayName = profile?.displayName.trim().isNotEmpty == true
              ? profile!.displayName.trim()
              : user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : 'profile.guestUser'.tr();
          final location = [
            if (profile?.city.trim().isNotEmpty == true) profile!.city.trim(),
            if ((profile?.country ?? provider.country).trim().isNotEmpty)
              (profile?.country ?? provider.country).trim().toUpperCase(),
          ].join(' • ');

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text('auto.profile_profile_screen.profile'.tr()),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _ProfileHeader(
                  displayName: displayName,
                  username: profile?.username ?? '',
                  bio: profile?.bio ?? '',
                  avatarUrl: profile?.photoUrl ?? '',
                  location: location,
                  currency: profile?.currency ?? provider.currency,
                  reelsCount: profile?.reelsCount ?? 0,
                  sellItemsCount: profile?.sellItemsCount ?? 0,
                  followersCount: profile?.followersCount ?? 0,
                  isVerified:
                      profile?.isVerified == true ||
                      profile?.sellerVerified == true,
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
                ),
                const SizedBox(height: 30),
                _Tile(
                  icon: Icons.favorite_rounded,
                  title: 'profile.favorites'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoritesScreen(
                          favoriteIds: const {},
                          onFavorite: (_) {},
                        ),
                      ),
                    );
                  },
                ),
                _Tile(
                  icon: Icons.remove_red_eye,
                  title: 'profile.watchlist'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WatchlistScreen(
                          productIds: const {},
                          onToggleWatch: (_) {},
                        ),
                      ),
                    );
                  },
                ),
                _Tile(
                  icon: Icons.notifications_active,
                  title: 'profile.priceAlerts'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    );
                  },
                ),
                _Tile(
                  icon: Icons.workspace_premium,
                  title: 'profile.rewards'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    );
                  },
                ),
                _Tile(
                  icon: Icons.settings,
                  title: 'profile.settings'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                FutureBuilder<bool>(
                  future: ProfileService.instance.isCurrentUserAdmin(),
                  builder: (context, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return _Tile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'admin.title'.tr(),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.adminCommandCenter),
                    );
                  },
                ),
                const SizedBox(height: 34),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () async {
                    await provider.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'auto.profile_profile_screen.logout'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.location,
    required this.currency,
    required this.reelsCount,
    required this.sellItemsCount,
    required this.followersCount,
    required this.isVerified,
    required this.onEdit,
  });

  final String displayName;
  final String username;
  final String bio;
  final String avatarUrl;
  final String location;
  final String currency;
  final int reelsCount;
  final int sellItemsCount;
  final int followersCount;
  final bool isVerified;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.orange,
            backgroundImage: avatarUrl.startsWith('http')
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.startsWith('http')
                ? null
                : const Icon(Icons.person, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 7),
                const Icon(Icons.verified_rounded, color: AppColors.orange),
              ],
            ],
          ),
          if (username.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${username.trim()}',
              style: const TextStyle(
                color: AppColors.gray,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (bio.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio.trim(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            [
              if (location.trim().isNotEmpty) location.trim(),
              currency.trim().toUpperCase(),
            ].join(' • '),
            style: const TextStyle(color: AppColors.gray, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'profile.reels'.tr(), value: '$reelsCount'),
              _Stat(label: 'profile.sellItems'.tr(), value: '$sellItemsCount'),
              _Stat(label: 'profile.followers'.tr(), value: '$followersCount'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: Text('profile.editProfile'.tr()),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 12,
        ),
        leading: Icon(icon, color: AppColors.orange, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}
