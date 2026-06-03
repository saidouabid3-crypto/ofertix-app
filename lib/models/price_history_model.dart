import 'package:cloud_firestore/cloud_firestore.dart';

class PriceHistoryModel {
  final double price;
  final DateTime date;

  const PriceHistoryModel({required this.price, required this.date});

  factory PriceHistoryModel.fromMap(Map<String, dynamic> map) {
    return PriceHistoryModel(
      price: _parsePrice(map['price']),
      // Support both field names: new docs use createdAt (Firestore Timestamp),
      // legacy docs use date (ISO String). Fall back to now() so we never crash.
      date: _parseDate(map['createdAt'] ?? map['date']) ?? DateTime.now(),
    );
  }

  static double _parsePrice(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
