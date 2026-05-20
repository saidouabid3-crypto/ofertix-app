import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CountrySelector extends StatelessWidget {
  final String initialValue;

  final List<Map<String, String>> countries;

  final ValueChanged<String>? onChanged;

  const CountrySelector({
    super.key,
    required this.initialValue,
    required this.countries,
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

      items: countries.map((country) {
        return DropdownMenuItem(
          value: country['code'],

          child: Text('${country['flag']} ${country['name']}'),
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
