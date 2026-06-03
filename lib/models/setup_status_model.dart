class SetupFeatureModel {
  const SetupFeatureModel({
    required this.key,
    required this.name,
    required this.status,
    required this.ready,
    required this.missingEnv,
    required this.reason,
  });
  final String key;
  final String name;
  final String status;
  final bool ready;
  final List<String> missingEnv;
  final String reason;

  factory SetupFeatureModel.fromMap(String key, Map<String, dynamic> map) {
    return SetupFeatureModel(
      key: key,
      name: map['name']?.toString() ?? key,
      status: (map['effective_status'] ?? map['status'] ?? 'hidden').toString(),
      ready: map['ready'] == true,
      missingEnv: _list(map['missing_env']),
      reason: map['reason']?.toString() ?? '',
    );
  }

  static List<String> _list(dynamic value) {
    if (value is List)
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return const [];
  }
}

class SetupStatusModel {
  const SetupStatusModel({
    required this.missingEnv,
    required this.configuredEnv,
    required this.warnings,
    required this.features,
  });
  final List<String> missingEnv;
  final List<String> configuredEnv;
  final List<String> warnings;
  final List<SetupFeatureModel> features;

  factory SetupStatusModel.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['features'];
    final features = <SetupFeatureModel>[];
    if (rawFeatures is Map) {
      rawFeatures.forEach((key, value) {
        if (value is Map)
          features.add(
            SetupFeatureModel.fromMap(
              key.toString(),
              Map<String, dynamic>.from(value),
            ),
          );
      });
    }
    return SetupStatusModel(
      missingEnv: SetupFeatureModel._list(map['missingEnv']),
      configuredEnv: SetupFeatureModel._list(map['configuredEnv']),
      warnings: SetupFeatureModel._list(map['warnings']),
      features: features,
    );
  }
}
