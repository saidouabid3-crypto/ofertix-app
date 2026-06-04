import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = _AuthUi.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) _BackButton(ui: ui),
                    Expanded(
                      child: Text('auto.auth_auth_screen.ofertix_account'.tr(),
                        style: TextStyle(
                          color: ui.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                Spacer(),

                Container(
                  width: 132,
                  height: 132,
                  padding: EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 36,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 62,
                    ),
                  ),
                ),

                SizedBox(height: 34),

                Text('auto.auth_auth_screen.ahorra_mas_con_ofertix'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ui.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                    height: 1.05,
                  ),
                ),

                SizedBox(height: 12),

                Text('auto.auth_auth_screen.crea_una_cuenta_para_guardar_favoritos'.tr()
                      .tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 34),

                _FeatureCard(ui: ui),

                Spacer(),

                _GradientButton(
                  text: 'auth.registerButton'.tr(),
                  icon: Icons.person_add_rounded,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                ),

                SizedBox(height: 12),

                _OutlineButton(
                  text: 'auth.loginButton'.tr(),
                  icon: Icons.login_rounded,
                  ui: ui,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                ),

                SizedBox(height: 14),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  child: Text('auto.auth_auth_screen.continuar_como_invitado'.tr(),
                    style: TextStyle(
                      color: ui.muted,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                    ],
                  ),          // Column
                ),            // IntrinsicHeight
              ),              // ConstrainedBox
            ),                // SingleChildScrollView
          ),                  // LayoutBuilder
        ),                    // SafeArea
      ),                      // Container (body)
    );
  }
}

class _AuthUi {
  final bool isDark;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final LinearGradient gradient;

  _AuthUi({
    required this.isDark,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.gradient,
  });

  factory _AuthUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _AuthUi(
      isDark: isDark,
      background: isDark ? AppColors.background : Color(0xFFF7FAFC),
      card: isDark ? AppColors.card : Colors.white,
      text: isDark ? AppColors.white : Color(0xFF071318),
      muted: isDark ? AppColors.gray : Color(0xFF667085),
      border: isDark ? Colors.white10 : Color(0xFFE3EDF0),
      gradient: isDark
          ? AppColors.darkGradient
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFC), Color(0xFFEFF8F5)],
            ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final _AuthUi ui;

  _BackButton({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ui.border),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: ui.text, size: 18),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _AuthUi ui;

  _FeatureCard({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ui.border),
        boxShadow: ui.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          _FeatureRow(
            icon: Icons.favorite_rounded,
            color: AppColors.red,
            title: 'auth.featFavTitle'.tr(),
            subtitle: 'auth.featFavSubtitle'.tr(),
            ui: ui,
          ),
          SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.notifications_active_rounded,
            color: AppColors.orange,
            title: 'auth.featAlertsTitle'.tr(),
            subtitle: 'auth.featAlertsSubtitle'.tr(),
            ui: ui,
          ),
          SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.workspace_premium_rounded,
            color: AppColors.primary,
            title: 'auth.featRewardsTitle'.tr(),
            subtitle: 'auth.featRewardsSubtitle'.tr(),
            ui: ui,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final _AuthUi ui;

  _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ui.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: ui.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  _GradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.26),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final _AuthUi ui;
  final VoidCallback onTap;

  _OutlineButton({
    required this.text,
    required this.icon,
    required this.ui,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.card,
          foregroundColor: ui.text,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: ui.border),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }
}
