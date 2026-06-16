class MarketplaceReview {
  final String id;
  final String listingId;
  final String conversationId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const MarketplaceReview({
    required this.id,
    required this.listingId,
    required this.conversationId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MarketplaceReview.fromMap(Map<String, dynamic> map) {
    return MarketplaceReview(
      id: (map['id'] ?? '').toString(),
      listingId: (map['listing_id'] ?? '').toString(),
      conversationId: (map['conversation_id'] ?? '').toString(),
      reviewerId: (map['reviewer_id'] ?? '').toString(),
      reviewerName: (map['reviewer_name'] ?? 'User').toString(),
      revieweeId: (map['reviewee_id'] ?? '').toString(),
      rating: map['rating'] is num
          ? (map['rating'] as num).toInt()
          : int.tryParse('${map['rating']}') ?? 0,
      comment: (map['comment'] ?? '').toString(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}

class MarketplaceReviewSummary {
  final List<MarketplaceReview> items;
  final double average;
  final int count;

  const MarketplaceReviewSummary({
    required this.items,
    required this.average,
    required this.count,
  });

  factory MarketplaceReviewSummary.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return MarketplaceReviewSummary(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => MarketplaceReview.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      average: map['average'] is num ? (map['average'] as num).toDouble() : 0,
      count: map['count'] is num ? (map['count'] as num).toInt() : 0,
    );
  }

  static const empty = MarketplaceReviewSummary(items: [], average: 0, count: 0);
}
