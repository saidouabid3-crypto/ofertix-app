import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/features/marketplace/marketplace_item_detail_screen.dart';
import 'package:ofertix/models/marketplace_item.dart';

MarketplaceItem _item({
  String coverImage = '',
  List<String> images = const [],
}) =>
    MarketplaceItem(
      id: 'test-id',
      sellerId: 's1',
      sellerName: 'Seller',
      title: 'Test',
      description: 'Desc',
      price: 10,
      city: 'Madrid',
      sellerCountryCode: 'es',
      availableCountries: const ['es'],
      shipsTo: const [],
      pickupOnly: true,
      isActive: true,
      isFeatured: false,
      isSponsored: false,
      createdAt: null,
      images: images,
      coverImage: coverImage,
    );

void main() {
  group('MarketplaceItemDetailScreen.buildGalleryUrls', () {
    test('coverImage only returns 1 item', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(coverImage: 'https://example.com/cover.jpg'),
      );
      expect(urls, ['https://example.com/cover.jpg']);
    });

    test('images[] 3 returns 3', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(images: [
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
          'https://example.com/3.jpg',
        ]),
      );
      expect(urls.length, 3);
    });

    test('coverImage + images[] deduplicates cover', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(
          coverImage: 'https://example.com/cover.jpg',
          images: [
            'https://example.com/cover.jpg',
            'https://example.com/2.jpg',
          ],
        ),
      );
      expect(urls.length, 2);
      expect(urls.first, 'https://example.com/cover.jpg');
    });

    test('coverImage is first', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(
          coverImage: 'https://example.com/cover.jpg',
          images: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        ),
      );
      expect(urls.first, 'https://example.com/cover.jpg');
      expect(urls.length, 3);
    });

    test('duplicate URLs removed', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(images: [
          'https://example.com/same.jpg',
          'https://example.com/same.jpg',
          'https://example.com/other.jpg',
        ]),
      );
      expect(urls.length, 2);
    });

    test('empty images returns empty list', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(_item());
      expect(urls, isEmpty);
    });

    test('non-http URLs are excluded', () {
      final urls = MarketplaceItemDetailScreen.buildGalleryUrls(
        _item(images: ['local/path/img.jpg', 'https://example.com/valid.jpg']),
      );
      expect(urls, ['https://example.com/valid.jpg']);
    });
  });
}
