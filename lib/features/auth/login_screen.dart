import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/watchlist_provider.dart';
import '../../repositories/auth_repository.dart';
import '../../services/watchlist_service.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool get _validEmail {
    final email = emailController.text.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!_validEmail) {
      _showSnack('Enter a valid email');
      return;
    }

    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.login(email: email, password: password);

      if (!mounted) return;

      // Grab the global WatchlistProvider reference before navigation
      // removes this widget from the tree.
      final watchlistProvider =
          Provider.of<WatchlistProvider>(context, listen: false);

      // Fire guest watchlist migration asynchronously — never blocks auth flow.
      // Refreshes the in-memory cache once migration completes.
      WatchlistService.instance.migrateLocalToFirestore().then((_) {
        watchlistProvider.refresh();
      }).catchError((_) {});

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = _AuthFormUi.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              _TopBar(
                title: 'Welcome Back',
                subtitle: 'Login to continue with Ofertix',
                ui: ui,
              ),

              SizedBox(height: 38),

              _LogoBox(ui: ui),

              SizedBox(height: 36),

              _Input(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                ui: ui,
              ),

              SizedBox(height: 16),

              _Input(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_rounded,
                obscureText: obscurePassword,
                ui: ui,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: ui.muted,
                  ),
                ),
              ),

              SizedBox(height: 28),

              _GradientSubmitButton(
                text: isLoading ? 'Loading...' : 'Login',
                icon: Icons.login_rounded,
                onTap: isLoading ? null : login,
              ),

              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('auto.auth_login_screen.no_account'.tr(),
                    style: TextStyle(color: ui.muted),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.register,
                      );
                    },
                    child: Text('auto.auth_login_screen.create_one'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthFormUi {
  final bool isDark;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final LinearGradient gradient;

  _AuthFormUi({
    required this.isDark,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.gradient,
  });

  factory _AuthFormUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _AuthFormUi(
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

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final _AuthFormUi ui;

  _TopBar({required this.title, required this.subtitle, required this.ui});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context))
          Container(
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
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ui.text,
                size: 18,
              ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ui.text,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ui.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoBox extends StatelessWidget {
  final _AuthFormUi ui;

  _LogoBox({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo.png',
          errorBuilder: (_, __, ___) =>
              Icon(Icons.local_offer_rounded, color: Colors.white, size: 54),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final _AuthFormUi ui;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.ui,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: ui.text, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ui.muted),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: ui.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: ui.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _GradientSubmitButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  _GradientSubmitButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: onTap == null ? null : AppColors.primaryGradient,
          color: onTap == null ? AppColors.gray : null,
          borderRadius: BorderRadius.circular(24),
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
