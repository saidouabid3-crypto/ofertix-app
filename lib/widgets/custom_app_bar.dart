import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onSearch,
    this.onProfile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
      ),
      actions: [
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded, color: AppColors.orange),
        ),
        IconButton(
          onPressed: onProfile,
          icon: const Icon(Icons.person_rounded, color: AppColors.orange),
        ),
      ],
    );
  }
}
