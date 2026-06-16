import 'package:flutter_test/flutter_test.dart';
import 'package:ofertix/models/user_profile_model.dart';

void main() {
  test('parses minimal public profile payload safely', () {
    final profile = UserProfileModel.fromPublicMap({
      'uid': 'seller-1',
      'display_name': 'Seller One',
      'username': 'seller_one',
      'avatar_url': 'https://example.test/avatar.png',
      'seller_verified': true,
      'city': 'Barcelona',
    });

    expect(profile.uid, 'seller-1');
    expect(profile.displayName, 'Seller One');
    expect(profile.username, 'seller_one');
    expect(profile.photoUrl, 'https://example.test/avatar.png');
    expect(profile.sellerVerified, isTrue);
    expect(profile.city, 'Barcelona');
    expect(profile.email, isEmpty);
    expect(profile.role, 'user');
  });

  test('public profile parser ignores private fields', () {
    final profile = UserProfileModel.fromPublicMap({
      'uid': 'buyer-1',
      'displayName': 'Buyer One',
      'email': 'buyer@example.test',
      'phone': '+34123456789',
      'role': 'admin',
      'isAdmin': true,
      'permissions': ['moderate'],
      'address': 'Private street',
    });

    expect(profile.uid, 'buyer-1');
    expect(profile.displayName, 'Buyer One');
    expect(profile.email, isEmpty);
    expect(profile.role, 'user');
  });

  test('sellerVerified false does not imply a verified trust level', () {
    final profile = UserProfileModel.fromPublicMap({
      'uid': 'seller-2',
      'seller_verified': false,
      'trust_level': 'new_seller',
    });

    expect(profile.sellerVerified, isFalse);
    expect(profile.trustLevel, 'new_seller');
  });

  test('trust_level defaults to new_seller when backend omits it', () {
    final profile = UserProfileModel.fromMap({'uid': 'seller-3'});
    expect(profile.trustLevel, 'new_seller');
  });
}
