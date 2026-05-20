class UserModel {
  final String id;
  final String email;
  final String name;
  final String country;
  final String currency;
  final int coins;
  final bool premium;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.country,
    required this.currency,
    required this.coins,
    required this.premium,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? 'ES',
      currency: map['currency'] ?? 'EUR',
      coins: map['coins'] ?? 0,
      premium: map['premium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'country': country,
      'currency': currency,
      'coins': coins,
      'premium': premium,
    };
  }
}
