class MarketplaceConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final double listingPrice;
  final String listingCurrency;
  final String listingCity;
  final String sellerId;
  final String buyerId;
  final String status;
  // Legacy reel fields — kept so old conversation documents still parse
  final String reelId;
  final String reelTitle;
  final String reelThumbnailUrl;

  const MarketplaceConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageAt,
    required this.unreadCounts,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.listingPrice,
    required this.listingCurrency,
    required this.listingCity,
    required this.sellerId,
    required this.buyerId,
    required this.status,
    this.reelId = '',
    this.reelTitle = '',
    this.reelThumbnailUrl = '',
  });

  factory MarketplaceConversation.fromMap(Map<String, dynamic> map) {
    return MarketplaceConversation(
      id: (map['id'] ?? '').toString(),
      participants: _stringList(map['participants']),
      participantNames: _stringMap(
        map['participant_names'] ?? map['participantNames'],
      ),
      participantPhotos: _stringMap(
        map['participant_photos'] ?? map['participantPhotos'],
      ),
      lastMessage: (map['last_message'] ?? map['lastMessage'] ?? '').toString(),
      lastSenderId: (map['last_sender_id'] ?? map['lastSenderId'] ?? '')
          .toString(),
      lastMessageAt: _date(map['last_message_at'] ?? map['lastMessageAt']),
      unreadCounts: _intMap(map['unread_counts'] ?? map['unreadCounts']),
      listingId: (map['listing_id'] ?? map['listingId'] ?? '').toString(),
      listingTitle: (map['listing_title'] ?? map['listingTitle'] ?? '')
          .toString(),
      listingImage: (map['listing_image'] ?? map['listingImage'] ?? '')
          .toString(),
      listingPrice: _double(map['listing_price'] ?? map['listingPrice']),
      listingCurrency: (map['listing_currency'] ?? map['listingCurrency'] ?? '')
          .toString(),
      listingCity: (map['listing_city'] ?? map['listingCity'] ?? '').toString(),
      sellerId: (map['seller_id'] ?? map['sellerId'] ?? '').toString(),
      buyerId: (map['buyer_id'] ?? map['buyerId'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      reelId: (map['reel_id'] ?? map['reelId'] ?? '').toString(),
      reelTitle: (map['reel_title'] ?? map['reelTitle'] ?? '').toString(),
      reelThumbnailUrl:
          (map['reel_thumbnail_url'] ?? map['reelThumbnailUrl'] ?? '')
              .toString(),
    );
  }

  String otherUserId(String uid) =>
      participants.firstWhere((id) => id != uid, orElse: () => '');

  String otherUserName(String uid) {
    final otherId = otherUserId(uid);
    return participantNames[otherId] ?? '';
  }

  String otherUserPhoto(String uid) {
    final otherId = otherUserId(uid);
    return participantPhotos[otherId] ?? '';
  }

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;
}

// ---------------------------------------------------------------------------
// Message model with unified context fields (Batch 16F-D)
// ---------------------------------------------------------------------------

/// Optional context attached to a specific message — represents the source
/// content (listing or reel) from which the user sent that particular message.
class MessageContext {
  final String contextType; // 'marketplace_listing', 'reel', 'direct', or ''
  final String contextId;
  final String contextTitle;
  final String contextThumbnailUrl;
  final double? contextPrice;
  final String contextCurrency;

  const MessageContext({
    required this.contextType,
    required this.contextId,
    required this.contextTitle,
    required this.contextThumbnailUrl,
    required this.contextPrice,
    required this.contextCurrency,
  });

  bool get isPresent => contextType.isNotEmpty && contextId.isNotEmpty;
  bool get isListing => contextType == 'marketplace_listing';
  bool get isReel => contextType == 'reel';

  factory MessageContext.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['context_price'] ?? map['contextPrice'];
    return MessageContext(
      contextType: (map['context_type'] ?? map['contextType'] ?? '').toString(),
      contextId: (map['context_id'] ?? map['contextId'] ?? '').toString(),
      contextTitle: (map['context_title'] ?? map['contextTitle'] ?? '').toString(),
      contextThumbnailUrl:
          (map['context_thumbnail_url'] ?? map['contextThumbnailUrl'] ?? '')
              .toString(),
      contextPrice: rawPrice == null ? null : _double(rawPrice),
      contextCurrency:
          (map['context_currency'] ?? map['contextCurrency'] ?? '').toString(),
    );
  }

  static const MessageContext none = MessageContext(
    contextType: '',
    contextId: '',
    contextTitle: '',
    contextThumbnailUrl: '',
    contextPrice: null,
    contextCurrency: '',
  );
}

class MarketplaceMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final double? offerAmount;
  final String offerCurrency;
  final DateTime? createdAt;
  // Per-message source context (Batch 16F-D)
  final MessageContext context;
  // Legacy reel fields — kept for backward compat with old message documents
  final String reelId;
  final String reelTitle;
  final String reelThumbnailUrl;

  const MarketplaceMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.offerAmount,
    required this.offerCurrency,
    required this.createdAt,
    this.context = MessageContext.none,
    this.reelId = '',
    this.reelTitle = '',
    this.reelThumbnailUrl = '',
  });

  factory MarketplaceMessage.fromMap(Map<String, dynamic> map) {
    final rawAmount = map['offer_amount'] ?? map['offerAmount'];

    // Build context from new fields, or synthesise from legacy reel fields
    final contextMap = <String, dynamic>{
      'context_type': map['context_type'] ?? map['contextType'] ?? '',
      'context_id': map['context_id'] ?? map['contextId'] ?? '',
      'context_title': map['context_title'] ?? map['contextTitle'] ?? '',
      'context_thumbnail_url':
          map['context_thumbnail_url'] ?? map['contextThumbnailUrl'] ?? '',
      'context_price': map['context_price'] ?? map['contextPrice'],
      'context_currency': map['context_currency'] ?? map['contextCurrency'] ?? '',
    };

    // If no explicit context type but legacy reel fields exist, synthesise
    final hasLegacyReel =
        (map['reel_id'] ?? map['reelId'] ?? '').toString().isNotEmpty;
    if (contextMap['context_type'].toString().isEmpty && hasLegacyReel) {
      contextMap['context_type'] = 'reel';
      contextMap['context_id'] = (map['reel_id'] ?? map['reelId'] ?? '').toString();
      contextMap['context_title'] =
          (map['reel_title'] ?? map['reelTitle'] ?? '').toString();
      contextMap['context_thumbnail_url'] =
          (map['reel_thumbnail_url'] ?? map['reelThumbnailUrl'] ?? '').toString();
    }

    return MarketplaceMessage(
      id: (map['id'] ?? '').toString(),
      conversationId: (map['conversation_id'] ?? map['conversationId'] ?? '')
          .toString(),
      senderId: (map['sender_id'] ?? map['senderId'] ?? '').toString(),
      senderName: (map['sender_name'] ?? map['senderName'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      type: (map['type'] ?? 'text').toString(),
      offerAmount: rawAmount == null ? null : _double(rawAmount),
      offerCurrency: (map['offer_currency'] ?? map['offerCurrency'] ?? '')
          .toString(),
      createdAt: _date(map['created_at'] ?? map['createdAt']),
      context: MessageContext.fromMap(contextMap),
      reelId: (map['reel_id'] ?? map['reelId'] ?? '').toString(),
      reelTitle: (map['reel_title'] ?? map['reelTitle'] ?? '').toString(),
      reelThumbnailUrl:
          (map['reel_thumbnail_url'] ?? map['reelThumbnailUrl'] ?? '')
              .toString(),
    );
  }

  bool get isOffer => type == 'offer' && offerAmount != null;
}

// ---------------------------------------------------------------------------
// Inbox deduplication safety net (Batch 16F-D)
//
// The backend already returns one canonical row per participant pair.
// This is a client-side safety net to guard against:
//   - Old legacy conversations appearing alongside canonical ones during rollout
//   - Malformed/duplicate responses from the server
//   - Self-conversation documents
//
// The old groupInboxByParticipant / InboxParticipantGroup / _ConversationPickerSheet
// architecture has been removed. The inbox now shows exactly one row per person
// backed by the canonical conversation document.
// ---------------------------------------------------------------------------

class InboxDedupeResult {
  final List<MarketplaceConversation> conversations;
  final int before;
  final int after;
  final int hiddenSelf;

  const InboxDedupeResult({
    required this.conversations,
    required this.before,
    required this.after,
    required this.hiddenSelf,
  });
}

/// Safety-net deduplication: removes self-conversations and duplicate
/// conversation IDs.  Also deduplicates by participant pair, preferring
/// canonical IDs (format: conv_{a}_{b} with no suffix) over legacy ones.
InboxDedupeResult dedupeInboxConversations(
  List<MarketplaceConversation> conversations,
  String currentUserId,
) {
  final seenIds = <String>{};
  final pairBest = <String, MarketplaceConversation>{}; // pairKey -> best conv
  var hiddenSelf = 0;

  for (final conv in conversations) {
    final otherId = conv.otherUserId(currentUserId);
    final isSelf = otherId.isEmpty || otherId == currentUserId;
    if (isSelf) {
      hiddenSelf++;
      continue;
    }
    if (!seenIds.add(conv.id)) continue;

    final pairKey = _sortedPairKey(currentUserId, otherId);
    final rank = _convRank(conv.id, pairKey);

    if (!pairBest.containsKey(pairKey)) {
      pairBest[pairKey] = conv;
    } else {
      final existing = pairBest[pairKey]!;
      final existingRank = _convRank(existing.id, pairKey);
      if (rank > existingRank) {
        pairBest[pairKey] = conv;
      } else if (rank == existingRank) {
        // Same rank — keep the more recently active
        final newAt = conv.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final existAt =
            existing.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (newAt.isAfter(existAt)) pairBest[pairKey] = conv;
      }
    }
  }

  final result = pairBest.values.toList()
    ..sort((a, b) {
      final ta = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

  return InboxDedupeResult(
    conversations: result,
    before: conversations.length,
    after: result.length,
    hiddenSelf: hiddenSelf,
  );
}

String _sortedPairKey(String a, String b) {
  final parts = [a, b]..sort();
  return '${parts[0]}_${parts[1]}';
}

/// Canonical rank for a conversation ID relative to its expected pair key.
/// 2 = new SHA-256 canonical (conv_v1_*)
/// 1 = old underscore canonical (conv_{a}_{b}, exact match, no suffix)
/// 0 = legacy per-listing / per-reel document
int _convRank(String convId, String pairKey) {
  if (convId.startsWith('conv_v1_')) return 2;
  if (convId == 'conv_$pairKey') return 1;
  return 0;
}

// ---------------------------------------------------------------------------
// Thread model
// ---------------------------------------------------------------------------

class MarketplaceConversationThread {
  final MarketplaceConversation conversation;
  final List<MarketplaceMessage> messages;

  const MarketplaceConversationThread({
    required this.conversation,
    required this.messages,
  });
}

// ---------------------------------------------------------------------------
// Parse helpers
// ---------------------------------------------------------------------------

List<String> _stringList(dynamic value) =>
    value is List ? value.map((entry) => entry.toString()).toList() : const [];

Map<String, String> _stringMap(dynamic value) => value is Map
    ? value.map(
        (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
      )
    : const {};

Map<String, int> _intMap(dynamic value) => value is Map
    ? value.map(
        (key, entry) => MapEntry(
          key.toString(),
          entry is num ? entry.toInt() : int.tryParse('$entry') ?? 0,
        ),
      )
    : const {};

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
