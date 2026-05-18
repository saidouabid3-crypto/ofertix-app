import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StoreChip extends StatelessWidget {
  final String name;

  const StoreChip({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_rounded, size: 16, color: AppColors.orange),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
