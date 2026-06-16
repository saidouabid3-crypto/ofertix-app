import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/models/marketplace_conversation.dart';

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
}
