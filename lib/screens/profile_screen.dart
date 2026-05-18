import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

import 'auth_screen.dart';
import 'country_selection_screen.dart';
import 'ai_assistant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String countryName = 'Global / Not selected';
  String countryCode = 'US';
  String currency = 'USD';
  String language = 'English';
  bool darkMode = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'dark';
    setState(() {
      darkMode = savedTheme == 'dark';
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    darkMode = !darkMode;
    await prefs.setString('theme_mode', darkMode ? 'dark' : 'light');
    OfertixApp.of(context)?.changeTheme(darkMode);
    setState(() {});
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCountryCode = prefs.getString('country') ?? 'US';
    final savedCountryName = prefs.getString('country_name') ?? 'United States';

    setState(() {
      countryCode = savedCountryCode.toUpperCase();
      countryName = savedCountryName;

      switch (countryCode) {
        case 'MA':
          currency = 'MAD (د.م.)';
          language = 'العربية / Français';
          break;
        case 'ES':
          currency = 'EUR (€)';
          language = 'Español';
          break;
        case 'FR':
        case 'DE':
        case 'IT':
        case 'BE':
        case 'NL':
          currency = 'EUR (€)';
          language = 'Européen';
          break;
        case 'GB':
          currency = 'GBP (£)';
          language = 'English';
          break;
        case 'CA':
          currency = 'CAD (\$)';
          language = 'English / Français';
          break;
        case 'AE':
          currency = 'AED (د.إ)';
          language = 'العربية / English';
          break;
        case 'SA':
          currency = 'SAR (ر.س)';
          language = 'العربية';
          break;
        default:
          currency = '$countryCode Tariffs (USD \$)';
          language = 'English (Global)';
      }
    });
  }

  Future<void> changeCountry() async {
    // 💡 حيدت const من هنا باش ما يبقاش يطلع الخطأ نهائياً
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CountrySelectionScreen()),
    );
    loadSettings();
  }

  Widget aiFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? AppColors.gray : Colors.black54,
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

  Widget tile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.orange),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: isDark ? AppColors.gray : Colors.black54),
        ),
        trailing: onTap == null
            ? null
            : Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
      ),
    );
  }

  void showAiAssistantSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.card : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Assistant',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next generation shopping AI',
                              style: TextStyle(
                                color: isDark ? AppColors.gray : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  aiFeature(
                    icon: Icons.psychology_rounded,
                    title: 'Smart Recommendations',
                    subtitle: 'AI suggests best products for you',
                  ),
                  aiFeature(
                    icon: Icons.trending_down_rounded,
                    title: 'Price Drop Detection',
                    subtitle: 'Detect real discounts instantly',
                  ),
                  aiFeature(
                    icon: Icons.bolt_rounded,
                    title: 'Best Deal Finder',
                    subtitle: 'Find cheapest trusted stores',
                  ),
                  aiFeature(
                    icon: Icons.bar_chart_rounded,
                    title: 'AI Deal Score',
                    subtitle: 'Score every product automatically',
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIAssistantScreen(
                              products: [],
                              userCountry: 'Global',
                              userPosition: null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'Activate AI',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.dark : const Color(0xFFF5F5F5);
    final cardColor = isDark ? AppColors.card : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? AppColors.gray : Colors.black54;

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final loggedIn = user != null;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                Text(
                  'Perfil',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.orange,
                        child: Icon(
                          Icons.person_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loggedIn ? 'Usuario conectado' : 'Invitado',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loggedIn
                                  ? user.email ?? ''
                                  : 'Login to save favorites',
                              style: TextStyle(color: subTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (!loggedIn) ...[
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(isRegister: false),
                          ),
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(isRegister: true),
                          ),
                        );
                      },
                      child: const Text(
                        'Create account',
                        style: TextStyle(color: AppColors.orange),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () async {
                        await AuthService().logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  'Settings (Global Edition)',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                tile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Theme',
                  value: darkMode ? 'Dark Mode' : 'Light Mode',
                  onTap: toggleTheme,
                ),
                tile(
                  icon: Icons.public_rounded,
                  title: 'Country',
                  value: countryName,
                  onTap: changeCountry,
                ),
                tile(
                  icon: Icons.payments_rounded,
                  title: 'Currency',
                  value: currency,
                ),
                tile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  value: language,
                ),
                tile(
                  icon: Icons.notifications_rounded,
                  title: 'Price alerts',
                  value: 'Coming soon',
                ),
                tile(
                  icon: Icons.smart_toy_rounded,
                  title: 'AI Assistant',
                  value: 'Smart deal finder',
                  onTap: () => showAiAssistantSheet(isDark),
                ),
                tile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premium',
                  value: 'Coming soon',
                ),
                tile(
                  icon: Icons.info_rounded,
                  title: 'Version',
                  value: '1.0.0 (Global Edition)',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
