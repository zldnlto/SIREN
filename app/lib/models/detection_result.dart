import 'detected_defect.dart';

class DetectionResult {
  const DetectionResult({
    required this.id,
    required this.inspectionId,
    required this.defects,
    required this.confidence,
    required this.detectedAt,
  });

  final String id;
  final String inspectionId;
  final List<DetectedDefect> defects;
  final double confidence;
  final DateTime detectedAt;

  bool get hasDefect => defects.any((d) => d.qualityState == 'defect');

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      DetectionResult(
        id: json['id'] as String,
        inspectionId: json['inspection_id'] as String,
        defects: (json['defects'] as List<dynamic>)
            .map((e) => DetectedDefect.fromJson(e as Map<String, dynamic>))
            .toList(),
        confidence: (json['confidence'] as num).toDouble(),
        detectedAt: DateTime.parse(json['detected_at'] as String),
      );
}
