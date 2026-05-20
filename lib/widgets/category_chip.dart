import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(category),
      selected: selected,
      onSelected: (_) => onTap?.call(),
      selectedColor: AppColors.orange,
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
