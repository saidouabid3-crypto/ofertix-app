import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../profile/creator_profile_screen.dart';

Future<void> openMarketplacePublicProfile({
  required BuildContext context,
  required String source,
  required String userId,
}) async {
  final cleanUserId = userId.trim();
  final available = cleanUserId.isNotEmpty;
  if (kDebugMode) {
    debugPrint(
      '[Marketplace16E-B] open_public_profile source=$source '
      'user=$cleanUserId available=$available',
    );
  }
  if (!available) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('mkt.profile.unavailable'.tr())));
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreatorProfileScreen(
        creatorId: cleanUserId,
        baseUrl: ApiConfig.baseUrl,
      ),
    ),
  );
}
