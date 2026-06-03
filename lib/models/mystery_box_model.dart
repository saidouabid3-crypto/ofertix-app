class MysteryBoxModel {
  final String id;
  final String title;
  final String subtitle;
  final String revealHint;
  final String unlockType;
  final String dayKey;
  final bool isOpened;
  final bool canOpen;
  final int streak;

  const MysteryBoxModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.revealHint,
    required this.unlockType,
    required this.dayKey,
    required this.isOpened,
    required this.canOpen,
    required this.streak,
  });

  factory MysteryBoxModel.fromJson(Map<String, dynamic> json) {
    return MysteryBoxModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Blind Deal Box',
      subtitle: json['subtitle']?.toString() ?? '',
      revealHint: json['reveal_hint']?.toString() ?? '',
      unlockType: json['unlock_type']?.toString() ?? 'shake',
      dayKey: json['day_key']?.toString() ?? '',
      isOpened: json['is_opened'] == true,
      canOpen: json['can_open'] != false,
      streak: _int(json['streak']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MysteryRewardModel {
  final String id;
  final String boxId;
  final String rewardType;
  final String title;
  final String description;
  final String valueLabel;
  final String couponCode;
  final String dealUrl;
  final String productId;
  final int coins;
  final double cashbackBoost;
  final String shareText;

  const MysteryRewardModel({
    required this.id,
    required this.boxId,
    required this.rewardType,
    required this.title,
    required this.description,
    required this.valueLabel,
    required this.couponCode,
    required this.dealUrl,
    required this.productId,
    required this.coins,
    required this.cashbackBoost,
    required this.shareText,
  });

  factory MysteryRewardModel.fromJson(Map<String, dynamic> json) {
    return MysteryRewardModel(
      id: json['id']?.toString() ?? '',
      boxId: json['box_id']?.toString() ?? '',
      rewardType: json['reward_type']?.toString() ?? 'coins',
      title: json['title']?.toString() ?? 'Ofertix Reward',
      description: json['description']?.toString() ?? '',
      valueLabel: json['value_label']?.toString() ?? '',
      couponCode: json['coupon_code']?.toString() ?? '',
      dealUrl: json['deal_url']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      coins: MysteryBoxModel._int(json['coins']),
      cashbackBoost: _double(json['cashback_boost']),
      shareText: json['share_text']?.toString() ?? '',
    );
  }

  static double _double(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
