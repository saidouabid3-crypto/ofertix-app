class AiRecommendationModel {
  final String message;
  final List<String> productIds;

  const AiRecommendationModel({
    required this.message,
    required this.productIds,
  });

  factory AiRecommendationModel.fromMap(Map<String, dynamic> map) {
    return AiRecommendationModel(
      message: map['message'] ?? '',
      productIds: List<String>.from(map['productIds'] ?? []),
    );
  }
}
