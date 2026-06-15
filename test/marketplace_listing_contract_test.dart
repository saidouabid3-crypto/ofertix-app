import 'package:flutter_test/flutter_test.dart';
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
}
