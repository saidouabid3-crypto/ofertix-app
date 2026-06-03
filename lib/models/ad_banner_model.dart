import 'package:cloud_firestore/cloud_firestore.dart';

/// Production model for affiliate banner placements.
/// WHY: Keeping ads as typed models avoids dynamic map bugs in UI.
class AdBannerModel {
  const AdBannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.trackingLink,
    required this.placement,
    required this.isActive,
    this.landingPage,
    this.creativeName,
    this.width,
    this.height,
    this.priority = 0,
  });

  final String id;
  final String title;
  final String description;
  final String trackingLink;
  final String placement;
  final bool isActive;
  final String? landingPage;
  final String? creativeName;
  final int? width;
  final int? height;
  final int priority;

  factory AdBannerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    int? asInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return AdBannerModel(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      trackingLink: (data['trackingLink'] ?? data['landingPage'] ?? '')
          .toString(),
      landingPage: data['landingPage']?.toString(),
      creativeName: data['creativeName']?.toString(),
      placement: (data['placement'] ?? 'home_top').toString(),
      isActive: data['isActive'] == true,
      width: asInt(data['width']),
      height: asInt(data['height']),
      priority: asInt(data['priority']) ?? 0,
    );
  }

  bool get hasValidLink => trackingLink.trim().isNotEmpty;
}
