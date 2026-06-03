import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LanguageSelector extends StatelessWidget {
  final String initialValue;

  final List<Map<String, String>> languages;

  final ValueChanged<String>? onChanged;

  const LanguageSelector({
    super.key,
    required this.initialValue,
    required this.languages,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,

      dropdownColor: AppColors.card,

      decoration: InputDecoration(
        filled: true,

        fillColor: AppColors.card,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: BorderSide.none,
        ),
      ),

      style: const TextStyle(color: Colors.white),

      items: languages.map((language) {
        return DropdownMenuItem(
          value: language['code'],

          child: Text(language['name']!),
        );
      }).toList(),

      onChanged: (value) {
        if (value != null) {
          onChanged?.call(value);
        }
      },
    );
  }
}
