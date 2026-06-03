import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile_model.dart';
import 'profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel profile;

  EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryController;
  late final TextEditingController _currencyController;

  XFile? _selectedImage;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.displayName);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _countryController = TextEditingController(text: widget.profile.country);
    _currencyController = TextEditingController(text: widget.profile.currency);
    _isCreator = widget.profile.isCreator;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 900,
      maxHeight: 900,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();

    final ok = await provider.saveProfile(
      displayName: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      country: _countryController.text,
      currency: _currencyController.text,
      isCreator: _isCreator,
      image: _selectedImage,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.profile_edit_profile_screen.perfil_actualizado_correctamente'.tr()
                .tr(),
          ),
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    final message = provider.errorMessage ?? 'No se pudo guardar el perfil.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ui = _EditProfileUi.of(context);

    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: ui.background,
          body: Container(
            decoration: BoxDecoration(gradient: ui.gradient),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 32),
                  children: [
                    _TopBar(ui: ui),

                    SizedBox(height: 22),

                    Center(
                      child: _AvatarEditor(
                        ui: ui,
                        profile: widget.profile,
                        selectedImage: _selectedImage,
                        onTap: _pickImage,
                      ),
                    ),

                    SizedBox(height: 26),

                    _Input(
                      controller: _nameController,
                      label: 'Nombre visible',
                      hint: 'Ej: Ofertix Deals',
                      icon: Icons.badge_rounded,
                      validator: (value) {
                        if ((value ?? '').trim().length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 14),

                    _Input(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'ofertix_deals',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        final text = (value ?? '').trim();

                        if (text.length < 3) {
                          return 'Mínimo 3 caracteres';
                        }

                        if (text.length > 24) {
                          return 'Máximo 24 caracteres';
                        }

                        if (!RegExp(r'^[a-zA-Z0-9_@. -]+$').hasMatch(text)) {
                          return 'Usa letras, números o guion bajo';
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: 14),

                    _Input(
                      controller: _bioController,
                      label: 'Bio',
                      hint: 'Comparo ofertas reales y descuentos útiles',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      validator: (value) {
                        if ((value ?? '').trim().length > 140) {
                          return 'Máximo 140 caracteres';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _Input(
                            controller: _countryController,
                            label: 'País',
                            hint: 'ES',
                            icon: Icons.public_rounded,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _Input(
                            controller: _currencyController,
                            label: 'Moneda',
                            hint: 'EUR',
                            icon: Icons.payments_rounded,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    _CreatorCard(
                      ui: ui,
                      enabled: _isCreator,
                      onChanged: (value) {
                        setState(() {
                          _isCreator = value;
                        });
                      },
                    ),

                    if (provider.errorMessage != null) ...[
                      SizedBox(height: 16),
                      _ErrorCard(message: provider.errorMessage!),
                    ],

                    SizedBox(height: 26),

                    SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: provider.isSaving ? null : _save,
                        icon: provider.isSaving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.save_rounded),
                        label: Text(
                          provider.isSaving ? 'Guardando...' : 'Guardar perfil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final _EditProfileUi ui;

  _TopBar({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
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
        SizedBox(width: 12),
        Expanded(
          child: Text('auto.profile_edit_profile_screen.editar_perfil'.tr(),
            style: TextStyle(
              color: ui.text,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  final _EditProfileUi ui;
  final UserProfileModel profile;
  final XFile? selectedImage;
  final VoidCallback onTap;

  _AvatarEditor({
    required this.ui,
    required this.profile,
    required this.selectedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = profile.photoUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 122,
            height: 122,
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(color: ui.card, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: selectedImage != null
                  ? FutureBuilder(
                      future: selectedImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    )
                  : hasNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: profile.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.person_rounded, size: 58, color: Colors.white),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: ui.background, width: 3),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final ui = _EditProfileUi.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: ui.text, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final _EditProfileUi ui;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  _CreatorCard({
    required this.ui,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ui.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.video_collection_rounded, color: Colors.white),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('auto.profile_edit_profile_screen.creator_mode'.tr(),
                  style: TextStyle(
                    color: ui.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text('auto.profile_edit_profile_screen.activa_tu_perfil_para_publicar_ofertas'.tr()
                      .tr(),
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: AppColors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileUi {
  final bool isDark;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final LinearGradient gradient;

  _EditProfileUi({
    required this.isDark,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.gradient,
  });

  factory _EditProfileUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _EditProfileUi(
      isDark: isDark,
      background: isDark ? AppColors.background : AppColors.lightBackground,
      card: isDark ? AppColors.card : AppColors.lightCard,
      text: isDark ? AppColors.white : AppColors.lightText,
      muted: isDark ? AppColors.gray : AppColors.lightGray,
      border: isDark ? Colors.white10 : AppColors.lightBorder,
      gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
    );
  }
}
