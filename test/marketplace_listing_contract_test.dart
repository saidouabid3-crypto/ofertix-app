import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/core/config/api_endpoints.dart';
import 'package:ofertix/features/marketplace/marketplace_listing_options.dart';
import 'package:ofertix/models/marketplace_item.dart';

void main() {
  test('normalizes legacy marketplace aliases', () {
    final item = MarketplaceItem.fromMap({
      'title': 'Camera',
      'description': 'Working camera',
      'price': '40',
      'currency': 'eur',
      'country': 'es',
      'city': 'Madrid',
      'category': 'electronics',
      'condition': 'used_good',
      'pickupOnly': false,
      'shipsTo': ['es'],
      'images': ['https://cdn.example.com/a.jpg'],
      'image': 'https://cdn.example.com/a.jpg',
      'views': 3,
      'favorites': 2,
      'isActive': true,
    }, 'item-1');

    expect(item.countryCode, 'ES');
    expect(item.currencyCode, 'EUR');
    expect(item.conditionKey, 'good');
    expect(item.deliveryMethodKey, 'shipping');
    expect(item.mainImage, 'https://cdn.example.com/a.jpg');
    expect(item.viewCount, 3);
    expect(item.favoriteCount, 2);
    expect(item.status, 'approved');
  });

  test('listing payload excludes owner and moderation fields', () {
    final item = MarketplaceItem.fromMap({
      'sellerId': 'owner-1',
      'status': 'approved',
      'title': 'Camera',
      'description': 'Working camera',
      'price': 40,
      'currencyCode': 'EUR',
      'countryCode': 'ES',
      'city': 'Madrid',
      'categoryKey': 'electronics',
      'conditionKey': 'good',
      'deliveryMethodKey': 'pickup',
      'images': ['https://cdn.example.com/a.jpg'],
      'coverImage': 'https://cdn.example.com/a.jpg',
    }, 'item-1');

    final payload = item.toListingPayload();
    expect(payload['coverImage'], 'https://cdn.example.com/a.jpg');
    expect(payload['imageCount'], 1);
    expect(payload.containsKey('sellerId'), isFalse);
    expect(payload.containsKey('status'), isFalse);
    expect(payload.containsKey('isActive'), isFalse);
  });

  test('seller identity resolves from supported ownership aliases', () {
    expect(
      MarketplaceItem.fromMap({
        'sellerId': 'seller-primary',
        'userId': 'legacy-user',
      }, 'listing-1').sellerId,
      'seller-primary',
    );
    expect(
      MarketplaceItem.fromMap({'userId': 'legacy-user'}, 'listing-2').sellerId,
      'legacy-user',
    );
    expect(
      MarketplaceItem.fromMap({
        'ownerId': 'legacy-owner',
      }, 'listing-3').sellerId,
      'legacy-owner',
    );
    expect(
      MarketplaceItem.fromMap({
        'creatorId': 'legacy-creator',
      }, 'listing-4').sellerId,
      'legacy-creator',
    );
  });

  test('seller pickers expose the required normalized choices', () {
    expect(
      MarketplaceListingOptions.countries
          .map((country) => country['code'])
          .toList(),
      ['ES', 'FR', 'MA', 'PT', 'IT', 'DE', 'OTHER'],
    );
    expect(MarketplaceListingOptions.conditions, contains('poor'));
    expect(MarketplaceListingOptions.deliveryMethods, [
      'pickup',
      'shipping',
      'both',
    ]);
    expect(MarketplaceListingOptions.popularCities['ES'], contains('Madrid'));
  });

  test('sold listings are not editable or public', () {
    final item = MarketplaceItem.fromMap({
      'sellerId': 'owner-1',
      'status': 'sold',
      'title': 'Camera',
      'description': 'Working camera',
      'price': 40,
      'currencyCode': 'EUR',
      'countryCode': 'ES',
      'city': 'Madrid',
      'categoryKey': 'electronics',
      'conditionKey': 'good',
      'deliveryMethodKey': 'pickup',
      'images': ['https://cdn.example.com/a.jpg'],
      'coverImage': 'https://cdn.example.com/a.jpg',
      'isActive': false,
      'visibleToUsers': false,
      'soldAt': '2026-06-18T10:00:00Z',
    }, 'item-1');

    expect(item.isSold, isTrue);
    expect(item.canEdit, isFalse);
    expect(item.canMarkSold, isFalse);
    expect(item.isPublicMarketplaceVisible, isFalse);
    expect(item.soldAt, isNotNull);
  });

  test('mark sold endpoint uses owner scoped my-items route', () {
    expect(
      ApiEndpoints.marketplaceMyItemMarkSold('item-1'),
      '/marketplace/my-items/item-1/mark-sold',
    );
  });
}
