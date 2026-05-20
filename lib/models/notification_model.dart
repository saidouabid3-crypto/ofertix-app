class NotificationModel {
  final String title;
  final String body;
  final DateTime createdAt;

  const NotificationModel({
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
