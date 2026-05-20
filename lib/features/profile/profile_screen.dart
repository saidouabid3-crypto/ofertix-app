import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import '../settings/settings_screen.dart';
import '../favorites/favorites_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../alerts/alerts_screen.dart';
import '../rewards/rewards_screen.dart';

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

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Profile'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                Center(
                  child: Text(
                    user?.email ?? 'Guest User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    '${provider.country} • ${provider.currency}',
                    style: const TextStyle(color: AppColors.gray, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 40),

                _Tile(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
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
                  title: 'Watchlist',
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
                  title: 'Price Alerts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    );
                  },
                ),

                _Tile(
                  icon: Icons.workspace_premium,
                  title: 'Rewards',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    );
                  },
                ),

                _Tile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
