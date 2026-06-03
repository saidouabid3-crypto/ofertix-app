class VoteSummaryModel {
  final String targetType;
  final String targetId;
  final int hotVotes;
  final int coldVotes;
  final int hotScore;
  final int temperature;
  final String? userVote;

  const VoteSummaryModel({
    required this.targetType,
    required this.targetId,
    required this.hotVotes,
    required this.coldVotes,
    required this.hotScore,
    required this.temperature,
    required this.userVote,
  });

  factory VoteSummaryModel.fromJson(Map<String, dynamic> json) {
    return VoteSummaryModel(
      targetType: json['target_type']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
      hotVotes: _int(json['hot_votes']),
      coldVotes: _int(json['cold_votes']),
      hotScore: _int(json['hot_score'], fallback: 50),
      temperature: _int(json['temperature'], fallback: 50),
      userVote: json['user_vote']?.toString(),
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
