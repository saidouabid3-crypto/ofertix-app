import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AISearchBar extends StatelessWidget {
  final TextEditingController controller;

  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onAiTap;

  const AISearchBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onAiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
      ),

      child: Row(
        children: [
          const SizedBox(width: 14),

          const Icon(Icons.search, color: AppColors.gray),

          Expanded(
            child: TextField(
              controller: controller,

              style: const TextStyle(color: Colors.white),

              onSubmitted: onSubmitted,

              decoration: const InputDecoration(
                hintText: 'Search with AI...',

                hintStyle: TextStyle(color: AppColors.gray),

                border: InputBorder.none,

                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: onAiTap,

            icon: const Icon(Icons.psychology, color: AppColors.orange),
          ),
        ],
      ),
    );
  }
}
