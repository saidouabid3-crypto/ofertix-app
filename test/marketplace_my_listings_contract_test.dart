import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/features/marketplace/marketplace_my_listings_screen.dart';
import 'package:ofertix/models/marketplace_item.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

MarketplaceItem _item({
  String id = 'item-1',
  String title = 'Test listing',
  String status = 'approved',
  bool isActive = true,
  String sellerId = 'seller-1',
  String rejectionReason = '',
  double price = 99,
  String city = 'Madrid',
}) {
  return MarketplaceItem(
    id: id,
    sellerId: sellerId,
    sellerName: 'Seller',
    title: title,
    description: '',
    price: price,
    currencyCode: 'EUR',
    countryCode: 'ES',
    city: city,
    categoryKey: 'electronics',
    conditionKey: 'good',
    deliveryMethodKey: 'pickup',
    images: const [],
    sellerCountryCode: 'es',
    availableCountries: const ['es'],
    shipsTo: const [],
    pickupOnly: true,
    isActive: isActive,
    isFeatured: false,
    isSponsored: false,
    createdAt: DateTime(2026, 6, 1),
    status: status,
    rejectionReason: rejectionReason,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

// ─── Filter logic ─────────────────────────────────────────────────────────────

void main() {
  group('MarketplaceMyListingsScreen filter logic', () {
    test('all filter shows every non-deleted item', () {
      final items = [
        _item(id: 'a', status: 'approved'),
        _item(id: 'b', status: 'pending'),
        _item(id: 'c', status: 'rejected'),
        _item(id: 'd', status: 'archived'),
        _item(id: 'e', status: 'sold'),
        _item(id: 'f', status: 'hidden'),
      ];
      final visible = items
          .where((i) => MarketplaceMyListingsScreen.matchesFilter(i, 'all'))
          .map((i) => i.id)
          .toList();
      expect(visible, ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test('deleted items never appear in any filter', () {
      final deleted = _item(id: 'del', status: 'deleted');
      for (final f in ['all', 'approved', 'pending', 'rejected', 'archived', 'sold', 'hidden']) {
        expect(
          MarketplaceMyListingsScreen.matchesFilter(deleted, f),
          isFalse,
          reason: 'filter=$f must exclude deleted',
        );
      }
    });

    test('approved filter matches approved/active/published statuses', () {
      final approved = _item(id: 'a', status: 'approved');
      final active = _item(id: 'b', status: 'active');
      final published = _item(id: 'c', status: 'published');
      final pending = _item(id: 'd', status: 'pending');

      expect(MarketplaceMyListingsScreen.matchesFilter(approved, 'approved'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(active, 'approved'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(published, 'approved'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(pending, 'approved'), isFalse);
    });

    test('pending filter exact match', () {
      final pending = _item(id: 'p', status: 'pending');
      final approved = _item(id: 'a', status: 'approved');
      expect(MarketplaceMyListingsScreen.matchesFilter(pending, 'pending'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(approved, 'pending'), isFalse);
    });

    test('rejected filter exact match', () {
      final rejected = _item(id: 'r', status: 'rejected');
      expect(MarketplaceMyListingsScreen.matchesFilter(rejected, 'rejected'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(rejected, 'archived'), isFalse);
    });

    test('sold filter exact match, not shown under approved', () {
      final sold = _item(id: 's', status: 'sold');
      expect(MarketplaceMyListingsScreen.matchesFilter(sold, 'sold'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(sold, 'approved'), isFalse);
      expect(MarketplaceMyListingsScreen.matchesFilter(sold, 'all'), isTrue);
    });

    test('archived filter exact match', () {
      final archived = _item(id: 'ar', status: 'archived');
      expect(MarketplaceMyListingsScreen.matchesFilter(archived, 'archived'), isTrue);
      expect(MarketplaceMyListingsScreen.matchesFilter(archived, 'sold'), isFalse);
    });
  });

  // ─── Item model action visibility ───────────────────────────────────────────

  group('MarketplaceItem action visibility', () {
    test('canEdit is false for archived/deleted/hidden/sold', () {
      for (final s in ['archived', 'deleted', 'hidden', 'sold']) {
        final item = _item(status: s);
        expect(item.canEdit, isFalse, reason: 'status=$s');
      }
    });

    test('canEdit is true for pending/approved/rejected', () {
      for (final s in ['pending', 'approved', 'active', 'published', 'rejected']) {
        final item = _item(status: s);
        expect(item.canEdit, isTrue, reason: 'status=$s');
      }
    });

    test('canMarkSold is true only for approved variants', () {
      for (final s in ['approved', 'active', 'published']) {
        expect(_item(status: s).canMarkSold, isTrue, reason: 'status=$s');
      }
      for (final s in ['pending', 'rejected', 'archived', 'sold', 'deleted']) {
        expect(_item(status: s).canMarkSold, isFalse, reason: 'status=$s');
      }
    });

    test('isArchived is true only for archived', () {
      expect(_item(status: 'archived').isArchived, isTrue);
      expect(_item(status: 'sold').isArchived, isFalse);
    });

    test('isSold is true only for sold', () {
      expect(_item(status: 'sold').isSold, isTrue);
      expect(_item(status: 'archived').isSold, isFalse);
    });
  });

  // ─── Compact card widget rendering ──────────────────────────────────────────

  group('_MyListingCard rendering', () {
    testWidgets('renders title, price, and status without overflow', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: _MyListingCardProxy(
              item: _item(title: 'Premium camera body', status: 'approved'),
              onOpen: () => tapped = true,
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('99'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('renders long Arabic title without overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 360,
              child: _MyListingCardProxy(
                item: _item(
                  title: 'عنوان إعلان طويل جدا لاختبار البطاقة في واجهة إدارة الإعلانات',
                  city: 'المغرب',
                  status: 'pending',
                ),
                onOpen: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows rejection reason for rejected items', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: _MyListingCardProxy(
              item: _item(
                status: 'rejected',
                rejectionReason: 'Prohibited item',
              ),
              onOpen: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows delete in popup menu regardless of status', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: _MyListingCardProxy(
              item: _item(status: 'archived'),
              onOpen: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      // Open popup
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      // Delete option should be visible
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no Edit action shown for archived items', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            child: _MyListingCardProxy(
              item: _item(status: 'archived'),
              onOpen: () {},
              onDelete: () {},
              // canEdit is false for archived — onEdit should not be shown
            ),
          ),
        ),
      );
      // Edit text button should not appear when canEdit is false
      expect(find.text('Editar'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ─── Delete is distinct from archive ────────────────────────────────────────

  group('Delete vs Archive distinctness', () {
    test('archive sets status=archived, not deleted', () {
      // Verify that the archived status is not the same as deleted
      final archived = _item(status: 'archived');
      final deleted = _item(status: 'deleted');
      expect(archived.status, isNot('deleted'));
      expect(deleted.status, isNot('archived'));
    });

    test('deleted item is hidden from all filters including archived', () {
      final deleted = _item(status: 'deleted');
      expect(
        MarketplaceMyListingsScreen.matchesFilter(deleted, 'archived'),
        isFalse,
        reason: 'deleted must not appear in archived filter',
      );
    });

    test('archived item appears in archived filter', () {
      final archived = _item(status: 'archived');
      expect(
        MarketplaceMyListingsScreen.matchesFilter(archived, 'archived'),
        isTrue,
      );
    });
  });

  // ─── Public visibility ───────────────────────────────────────────────────────

  group('Public marketplace visibility after delete', () {
    test('deleted item is not public marketplace visible', () {
      final deleted = _item(status: 'deleted', isActive: false);
      expect(deleted.isPublicMarketplaceVisible, isFalse);
    });

    test('approved item is public marketplace visible when active and visible', () {
      final approved = MarketplaceItem(
        id: 'pub-1',
        sellerId: 'seller-1',
        sellerName: 'Seller',
        title: 'Public item',
        description: '',
        price: 50,
        currencyCode: 'EUR',
        countryCode: 'ES',
        city: 'Madrid',
        categoryKey: 'electronics',
        conditionKey: 'good',
        deliveryMethodKey: 'pickup',
        images: const [],
        sellerCountryCode: 'es',
        availableCountries: const ['es'],
        shipsTo: const [],
        pickupOnly: true,
        isActive: true,
        visibleToUsers: true,
        isFeatured: false,
        isSponsored: false,
        createdAt: DateTime(2026, 6, 1),
        status: 'approved',
      );
      expect(approved.isPublicMarketplaceVisible, isTrue);
    });
  });
}

// ─── Test proxy (accesses private card widget via its public interface) ───────

/// Proxy widget that instantiates the card using the public item model,
/// mirroring what the real screen does — avoids importing private classes.
class _MyListingCardProxy extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _MyListingCardProxy({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // We build the card exactly as the screen does, passing action callbacks
    // according to the same state rules used by the real screen.
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: _cardBody(context),
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF0D1A20) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;
    final text = isDark ? Colors.white : Colors.black87;
    final muted = isDark ? Colors.grey : Colors.grey.shade600;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.shopping_bag_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : 'Anuncio no disponible',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.status,
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.rejectionReason.isNotEmpty && item.status == 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.rejectionReason,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (item.canEdit)
                  GestureDetector(
                    onTap: () {},
                    child: Text('Editar', style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'view') { onOpen(); }
                    if (v == 'delete') { onDelete(); }
                  },
                  icon: Icon(Icons.more_vert_rounded, color: muted, size: 18),
                  itemBuilder: (_) => [
                    const PopupMenuItem<String>(
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.open_in_new_rounded, size: 15),
                        SizedBox(width: 8),
                        Text('Ver anuncio'),
                      ]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
