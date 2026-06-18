import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/models/marketplace_conversation.dart';
import 'package:ofertix/models/marketplace_item.dart';

void main() {
  test('parses marketplace conversation envelope fields', () {
    final conversation = MarketplaceConversation.fromMap({
      'id': 'conv-1',
      'participants': ['buyer', 'seller'],
      'participant_names': {'buyer': 'Buyer', 'seller': 'Seller'},
      'unread_counts': {'buyer': 2},
      'listing_id': 'listing-1',
      'listing_title': 'Phone',
      'listing_price': 250,
      'listing_currency': 'EUR',
      'seller_id': 'seller',
      'buyer_id': 'buyer',
    });

    expect(conversation.listingId, 'listing-1');
    expect(conversation.otherUserName('buyer'), 'Seller');
    expect(conversation.unreadFor('buyer'), 2);
  });

  test('parses offer message fields', () {
    final message = MarketplaceMessage.fromMap({
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'sender_id': 'buyer',
      'type': 'offer',
      'offer_amount': 200,
      'offer_currency': 'EUR',
      'created_at': '2026-06-15T10:00:00Z',
    });

    expect(message.isOffer, isTrue);
    expect(message.offerAmount, 200);
    expect(message.createdAt, isNotNull);
  });

  test('derives other participant id safely', () {
    final conversation = MarketplaceConversation.fromMap({
      'id': 'conv-1',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
    });

    expect(conversation.otherUserId('buyer'), 'seller');
    expect(conversation.otherUserId('seller'), 'buyer');
    expect(conversation.otherUserId(''), 'buyer');
  });

  test('missing participant id returns empty profile target', () {
    final conversation = MarketplaceConversation.fromMap({
      'id': 'conv-1',
      'participants': <String>[],
    });

    expect(conversation.otherUserId('buyer'), '');
    expect(conversation.otherUserName('buyer'), '');
    expect(conversation.otherUserPhoto('buyer'), '');
  });

  test('dedupeInboxConversations hides self-conversations', () {
    final real = MarketplaceConversation.fromMap({
      'id': 'conv-real',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
    });
    final selfConvo = MarketplaceConversation.fromMap({
      'id': 'conv-self',
      'participants': ['buyer', 'buyer'],
      'seller_id': 'buyer',
      'buyer_id': 'buyer',
    });

    final result = dedupeInboxConversations([real, selfConvo], 'buyer');

    expect(result.before, 2);
    expect(result.after, 1);
    expect(result.hiddenSelf, 1);
    expect(result.conversations.single.id, 'conv-real');
  });

  test('dedupeInboxConversations removes exact duplicate ids', () {
    final conversation = MarketplaceConversation.fromMap({
      'id': 'conv-dup',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
    });

    final result = dedupeInboxConversations([
      conversation,
      conversation,
    ], 'buyer');

    expect(result.before, 2);
    expect(result.after, 1);
    expect(result.hiddenSelf, 0);
  });

  // Canonical dedup: two legacy conversations for the same pair are merged
  // into one row (the backend now returns one canonical conversation per pair,
  // and the client safety-net dedup enforces the same rule).
  test('dedupeInboxConversations collapses multiple conversations for same pair to one row', () {
    final convoA = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller_marketplace_listing_a',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'listing_id': 'listing-a',
      'last_message_at': '2024-01-02T00:00:00Z',
    });
    final convoB = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller_marketplace_listing_b',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'listing_id': 'listing-b',
      'last_message_at': '2024-01-01T00:00:00Z',
    });

    final result = dedupeInboxConversations([convoA, convoB], 'buyer');

    // One conversation per pair — the canonical WhatsApp behaviour
    expect(result.after, 1);
    // Prefers the more recently active one (convoA)
    expect(result.conversations.single.id, 'conv_buyer_seller_marketplace_listing_a');
  });

  test('dedupeInboxConversations canonical id preferred over legacy', () {
    final canonical = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'last_message_at': '2024-01-01T00:00:00Z',
    });
    final legacy = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller_marketplace_listing_a',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'last_message_at': '2024-01-05T00:00:00Z', // newer but legacy
    });

    final result = dedupeInboxConversations([canonical, legacy], 'buyer');

    expect(result.after, 1);
    expect(result.conversations.single.id, 'conv_buyer_seller');
  });

  // conv_v1_* is rank 2 and must beat conv_{a}_{b} (rank 1) regardless of recency
  test('dedupeInboxConversations conv_v1_* preferred over old underscore canonical', () {
    const v1Id = 'conv_v1_abc123def456abc123def456abc123def456abc123def456abc123def456ab';
    final v1Conv = MarketplaceConversation.fromMap({
      'id': v1Id,
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'last_message_at': '2024-01-01T00:00:00Z', // older
    });
    final oldCanonical = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'last_message_at': '2024-01-05T00:00:00Z', // newer but rank 1
    });

    final result = dedupeInboxConversations([v1Conv, oldCanonical], 'buyer');

    expect(result.after, 1);
    expect(result.conversations.single.id, v1Id);
  });

  test('dedupeInboxConversations two different sellers produce two rows', () {
    final fromSeller1 = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller1',
      'participants': ['buyer', 'seller1'],
      'listing_id': 'listing-1',
    });
    final fromSeller2 = MarketplaceConversation.fromMap({
      'id': 'conv_buyer_seller2',
      'participants': ['buyer', 'seller2'],
      'listing_id': 'listing-2',
    });

    final result = dedupeInboxConversations([fromSeller1, fromSeller2], 'buyer');

    expect(result.after, 2);
    final ids = result.conversations.map((c) => c.otherUserId('buyer')).toSet();
    expect(ids, {'seller1', 'seller2'});
  });

  // -------------------------------------------------------------------------
  // MessageContext
  // -------------------------------------------------------------------------

  test('MessageContext.none is not present', () {
    expect(MessageContext.none.isPresent, isFalse);
  });

  test('MessageContext with type and id is present', () {
    final ctx = MessageContext.fromMap({
      'context_type': 'marketplace_listing',
      'context_id': 'listing-1',
      'context_title': 'Phone',
      'context_price': 120.0,
      'context_currency': 'EUR',
    });
    expect(ctx.isPresent, isTrue);
    expect(ctx.isListing, isTrue);
    expect(ctx.isReel, isFalse);
    expect(ctx.contextTitle, 'Phone');
    expect(ctx.contextPrice, 120.0);
  });

  test('MarketplaceMessage synthesises context from legacy reel fields', () {
    final msg = MarketplaceMessage.fromMap({
      'id': 'msg-reel',
      'conversation_id': 'conv-1',
      'sender_id': 'buyer',
      'sender_name': 'Buyer',
      'text': 'Hello from reel',
      'type': 'text',
      'reel_id': 'reel-xyz',
      'reel_title': 'Cool reel',
      'reel_thumbnail_url': 'https://example.com/reel.jpg',
      'is_read': false,
      'created_at': '2024-01-01T10:00:00Z',
    });
    expect(msg.context.isPresent, isTrue);
    expect(msg.context.isReel, isTrue);
    expect(msg.context.contextId, 'reel-xyz');
    expect(msg.reelId, 'reel-xyz');
  });

  test(
    'public marketplace visibility requires approved active visible item',
    () {
      final visible = MarketplaceItem.fromMap({
        'id': 'item-visible',
        'sellerId': 'seller',
        'title': 'Phone',
        'description': 'Clean phone',
        'price': 120,
        'city': 'Madrid',
        'images': <String>[],
        'sellerCountryCode': 'es',
        'availableCountries': ['es'],
        'shipsTo': <String>[],
        'pickupOnly': true,
        'isActive': true,
        'visibleToUsers': true,
        'status': 'approved',
      }, 'item-visible');
      final pending = MarketplaceItem.fromMap({
        ...visible.toMap(),
        'id': 'item-pending',
        'status': 'pending',
      }, 'item-pending');

      expect(visible.isPublicMarketplaceVisible, isTrue);
      expect(pending.isPublicMarketplaceVisible, isFalse);
    },
  );
}
