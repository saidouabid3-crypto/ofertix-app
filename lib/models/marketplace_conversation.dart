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
  });

  factory MarketplaceMessage.fromMap(Map<String, dynamic> map) {
    final rawAmount = map['offer_amount'] ?? map['offerAmount'];
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
    );
  }

  bool get isOffer => type == 'offer' && offerAmount != null;
}

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

/// Removes self-conversations and exact duplicate conversation ids from an
/// inbox list. Kept as a low-level safety net; prefer [groupInboxByParticipant]
/// for the UI layer which also groups by person.
InboxDedupeResult dedupeInboxConversations(
  List<MarketplaceConversation> conversations,
  String currentUserId,
) {
  final seenIds = <String>{};
  var hiddenSelf = 0;
  final result = <MarketplaceConversation>[];

  for (final conversation in conversations) {
    final isSelf =
        conversation.otherUserId(currentUserId).isEmpty ||
        conversation.otherUserId(currentUserId) == currentUserId;
    if (isSelf) {
      hiddenSelf++;
      continue;
    }
    if (!seenIds.add(conversation.id)) continue;
    result.add(conversation);
  }

  return InboxDedupeResult(
    conversations: result,
    before: conversations.length,
    after: result.length,
    hiddenSelf: hiddenSelf,
  );
}

// ---------------------------------------------------------------------------
// Participant-grouped inbox (one row per person, not per conversation)
// ---------------------------------------------------------------------------

/// One row in the grouped inbox: represents all conversations with a single
/// other user, collapsed to show the most recent message and context chips.
class InboxParticipantGroup {
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;
  final String latestMessage;
  final DateTime? latestMessageAt;
  final int totalUnread;
  final int listingCount;
  final int reelCount;
  final int directCount;

  /// Conversations sorted newest-first. latestConversation == first element.
  final List<MarketplaceConversation> conversations;

  const InboxParticipantGroup({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.latestMessage,
    required this.latestMessageAt,
    required this.totalUnread,
    required this.listingCount,
    required this.reelCount,
    required this.directCount,
    required this.conversations,
  });

  MarketplaceConversation get latestConversation => conversations.first;

  /// Best image to display: prefer the user's own avatar, then fall back to
  /// the latest listing/reel thumbnail so the tile never looks empty.
  String get leadingImage {
    if (otherUserPhoto.startsWith('http')) return otherUserPhoto;
    for (final c in conversations) {
      if (c.listingImage.startsWith('http')) return c.listingImage;
      if (c.reelThumbnailUrl.startsWith('http')) return c.reelThumbnailUrl;
    }
    return '';
  }
}

class InboxGroupResult {
  final List<InboxParticipantGroup> groups;
  final int before;
  final int after;
  final int hiddenSelf;
  final int contexts;

  const InboxGroupResult({
    required this.groups,
    required this.before,
    required this.after,
    required this.hiddenSelf,
    required this.contexts,
  });
}

/// Groups conversations by the other participant, hiding self-rows and
/// deduplicating exact conversation IDs.  Produces one [InboxParticipantGroup]
/// per unique other-user, sorted by most-recent message descending.
InboxGroupResult groupInboxByParticipant(
  List<MarketplaceConversation> conversations,
  String currentUserId,
) {
  final seenIds = <String>{};
  final grouped = <String, List<MarketplaceConversation>>{};
  var hiddenSelf = 0;

  for (final conv in conversations) {
    // Skip exact duplicate conversation IDs (safety net).
    if (!seenIds.add(conv.id)) continue;

    final otherId = conv.otherUserId(currentUserId);
    if (otherId.isEmpty || otherId == currentUserId) {
      hiddenSelf++;
      continue;
    }
    grouped.putIfAbsent(otherId, () => []).add(conv);
  }

  final epoch = DateTime.fromMillisecondsSinceEpoch(0);

  final groups = <InboxParticipantGroup>[];
  for (final entry in grouped.entries) {
    final convs = List<MarketplaceConversation>.from(entry.value)
      ..sort((a, b) =>
          (b.lastMessageAt ?? epoch).compareTo(a.lastMessageAt ?? epoch));

    final latest = convs.first;
    final otherId = entry.key;

    groups.add(InboxParticipantGroup(
      otherUserId: otherId,
      otherUserName: latest.otherUserName(currentUserId),
      otherUserPhoto: latest.otherUserPhoto(currentUserId),
      latestMessage: latest.lastMessage,
      latestMessageAt: latest.lastMessageAt,
      totalUnread:
          convs.fold(0, (sum, c) => sum + c.unreadFor(currentUserId)),
      listingCount: convs.where((c) => c.listingId.isNotEmpty).length,
      reelCount: convs
          .where((c) => c.reelId.isNotEmpty && c.listingId.isEmpty)
          .length,
      directCount: convs
          .where((c) => c.listingId.isEmpty && c.reelId.isEmpty)
          .length,
      conversations: convs,
    ));
  }

  groups.sort((a, b) =>
      (b.latestMessageAt ?? epoch).compareTo(a.latestMessageAt ?? epoch));

  return InboxGroupResult(
    groups: groups,
    before: conversations.length,
    after: groups.length,
    hiddenSelf: hiddenSelf,
    contexts: conversations.length - hiddenSelf,
  );
}

class MarketplaceConversationThread {
  final MarketplaceConversation conversation;
  final List<MarketplaceMessage> messages;

  const MarketplaceConversationThread({
    required this.conversation,
    required this.messages,
  });
}

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
