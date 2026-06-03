import '../core/config/api_endpoints.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MessageService {
  MessageService({String? baseUrl, ApiService? api}) : _api = api ?? ApiService.instance;

  static final MessageService instance = MessageService();

  final ApiService _api;
  final AuthService _auth = AuthService.instance;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getIdToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para usar mensajes.');
    }

    return {'Authorization': 'Bearer ${token.trim()}'};
  }

  Future<List<ConversationModel>> getInbox() async {
    final decoded = await _api.get(
      ApiEndpoints.messagesInbox,
      extraHeaders: await _authHeaders(),
    );

    final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ChatMessageModel>> getConversation(String conversationId) async {
    final decoded = await _api.get(
      ApiEndpoints.messageConversation(conversationId),
      extraHeaders: await _authHeaders(),
    );

    final rawItems = decoded is Map<String, dynamic> ? decoded['items'] : decoded;
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConversationModel?> startConversation({
    required String receiverId,
    required String receiverName,
    String receiverPhotoUrl = '',
    required String text,
    String reelId = '',
    String reelTitle = '',
    String reelThumbnailUrl = '',
  }) async {
    final decoded = await _api.post(
      ApiEndpoints.messagesStart,
      extraHeaders: await _authHeaders(),
      body: {
        'receiver_id': receiverId,
        'receiver_name': receiverName,
        'receiver_photo_url': receiverPhotoUrl,
        'text': text.trim(),
        'reel_id': reelId,
        'reel_title': reelTitle,
        'reel_thumbnail_url': reelThumbnailUrl,
      },
    );

    if (decoded is! Map<String, dynamic>) return null;
    return ConversationModel.fromJson(decoded);
  }

  Future<ChatMessageModel?> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final decoded = await _api.post(
      ApiEndpoints.messageConversationSend(conversationId),
      extraHeaders: await _authHeaders(),
      body: {'text': text.trim()},
    );

    if (decoded is! Map<String, dynamic>) return null;
    return ChatMessageModel.fromJson(decoded);
  }

  Future<void> markConversationRead(String conversationId) async {
    await _api.post(
      ApiEndpoints.messageConversationRead(conversationId),
      extraHeaders: await _authHeaders(),
      timeout: const Duration(seconds: 15),
    );
  }
}
