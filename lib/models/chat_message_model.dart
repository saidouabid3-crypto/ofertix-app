class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String reelId;
  final String reelTitle;
  final String reelThumbnailUrl;
  final bool isRead;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.reelId,
    required this.reelTitle,
    required this.reelThumbnailUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? json['conversationId'] ?? '')
          .toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      senderName: (json['sender_name'] ?? json['senderName'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      reelId: (json['reel_id'] ?? json['reelId'] ?? '').toString(),
      reelTitle: (json['reel_title'] ?? json['reelTitle'] ?? '').toString(),
      reelThumbnailUrl:
          (json['reel_thumbnail_url'] ?? json['reelThumbnailUrl'] ?? '')
              .toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
