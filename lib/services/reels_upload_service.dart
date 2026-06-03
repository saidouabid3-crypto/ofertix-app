import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';

class ReelsUploadResult {
  final String cloudinaryPublicId;
  final String videoUrlOriginal;
  final String videoUrlOptimized;
  final String thumbnailUrl;
  final int durationSeconds;

  const ReelsUploadResult({
    required this.cloudinaryPublicId,
    required this.videoUrlOriginal,
    required this.videoUrlOptimized,
    required this.thumbnailUrl,
    required this.durationSeconds,
  });

  factory ReelsUploadResult.fromJson(Map<String, dynamic> json) {
    return ReelsUploadResult(
      cloudinaryPublicId: json['cloudinaryPublicId']?.toString() ?? '',
      videoUrlOriginal: json['videoUrlOriginal']?.toString() ?? '',
      videoUrlOptimized: json['videoUrlOptimized']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      durationSeconds:
          int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Smart Reels video uploader routed through the unified multipart transport.
class ReelsUploadService {
  const ReelsUploadService();

  Future<ReelsUploadResult> uploadVideo(File file) async {
    final decoded = await ApiService.instance.postMultipart(
      ApiEndpoints.reelsUploadVideo,
      files: [await http.MultipartFile.fromPath('file', file.path)],
    );

    if (decoded is! Map || decoded['ok'] != true) {
      throw Exception('Upload failed: $decoded');
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    return ReelsUploadResult.fromJson(data);
  }
}
