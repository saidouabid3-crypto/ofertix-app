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

  test('dedupeInboxConversations keeps distinct listings for same seller', () {
    final convoA = MarketplaceConversation.fromMap({
      'id': 'conv-a',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'listing_id': 'listing-a',
    });
    final convoB = MarketplaceConversation.fromMap({
      'id': 'conv-b',
      'participants': ['buyer', 'seller'],
      'seller_id': 'seller',
      'buyer_id': 'buyer',
      'listing_id': 'listing-b',
    });

    final result = dedupeInboxConversations([convoA, convoB], 'buyer');

    expect(result.after, 2);
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
