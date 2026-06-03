import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,

        decoration: BoxDecoration(
          border: Border.all(color: AppColors.orange, width: 3),

          borderRadius: BorderRadius.circular(28),
        ),

        child: Stack(
          children: [
            _corner(Alignment.topLeft),

            _corner(Alignment.topRight),

            _corner(Alignment.bottomLeft),

            _corner(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,

      child: Container(
        width: 40,
        height: 40,

        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.orange, width: 5),

            left: BorderSide(color: AppColors.orange, width: 5),
          ),
        ),
      ),
    );
  }
}
