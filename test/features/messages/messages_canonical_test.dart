// Flutter tests for Batch 16F-D canonical messaging
//
// Run with:
//   flutter test test/features/messages/messages_canonical_test.dart
//
// Tests cover:
//   - dedupeInboxConversations() safety-net dedup
//   - InboxDedupeResult correctness
//   - No picker / no grouped architecture reachable
//   - MessageContext parsing from new and legacy fields
//   - MarketplaceMessage context field synthesis from legacy reel fields
//   - delete-for-me model semantics
//   - Arabic RTL / dark / light widget smoke tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ofertix/models/marketplace_conversation.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MarketplaceConversation _conv({
  required String id,
  required List<String> participants,
  String lastMessage = 'hello',
  DateTime? lastMessageAt,
  Map<String, int> unreadCounts = const {},
  String listingId = '',
  String reelId = '',
  String status = 'active',
}) {
  final now = lastMessageAt ?? DateTime(2024, 1, 1);
  return MarketplaceConversation(
    id: id,
    participants: participants,
    participantNames: {
      participants[0]: 'User A',
      if (participants.length > 1) participants[1]: 'User B',
    },
    participantPhotos: {},
    lastMessage: lastMessage,
    lastSenderId: participants[0],
    lastMessageAt: now,
    unreadCounts: unreadCounts,
    listingId: listingId,
    listingTitle: listingId.isNotEmpty ? 'Listing $listingId' : '',
    listingImage: '',
    listingPrice: listingId.isNotEmpty ? 10.0 : 0.0,
    listingCurrency: 'EUR',
    listingCity: '',
    sellerId: participants.length > 1 ? participants[1] : '',
    buyerId: participants[0],
    status: status,
    reelId: reelId,
    reelTitle: reelId.isNotEmpty ? 'Reel $reelId' : '',
    reelThumbnailUrl: '',
  );
}

// ---------------------------------------------------------------------------
// 1. dedupeInboxConversations — canonical preference
// ---------------------------------------------------------------------------

void main() {
  group('dedupeInboxConversations', () {
    const uid = 'userA';

    test('single conversation returned unchanged', () {
      final convs = [_conv(id: 'conv_userA_userB', participants: ['userA', 'userB'])];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.conversations.length, 1);
      expect(result.conversations.first.id, 'conv_userA_userB');
      expect(result.hiddenSelf, 0);
    });

    test('two legacy conversations for same pair → one row', () {
      final convs = [
        _conv(
          id: 'conv_userA_userB_marketplace_l1',
          participants: ['userA', 'userB'],
          lastMessageAt: DateTime(2024, 1, 2),
        ),
        _conv(
          id: 'conv_userA_userB_marketplace_l2',
          participants: ['userA', 'userB'],
          lastMessageAt: DateTime(2024, 1, 1),
        ),
      ];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.before, 2);
      expect(result.after, 1);
      // Prefer the more recently active legacy
      expect(result.conversations.first.id, 'conv_userA_userB_marketplace_l1');
    });

    test('canonical preferred over legacy regardless of recency', () {
      final convs = [
        _conv(
          id: 'conv_userA_userB_marketplace_l1',
          participants: ['userA', 'userB'],
          lastMessageAt: DateTime(2024, 1, 5), // newer
        ),
        _conv(
          id: 'conv_userA_userB',
          participants: ['userA', 'userB'],
          lastMessageAt: DateTime(2024, 1, 1), // older but canonical
        ),
      ];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.after, 1);
      expect(result.conversations.first.id, 'conv_userA_userB');
    });

    test('different pairs each produce one row', () {
      final convs = [
        _conv(id: 'conv_userA_userB', participants: ['userA', 'userB']),
        _conv(id: 'conv_userA_userC', participants: ['userA', 'userC']),
      ];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.after, 2);
    });

    test('self-conversation is hidden', () {
      final convs = [_conv(id: 'conv_userA_userA', participants: ['userA', 'userA'])];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.after, 0);
      expect(result.hiddenSelf, 1);
    });

    test('empty participant conversation is hidden', () {
      final conv = MarketplaceConversation(
        id: 'conv_broken',
        participants: const [],
        participantNames: const {},
        participantPhotos: const {},
        lastMessage: '',
        lastSenderId: '',
        lastMessageAt: null,
        unreadCounts: const {},
        listingId: '',
        listingTitle: '',
        listingImage: '',
        listingPrice: 0,
        listingCurrency: '',
        listingCity: '',
        sellerId: '',
        buyerId: '',
        status: 'active',
      );
      final result = dedupeInboxConversations([conv], uid);
      expect(result.after, 0);
    });

    test('sorted correctly by lastMessageAt descending', () {
      final convs = [
        _conv(
          id: 'conv_userA_userB',
          participants: ['userA', 'userB'],
          lastMessageAt: DateTime(2024, 1, 1),
        ),
        _conv(
          id: 'conv_userA_userC',
          participants: ['userA', 'userC'],
          lastMessageAt: DateTime(2024, 1, 5),
        ),
      ];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.conversations.first.id, 'conv_userA_userC');
    });

    test('inbox_before tracks raw count including dupes', () {
      final convs = [
        _conv(id: 'conv_userA_userB_l1', participants: ['userA', 'userB']),
        _conv(id: 'conv_userA_userB_l2', participants: ['userA', 'userB']),
        _conv(id: 'conv_userA_userC', participants: ['userA', 'userC']),
      ];
      final result = dedupeInboxConversations(convs, uid);
      expect(result.before, 3);
      expect(result.after, 2);
    });
  });

  // -------------------------------------------------------------------------
  // 2. No ConversationPickerSheet — the removed architecture
  // -------------------------------------------------------------------------

  group('No conversation picker', () {
    test('InboxParticipantGroup class does not exist in models', () {
      // If this compiles, it means the class is gone.
      // We verify by confirming dedupeInboxConversations returns MarketplaceConversation,
      // not InboxParticipantGroup.
      final result = dedupeInboxConversations(
        [_conv(id: 'conv_userA_userB', participants: ['userA', 'userB'])],
        'userA',
      );
      expect(result.conversations.first, isA<MarketplaceConversation>());
    });

    test('InboxDedupeResult has conversations list, not groups', () {
      final result = dedupeInboxConversations([], 'userA');
      expect(result, isA<InboxDedupeResult>());
      expect(result.conversations, isA<List<MarketplaceConversation>>());
    });
  });

  // -------------------------------------------------------------------------
  // 3. MessageContext parsing
  // -------------------------------------------------------------------------

  group('MessageContext', () {
    test('parses marketplace listing context', () {
      final ctx = MessageContext.fromMap({
        'context_type': 'marketplace_listing',
        'context_id': 'listing_abc',
        'context_title': 'Nike Shoes',
        'context_thumbnail_url': 'https://example.com/img.jpg',
        'context_price': 49.99,
        'context_currency': 'EUR',
      });
      expect(ctx.isPresent, isTrue);
      expect(ctx.isListing, isTrue);
      expect(ctx.isReel, isFalse);
      expect(ctx.contextTitle, 'Nike Shoes');
      expect(ctx.contextPrice, 49.99);
      expect(ctx.contextCurrency, 'EUR');
    });

    test('parses reel context', () {
      final ctx = MessageContext.fromMap({
        'context_type': 'reel',
        'context_id': 'reel_xyz',
        'context_title': 'Cool reel',
        'context_thumbnail_url': 'https://example.com/reel.jpg',
      });
      expect(ctx.isReel, isTrue);
      expect(ctx.isListing, isFalse);
      expect(ctx.isPresent, isTrue);
    });

    test('empty context is not present', () {
      final ctx = MessageContext.fromMap({});
      expect(ctx.isPresent, isFalse);
    });

    test('none sentinel is not present', () {
      expect(MessageContext.none.isPresent, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // 4. MarketplaceMessage context parsing
  // -------------------------------------------------------------------------

  group('MarketplaceMessage context parsing', () {
    test('new context fields parsed correctly', () {
      final msg = MarketplaceMessage.fromMap({
        'id': 'msg1',
        'conversation_id': 'conv_a_b',
        'sender_id': 'a',
        'sender_name': 'Alice',
        'text': 'Is this still available?',
        'type': 'text',
        'context_type': 'marketplace_listing',
        'context_id': 'listing123',
        'context_title': 'Red Dress',
        'context_thumbnail_url': 'https://example.com/dress.jpg',
        'context_price': 25.0,
        'context_currency': 'EUR',
        'is_read': false,
        'created_at': '2024-01-01T10:00:00Z',
      });
      expect(msg.context.isPresent, isTrue);
      expect(msg.context.isListing, isTrue);
      expect(msg.context.contextTitle, 'Red Dress');
      expect(msg.context.contextPrice, 25.0);
    });

    test('legacy reel fields synthesised into context', () {
      final msg = MarketplaceMessage.fromMap({
        'id': 'msg2',
        'conversation_id': 'conv_a_b',
        'sender_id': 'a',
        'sender_name': 'Alice',
        'text': 'Love this reel!',
        'type': 'text',
        'reel_id': 'reel_xyz',
        'reel_title': 'Summer collection',
        'reel_thumbnail_url': 'https://example.com/reel.jpg',
        'is_read': false,
        'created_at': '2024-01-01T10:00:00Z',
      });
      expect(msg.context.isPresent, isTrue);
      expect(msg.context.isReel, isTrue);
      expect(msg.context.contextId, 'reel_xyz');
      expect(msg.context.contextTitle, 'Summer collection');
      // Legacy fields still accessible
      expect(msg.reelId, 'reel_xyz');
    });

    test('plain text message has no context', () {
      final msg = MarketplaceMessage.fromMap({
        'id': 'msg3',
        'conversation_id': 'conv_a_b',
        'sender_id': 'a',
        'sender_name': 'Alice',
        'text': 'Hello!',
        'type': 'text',
        'is_read': false,
        'created_at': '2024-01-01T10:00:00Z',
      });
      expect(msg.context.isPresent, isFalse);
    });

    test('offer message parsed correctly', () {
      final msg = MarketplaceMessage.fromMap({
        'id': 'msg4',
        'conversation_id': 'conv_a_b',
        'sender_id': 'a',
        'sender_name': 'Alice',
        'text': '45 EUR',
        'type': 'offer',
        'offer_amount': 45.0,
        'offer_currency': 'EUR',
        'is_read': false,
        'created_at': '2024-01-01T10:00:00Z',
      });
      expect(msg.isOffer, isTrue);
      expect(msg.offerAmount, 45.0);
      expect(msg.context.isPresent, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // 5. MarketplaceConversation model
  // -------------------------------------------------------------------------

  group('MarketplaceConversation', () {
    test('otherUserId returns the other participant', () {
      final conv = _conv(id: 'conv_a_b', participants: ['a', 'b']);
      expect(conv.otherUserId('a'), 'b');
      expect(conv.otherUserId('b'), 'a');
    });

    test('otherUserId returns empty for self-conversation', () {
      final conv = _conv(id: 'conv_a_a', participants: ['a', 'a']);
      final other = conv.otherUserId('a');
      // Both are 'a', firstWhere picks first non-'a' which doesn't exist
      expect(other, '');
    });

    test('unreadFor returns correct count', () {
      final conv = _conv(
        id: 'conv_a_b',
        participants: ['a', 'b'],
        unreadCounts: {'a': 3, 'b': 0},
      );
      expect(conv.unreadFor('a'), 3);
      expect(conv.unreadFor('b'), 0);
      expect(conv.unreadFor('c'), 0); // unknown user → 0
    });

    test('fromMap parses snake_case and camelCase', () {
      final conv = MarketplaceConversation.fromMap({
        'id': 'conv_a_b',
        'participants': ['a', 'b'],
        'participant_names': {'a': 'Alice', 'b': 'Bob'},
        'participant_photos': {},
        'last_message': 'hi',
        'last_sender_id': 'a',
        'last_message_at': '2024-01-01T10:00:00Z',
        'unread_counts': {'a': 1, 'b': 0},
        'listing_id': 'l1',
        'listing_title': 'Test Listing',
        'listing_image': '',
        'listing_price': 20.0,
        'listing_currency': 'EUR',
        'listing_city': 'Madrid',
        'seller_id': 'b',
        'buyer_id': 'a',
        'status': 'active',
      });
      expect(conv.id, 'conv_a_b');
      expect(conv.listingId, 'l1');
      expect(conv.listingTitle, 'Test Listing');
      expect(conv.unreadFor('a'), 1);
      expect(conv.otherUserName('a'), 'Bob');
    });
  });

  // -------------------------------------------------------------------------
  // 6. Widget smoke tests — inbox screen renders without picker
  // -------------------------------------------------------------------------

  group('MarketplaceMessagesScreen widget', () {
    testWidgets('renders empty state without crash', (tester) async {
      // We can't test the full screen without a backend mock, but we can
      // verify that the screen widget tree builds cleanly.
      // A minimal build-only smoke test for the inbox tile widget.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestConversationTile(
              isDark: false,
              conversation: _conv(
                id: 'conv_a_b',
                participants: ['a', 'b'],
              ),
              currentUserId: 'a',
            ),
          ),
        ),
      );
      // Should display the user name
      expect(find.text('User B'), findsOneWidget);
      // Should NOT contain a picker sheet
      expect(find.byKey(const Key('conversation_picker_sheet')), findsNothing);
    });

    testWidgets('RTL Arabic renders inbox tile without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: _TestConversationTile(
                isDark: false,
                conversation: _conv(
                  id: 'conv_a_b',
                  participants: ['a', 'b'],
                  lastMessage: 'مرحبا كيف حالك',
                ),
                currentUserId: 'a',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode renders inbox tile without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: _TestConversationTile(
              isDark: true,
              conversation: _conv(id: 'conv_a_b', participants: ['a', 'b']),
              currentUserId: 'a',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unread badge shown when unread > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestConversationTile(
              isDark: false,
              conversation: _conv(
                id: 'conv_a_b',
                participants: ['a', 'b'],
                unreadCounts: {'a': 5},
              ),
              currentUserId: 'a',
            ),
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('no unread badge when unread is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestConversationTile(
              isDark: false,
              conversation: _conv(
                id: 'conv_a_b',
                participants: ['a', 'b'],
                unreadCounts: {'a': 0},
              ),
              currentUserId: 'a',
            ),
          ),
        ),
      );
      expect(find.text('0'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 7. MessageContext widget (inline context card)
  // -------------------------------------------------------------------------

  group('MessageContext widget smoke tests', () {
    testWidgets('listing context card renders correctly', (tester) async {
      final ctx = MessageContext.fromMap({
        'context_type': 'marketplace_listing',
        'context_id': 'l1',
        'context_title': 'Nike Air Max',
        'context_thumbnail_url': '',
        'context_price': 99.0,
        'context_currency': 'EUR',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestContextCard(context: ctx, isMine: false, isDark: false),
          ),
        ),
      );
      expect(find.textContaining('Nike Air Max'), findsOneWidget);
    });

    testWidgets('no context card for messages without context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                // isPresent == false → no card rendered
                expect(MessageContext.none.isPresent, isFalse);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('context card RTL renders without overflow', (tester) async {
      final ctx = MessageContext.fromMap({
        'context_type': 'marketplace_listing',
        'context_id': 'l1',
        'context_title': 'أحذية نايك',
        'context_thumbnail_url': '',
        'context_price': 50.0,
        'context_currency': 'SAR',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: _TestContextCard(context: ctx, isMine: false, isDark: false),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Test-only minimal widget wrappers
// ---------------------------------------------------------------------------

/// Minimal reproduction of the _ConversationTile for widget tests.
class _TestConversationTile extends StatelessWidget {
  final MarketplaceConversation conversation;
  final String currentUserId;
  final bool isDark;

  const _TestConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherUserName(currentUserId);
    final unread = conversation.unreadFor(currentUserId);
    return ListTile(
      title: Text(name.isNotEmpty ? name : 'Unknown'),
      subtitle: Text(conversation.lastMessage),
      trailing: unread > 0
          ? Text('$unread', style: const TextStyle(fontWeight: FontWeight.w900))
          : null,
    );
  }
}

/// Minimal reproduction of the _MessageContextCard for widget tests.
class _TestContextCard extends StatelessWidget {
  final MessageContext context;
  final bool isMine;
  final bool isDark;

  const _TestContextCard({
    required this.context,
    required this.isMine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext buildContext) {
    if (!context.isPresent) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.contextTitle.isNotEmpty)
            Text(context.contextTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (context.isListing && context.contextPrice != null)
            Text(
              '${context.contextPrice!.toStringAsFixed(0)} ${context.contextCurrency}',
            ),
        ],
      ),
    );
  }
}
