import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/models/marketplace_review.dart';

void main() {
  test('parses a review with rating and comment', () {
    final review = MarketplaceReview.fromMap({
      'id': 'listing-1_buyer-1_seller-1',
      'listing_id': 'listing-1',
      'conversation_id': 'conv-1',
      'reviewer_id': 'buyer-1',
      'reviewer_name': 'Buyer',
      'reviewee_id': 'seller-1',
      'rating': 5,
      'comment': 'Great seller, fast response.',
      'created_at': '2026-01-01T00:00:00+00:00',
    });

    expect(review.rating, 5);
    expect(review.comment, 'Great seller, fast response.');
    expect(review.reviewerName, 'Buyer');
    expect(review.createdAt, isNotNull);
  });

  test('summary with no reviews reports honest empty state', () {
    final summary = MarketplaceReviewSummary.fromMap({
      'items': [],
      'average': 0,
      'count': 0,
    });

    expect(summary.items, isEmpty);
    expect(summary.count, 0);
    expect(summary.average, 0);
  });

  test('summary parses average and count from real review data', () {
    final summary = MarketplaceReviewSummary.fromMap({
      'items': [
        {
          'id': 'r1',
          'listing_id': 'listing-1',
          'reviewer_id': 'buyer-1',
          'reviewee_id': 'seller-1',
          'rating': 4,
          'comment': '',
          'created_at': '2026-01-01T00:00:00+00:00',
        },
      ],
      'average': 4.0,
      'count': 1,
    });

    expect(summary.items.length, 1);
    expect(summary.average, 4.0);
    expect(summary.count, 1);
  });
}
