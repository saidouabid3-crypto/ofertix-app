import '../core/network/api_client.dart';
import '../models/community_vote_model.dart';
import 'auth_service.dart';

/// Community voting service routed through the unified, locale-aware transport.
class CommunityService {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;

  Future<VoteSummaryModel> vote({
    required String targetType,
    required String targetId,
    required String vote,
  }) async {
    await _api.post(
      ApiEndpoints.communityVote,
      body: {
        'target_type': targetType,
        'target_id': targetId,
        'user_id': _auth.currentUserId ?? 'mobile_user',
        'vote': vote,
      },
    );

    return summary(targetType: targetType, targetId: targetId);
  }

  Future<VoteSummaryModel> summary({
    required String targetType,
    required String targetId,
  }) async {
    final userId = _auth.currentUserId;

    final decoded = await _api.get(
      ApiEndpoints.communitySummary,
      queryParameters: {
        'target_type': targetType,
        'target_id': targetId,
        if (userId != null) 'user_id': userId,
      },
    );

    return VoteSummaryModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }
}
