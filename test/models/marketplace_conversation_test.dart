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

  // -------------------------------------------------------------------------
  // groupInboxByParticipant tests
  // -------------------------------------------------------------------------

  test('groupInboxByParticipant produces one group per person', () {
    final convA = MarketplaceConversation.fromMap({
      'id': 'conv-a',
      'participants': ['buyer', 'seller'],
      'listing_id': 'listing-1',
    });
    final convB = MarketplaceConversation.fromMap({
      'id': 'conv-b',
      'participants': ['buyer', 'seller'],
      'listing_id': 'listing-2',
    });

    final result = groupInboxByParticipant([convA, convB], 'buyer');

    expect(result.before, 2);
    expect(result.after, 1);
    expect(result.groups.single.otherUserId, 'seller');
    expect(result.groups.single.conversations.length, 2);
    expect(result.groups.single.listingCount, 2);
  });

  test('groupInboxByParticipant aggregates unread counts', () {
    final convA = MarketplaceConversation.fromMap({
      'id': 'conv-a',
      'participants': ['buyer', 'seller'],
      'unread_counts': {'buyer': 3},
      'listing_id': 'listing-1',
    });
    final convB = MarketplaceConversation.fromMap({
      'id': 'conv-b',
      'participants': ['buyer', 'seller'],
      'unread_counts': {'buyer': 2},
      'listing_id': 'listing-2',
    });

    final result = groupInboxByParticipant([convA, convB], 'buyer');

    expect(result.groups.single.totalUnread, 5);
  });

  test('groupInboxByParticipant correctly classifies context counts', () {
    final listing = MarketplaceConversation.fromMap({
      'id': 'conv-listing',
      'participants': ['buyer', 'seller'],
      'listing_id': 'listing-1',
      'reel_id': '',
    });
    final reel = MarketplaceConversation.fromMap({
      'id': 'conv-reel',
      'participants': ['buyer', 'seller'],
      'listing_id': '',
      'reel_id': 'reel-1',
    });
    final direct = MarketplaceConversation.fromMap({
      'id': 'conv-direct',
      'participants': ['buyer', 'seller'],
      'listing_id': '',
      'reel_id': '',
    });

    final result = groupInboxByParticipant([listing, reel, direct], 'buyer');

    final group = result.groups.single;
    expect(group.listingCount, 1);
    expect(group.reelCount, 1);
    expect(group.directCount, 1);
  });

  test('groupInboxByParticipant hides self-conversations', () {
    final selfConvo = MarketplaceConversation.fromMap({
      'id': 'conv-self',
      'participants': ['buyer', 'buyer'],
    });
    final real = MarketplaceConversation.fromMap({
      'id': 'conv-real',
      'participants': ['buyer', 'seller'],
      'listing_id': 'listing-1',
    });

    final result = groupInboxByParticipant([selfConvo, real], 'buyer');

    expect(result.hiddenSelf, 1);
    expect(result.after, 1);
    expect(result.groups.single.otherUserId, 'seller');
  });

  test('groupInboxByParticipant two senders produce two groups', () {
    final fromSeller1 = MarketplaceConversation.fromMap({
      'id': 'conv-s1',
      'participants': ['buyer', 'seller1'],
      'listing_id': 'listing-1',
    });
    final fromSeller2 = MarketplaceConversation.fromMap({
      'id': 'conv-s2',
      'participants': ['buyer', 'seller2'],
      'listing_id': 'listing-2',
    });

    final result = groupInboxByParticipant([fromSeller1, fromSeller2], 'buyer');

    expect(result.after, 2);
    final ids = result.groups.map((g) => g.otherUserId).toSet();
    expect(ids, {'seller1', 'seller2'});
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
