class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  // Unified context fields (Batch 16F-D)
  final String contextType;
  final String contextId;
  final String contextTitle;
  final String contextThumbnailUrl;
  final double? contextPrice;
  final String contextCurrency;
  // Legacy reel fields — kept for backward compat
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
    this.contextType = '',
    this.contextId = '',
    this.contextTitle = '',
    this.contextThumbnailUrl = '',
    this.contextPrice,
    this.contextCurrency = '',
    this.reelId = '',
    this.reelTitle = '',
    this.reelThumbnailUrl = '',
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawCtxPrice = json['context_price'] ?? json['contextPrice'];
    // Synthesise context from legacy reel fields if no explicit context_type
    var ctxType = (json['context_type'] ?? json['contextType'] ?? '').toString();
    var ctxId = (json['context_id'] ?? json['contextId'] ?? '').toString();
    var ctxTitle = (json['context_title'] ?? json['contextTitle'] ?? '').toString();
    var ctxThumb =
        (json['context_thumbnail_url'] ?? json['contextThumbnailUrl'] ?? '').toString();

    final legacyReel = (json['reel_id'] ?? json['reelId'] ?? '').toString();
    if (ctxType.isEmpty && legacyReel.isNotEmpty) {
      ctxType = 'reel';
      ctxId = legacyReel;
      ctxTitle = (json['reel_title'] ?? json['reelTitle'] ?? '').toString();
      ctxThumb = (json['reel_thumbnail_url'] ?? json['reelThumbnailUrl'] ?? '').toString();
    }

    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? json['conversationId'] ?? '')
          .toString(),
      senderId: (json['sender_id'] ?? json['senderId'] ?? '').toString(),
      senderName: (json['sender_name'] ?? json['senderName'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      contextType: ctxType,
      contextId: ctxId,
      contextTitle: ctxTitle,
      contextThumbnailUrl: ctxThumb,
      contextPrice: rawCtxPrice == null
          ? null
          : (rawCtxPrice is num ? rawCtxPrice.toDouble() : double.tryParse('$rawCtxPrice')),
      contextCurrency:
          (json['context_currency'] ?? json['contextCurrency'] ?? '').toString(),
      reelId: (json['reel_id'] ?? json['reelId'] ?? '').toString(),
      reelTitle: (json['reel_title'] ?? json['reelTitle'] ?? '').toString(),
      reelThumbnailUrl:
          (json['reel_thumbnail_url'] ?? json['reelThumbnailUrl'] ?? '').toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
    );
  }

  bool get hasContext => contextType.isNotEmpty && contextId.isNotEmpty;
  bool get isOffer => type == 'offer';

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
