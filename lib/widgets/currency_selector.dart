import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CurrencySelector extends StatelessWidget {
  final String value;

  final List<Map<String, String>> currencies;

  final ValueChanged<String>? onChanged;

  const CurrencySelector({
    super.key,
    required this.value,
    required this.currencies,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,

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

      items: currencies.map((currency) {
        return DropdownMenuItem(
          value: currency['code'],

          child: Text('${currency['symbol']} ${currency['code']}'),
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
