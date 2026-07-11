import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/models/home_feed.dart';

Map<String, dynamic> _product(
  String id, {
  String store = 'Example',
  String status = 'active',
  bool visibleToUsers = true,
  bool active = true,
  String? affiliateUrl,
  String? productUrl,
  String? sku,
}) {
  return {
    'id': id,
    'name': 'Product $id',
    'status': status,
    'visibleToUsers': visibleToUsers,
    'active': active,
    'isActive': active,
    'store': store,
    'image': 'https://example.com/$id.jpg',
    'newPrice': 10,
    'currency': 'EUR',
    'countryCode': 'global',
    'country': 'global',
    'availableCountries': ['es'],
    'shipsTo': ['es'],
    'affiliateUrl': affiliateUrl ?? 'https://example.com/offer/$id',
    if (productUrl != null) 'productUrl': productUrl,
    if (sku != null) 'sku': sku,
  };
}

List<String> _ids(List products) =>
    products.map((p) => p.id as String).toList();

void main() {
  test('HomeFeed sections dedupe by id, URL, and SKU across source lists', () {
    final feed = HomeFeed.fromMap({
      'sections': {
        'hotDeals': [
          _product(
            'same-id',
            affiliateUrl: 'https://shop.test/a?utm_source=hot',
          ),
        ],
        'globalOnline': [
          _product(
            'same-id',
            affiliateUrl: 'https://shop.test/a?utm_source=online',
          ),
          _product(
            'same-url-a',
            affiliateUrl: 'https://shop.test/b?utm_source=one',
          ),
          _product('same-sku-a', sku: 'SKU-1'),
          _product('online-unique'),
        ],
        'topRated': [
          _product(
            'same-url-b',
            affiliateUrl: 'https://shop.test/b?utm_campaign=two',
          ),
          _product('same-sku-b', sku: 'SKU-1'),
          _product('trending-unique'),
        ],
      },
      'products': [],
    });

    expect(_ids(feed.hotDeals), ['same-id']);
    expect(_ids(feed.globalOnline), [
      'same-url-a',
      'same-sku-a',
      'online-unique',
    ]);
    expect(_ids(feed.topRated), ['trending-unique']);
  });

  test('HomeFeed parser excludes hidden inactive and DHgate products', () {
    final feed = HomeFeed.fromMap({
      'sections': {
        'hotDeals': [
          _product('hidden', status: 'hidden'),
          _product('inactive', active: false),
          _product('invisible', visibleToUsers: false),
          _product('dhgate', store: 'DHgate'),
          _product('safe'),
        ],
      },
      'products': [
        _product('flat-hidden', status: 'removed'),
        _product('flat-dhgate', productUrl: 'https://www.dhgate.com/product/x'),
        _product('flat-safe'),
      ],
    });

    expect(_ids(feed.hotDeals), ['safe']);
    expect(_ids(feed.products), ['flat-safe']);
  });
}
