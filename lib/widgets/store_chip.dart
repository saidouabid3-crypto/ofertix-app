import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StoreChip extends StatelessWidget {
  final String store;
  final bool selected;
  final VoidCallback? onTap;

  const StoreChip({
    super.key,
    required this.store,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(store),
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
