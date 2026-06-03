import '../core/network/api_client.dart';
import '../models/mystery_box_model.dart';
import 'auth_service.dart';

/// Mystery Box service routed through the unified, locale-aware transport.
/// Firebase ID token is forwarded via `extraHeaders`.
class MysteryBoxService {
  MysteryBoxService._();

  static final MysteryBoxService instance = MysteryBoxService._();

  final ApiService _api = ApiService.instance;
  final AuthService _auth = AuthService.instance;

  Future<Map<String, String>> _authHeader() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesión para abrir el Blind Box.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<MysteryBoxModel> today() async {
    final decoded = await _api.get(
      ApiEndpoints.mysteryBoxToday,
      extraHeaders: await _authHeader(),
    );
    return MysteryBoxModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  Future<MysteryRewardModel> open({String unlockMethod = 'shake'}) async {
    final decoded = await _api.post(
      ApiEndpoints.mysteryBoxOpen,
      extraHeaders: await _authHeader(),
      timeout: const Duration(seconds: 25),
      body: {
        'unlock_method': unlockMethod,
        'client_nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return MysteryRewardModel.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  Future<void> claim(String rewardId) async {
    await _api.post(
      ApiEndpoints.mysteryBoxClaim,
      extraHeaders: await _authHeader(),
      body: {'reward_id': rewardId},
    );
  }
}
