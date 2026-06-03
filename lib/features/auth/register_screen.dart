import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthRepository _authRepository = AuthRepository.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (!_validEmail) {
      _showSnack('register.invalidEmail'.tr());
      return;
    }

    if (password.length < 6) {
      _showSnack('register.passwordTooShort'.tr());
      return;
    }

    if (password != confirm) {
      _showSnack('register.passwordMismatch'.tr());
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.register(email: email, password: password);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('register.registerFailed'.tr(namedArgs: {'error': e.toString()}));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = _RegisterUi.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      body: Container(
        decoration: BoxDecoration(gradient: ui.gradient),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              _TopBar(
                title: 'register.title'.tr(),
                subtitle: 'register.subtitle'.tr(),
                ui: ui,
              ),

              SizedBox(height: 38),

              Center(
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
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 36),

              _Input(
                controller: emailController,
                hint: 'register.emailHint'.tr(),
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                ui: ui,
              ),

              SizedBox(height: 16),

              _Input(
                controller: passwordController,
                hint: 'register.passwordHint'.tr(),
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

              SizedBox(height: 16),

              _Input(
                controller: confirmPasswordController,
                hint: 'register.confirmPasswordHint'.tr(),
                icon: Icons.verified_user_rounded,
                obscureText: obscurePassword,
                ui: ui,
              ),

              SizedBox(height: 28),

              SizedBox(
                height: 58,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isLoading ? null : AppColors.primaryGradient,
                    color: isLoading ? AppColors.gray : null,
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
                    onPressed: isLoading ? null : register,
                    icon: Icon(Icons.person_add_rounded),
                    label: Text(
                      isLoading ? 'register.creating'.tr() : 'register.createButton'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('auto.auth_register_screen.already_have_account'.tr(),
                    style: TextStyle(color: ui.muted),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: Text('auto.auth_register_screen.login'.tr(),
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

class _RegisterUi {
  final bool isDark;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final LinearGradient gradient;

  _RegisterUi({
    required this.isDark,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.gradient,
  });

  factory _RegisterUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _RegisterUi(
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
  final _RegisterUi ui;

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

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final _RegisterUi ui;
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
