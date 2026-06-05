import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_languages.dart';
import '../../core/constants/app_countries.dart';

import '../cashback/cashback_screen.dart';
import '../admin/admin_command_center_screen.dart';
import '../../services/profile_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider()..initialize(),
      child: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Settings'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _HeaderCard(
                  title: 'Ofertix Settings',
                  subtitle: 'Control your shopping experience',
                  icon: Icons.settings_rounded,
                ),

                const SizedBox(height: 28),

                const _SectionTitle('Language'),

                ...AppLanguages.supported.map((lang) {
                  final selected = provider.language == lang['code'];

                  return _OptionTile(
                    title: lang['name']!,
                    subtitle: lang['code']!.toUpperCase(),
                    selected: selected,
                    icon: Icons.language_rounded,
                    onTap: () async {
                      await provider.changeLanguage(lang['code']!);

                      if (!context.mounted) return;

                      await context.setLocale(Locale(lang['code']!));
                    },
                  );
                }),

                const SizedBox(height: 28),

                const _SectionTitle('Country'),

                ...AppCountries.supported.map((country) {
                  final selected = provider.country == country['code'];

                  return _OptionTile(
                    title: country['name']!,
                    subtitle: '${country['code']} • ${country['currency']}',
                    selected: selected,
                    icon: Icons.public_rounded,
                    onTap: () {
                      provider.changeCountry(
                        countryCode: country['code']!,
                        currencyCode: country['currency']!,
                      );
                    },
                  );
                }),

                const SizedBox(height: 28),

                const _SectionTitle('Preferences'),

                _SwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use premium dark theme',
                  value: provider.darkMode,
                  icon: Icons.dark_mode_rounded,
                  onChanged: provider.changeTheme,
                ),

                _SwitchTile(
                  title: 'Notifications',
                  subtitle: 'Deals, price drops and AI alerts',
                  value: true,
                  icon: Icons.notifications_active_rounded,
                  onChanged: (_) {},
                ),

                const SizedBox(height: 28),

                const _SectionTitle('Business'),

                _ActionTile(
                  title: 'Cashback Wallet',
                  subtitle: 'Check your cashback balance',
                  icon: Icons.savings_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CashbackScreen()),
                    );
                  },
                ),

                FutureBuilder<bool>(
                  future: ProfileService.instance.isCurrentUserAdmin(),
                  builder: (context, snap) {
                    if (snap.data != true) return const SizedBox.shrink();
                    return _ActionTile(
                      title: 'admin.commandCenter'.tr(),
                      subtitle: 'admin.commandCenterSubtitle'.tr(),
                      icon: Icons.admin_panel_settings_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCommandCenterScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),

                _ActionTile(
                  title: 'Privacy Policy',
                  subtitle: 'Data, analytics and affiliate tracking',
                  icon: Icons.privacy_tip_rounded,
                  onTap: () {},
                ),

                _ActionTile(
                  title: 'About Ofertix',
                  subtitle: 'AI shopping revolution',
                  icon: Icons.info_rounded,
                  onTap: () {},
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 52),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.orange : AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: selected ? Colors.white70 : AppColors.gray),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Colors.white)
            : null,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: SwitchListTile(
        value: value,
        activeThumbColor: AppColors.orange,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppColors.orange),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.gray)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.orange),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.gray)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      ),
    );
  }
}
