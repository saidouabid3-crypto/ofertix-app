import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/country_service.dart';

class MarketBanner extends StatelessWidget {
  const MarketBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CountryService.instance.getCurrentCountry(),
      builder: (context, snapshot) {
        final code = snapshot.data ?? 'es';
        final flag = CountryService.instance.getCountryFlag(code);
        final name = CountryService.instance.getCountryName(code);
        final currency = CountryService.instance.getCountryCurrency(code);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EAEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('market.banner'.tr(args: [name, currency]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E2022),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.countrySelection),
                child: Text('common.change'.tr(),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
