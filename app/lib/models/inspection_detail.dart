import 'guidance_detail.dart';

class InspectionDetail {
  const InspectionDetail({
    required this.inspectionId,
    required this.inspectorId,
    this.imageUrl,
    this.overlayImageUrl,
    this.status,
    this.qualityState,
    required this.annotationDomain,
    this.canonicalClassName,
    this.ontologyId,
    this.confidenceScore,
    this.guidance,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  final String inspectionId;
  final String inspectorId;
  final String? imageUrl;
  final String? overlayImageUrl;
  final String? status;
  final String? qualityState;
  final String annotationDomain;
  final String? canonicalClassName;
  final String? ontologyId;
  final double? confidenceScore;
  final GuidanceDetail? guidance;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  factory InspectionDetail.fromJson(Map<String, dynamic> json) => InspectionDetail(
        inspectionId: json['inspection_id'] as String,
        inspectorId: json['inspector_id'] as String,
        imageUrl: json['image_url'] as String?,
        overlayImageUrl: json['overlay_image_url'] as String?,
        status: json['status'] as String?,
        qualityState: json['quality_state'] as String?,
        annotationDomain: json['annotation_domain'] as String,
        canonicalClassName: json['canonical_class_name'] as String?,
        ontologyId: json['ontology_id'] as String?,
        confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
        guidance: json['guidance'] == null
            ? null
            : GuidanceDetail.fromJson(json['guidance'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
        errorMessage: json['error_message'] as String?,
      );
}
