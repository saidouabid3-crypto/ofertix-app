class ScanResultModel {
  final String code;
  final String type;

  const ScanResultModel({required this.code, required this.type});

  factory ScanResultModel.fromMap(Map<String, dynamic> map) {
    return ScanResultModel(code: map['code'] ?? '', type: map['type'] ?? '');
  }
}
