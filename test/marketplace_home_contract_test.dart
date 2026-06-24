import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/features/marketplace/marketplace_home_screen.dart';
import 'package:ofertix/models/marketplace_item.dart';

MarketplaceItem _item({
  String id = 'item-1',
  String title = 'Premium camera with long but safe title',
  String description = 'Mirrorless camera in good condition',
  String categoryKey = 'electronics',
  String city = 'Madrid',
  String status = 'approved',
  bool isActive = true,
  List<String> images = const [],
}) {
  return MarketplaceItem(
    id: id,
    sellerId: 'seller-1',
    sellerName: 'Seller',
    title: title,
    description: description,
    price: 120,
    currencyCode: 'EUR',
    countryCode: 'ES',
    city: city,
    categoryKey: categoryKey,
    conditionKey: 'good',
    deliveryMethodKey: 'pickup',
    images: images,
    sellerCountryCode: 'es',
    availableCountries: const ['es'],
    shipsTo: const [],
    pickupOnly: true,
    isActive: isActive,
    isFeatured: false,
    isSponsored: false,
    createdAt: DateTime(2026, 6, 24),
    status: status,
  );
}

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        // Height reflects real grid childAspectRatio 0.82: 190 / 0.82 ≈ 232
        body: Center(child: SizedBox(width: 190, height: 232, child: child)),
      ),
    ),
  );
}

void main() {
  group('MarketplaceHomeScreen.visibleItemsForHome', () {
    test('keeps only active public statuses before filtering', () {
      final visible = _item(id: 'visible');
      final pending = _item(id: 'pending', status: 'pending');
      final hidden = _item(id: 'hidden', status: 'hidden');
      final sold = _item(id: 'sold', status: 'sold', isActive: false);

      final result = MarketplaceHomeScreen.visibleItemsForHome(
        items: [visible, pending, hidden, sold],
        selectedCategory: 'all',
        searchQuery: '',
      );

      expect(result.map((item) => item.id), ['visible']);
    });

    test('preserves category and search behavior', () {
      final camera = _item(id: 'camera', title: 'Sony camera');
      final sneakers = _item(
        id: 'sneakers',
        title: 'Running shoes',
        categoryKey: 'fashion',
      );

      expect(
        MarketplaceHomeScreen.visibleItemsForHome(
          items: [camera, sneakers],
          selectedCategory: 'electronics',
          searchQuery: '',
        ).map((item) => item.id),
        ['camera'],
      );
      expect(
        MarketplaceHomeScreen.visibleItemsForHome(
          items: [camera, sneakers],
          selectedCategory: 'all',
          searchQuery: 'shoes',
        ).map((item) => item.id),
        ['sneakers'],
      );
    });
  });

  group('MarketplaceListingCard', () {
    testWidgets('renders missing image, title, price, and location safely', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          MarketplaceListingCard(
            item: _item(title: '', city: ''),
            onTap: (_) => tapped = true,
          ),
        ),
      );

      expect(find.text('120 EUR'), findsOneWidget);
      expect(find.text('ES'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(MarketplaceListingCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders long RTL marketplace titles without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MarketplaceListingCard(
            item: _item(
              title:
                  'عنوان إعلان طويل جدا لاختبار البطاقة في واجهة السوق العربية',
              city: 'برشلونة',
            ),
            onTap: (_) {},
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
