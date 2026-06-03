import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OfertixLogoMark extends StatelessWidget {
  final double size;
  final bool showText;
  final String subtitle;

  const OfertixLogoMark({
    super.key,
    this.size = 46,
    this.showText = true,
    this.subtitle = 'Deals, AI & shopping',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.lightText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(size * .32),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: .32),
                blurRadius: size * .55,
                offset: Offset(0, size * .2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: size * .58,
              ),
              Positioned(
                right: size * .22,
                top: size * .22,
                child: Container(
                  width: size * .16,
                  height: size * .16,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ofertix',
                style: TextStyle(
                  color: textColor,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? AppColors.gray : AppColors.lightGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
