class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final String reelId;
  final String reelTitle;
  final String reelThumbnailUrl;
  final String creatorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageAt,
    required this.unreadCounts,
    required this.reelId,
    required this.reelTitle,
    required this.reelThumbnailUrl,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? '').toString(),
      participants: _stringList(json['participants']),
      participantNames: _stringMap(
        json['participant_names'] ?? json['participantNames'],
      ),
      participantPhotos: _stringMap(
        json['participant_photos'] ?? json['participantPhotos'],
      ),
      lastMessage: (json['last_message'] ?? json['lastMessage'] ?? '')
          .toString(),
      lastSenderId: (json['last_sender_id'] ?? json['lastSenderId'] ?? '')
          .toString(),
      lastMessageAt: _toDate(json['last_message_at'] ?? json['lastMessageAt']),
      unreadCounts: _intMap(json['unread_counts'] ?? json['unreadCounts']),
      reelId: (json['reel_id'] ?? json['reelId'] ?? '').toString(),
      reelTitle: (json['reel_title'] ?? json['reelTitle'] ?? '').toString(),
      reelThumbnailUrl:
          (json['reel_thumbnail_url'] ?? json['reelThumbnailUrl'] ?? '')
              .toString(),
      creatorId: (json['creator_id'] ?? json['creatorId'] ?? '').toString(),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _toDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  String otherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
  }

  String otherUserName(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantNames[otherId] ?? 'Ofertix User';
  }

  String otherUserPhoto(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantPhotos[otherId] ?? '';
  }

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
      );
    }
    return const {};
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        if (val is int) return MapEntry(key.toString(), val);
        if (val is num) return MapEntry(key.toString(), val.toInt());
        return MapEntry(key.toString(), int.tryParse(val.toString()) ?? 0);
      });
    }
    return const {};
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
