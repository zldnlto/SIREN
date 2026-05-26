class Inspection {
  const Inspection({
    required this.id,
    required this.annotationDomain,
    required this.inspectorId,
    required this.reportFlagged,
    required this.createdAt,
    this.status,
    this.imageKey,
    this.thumbnailKey,
  });

  final String id;
  final String annotationDomain;
  final String? status;
  final String inspectorId;
  final bool reportFlagged;
  final DateTime createdAt;
  final String? imageKey;
  final String? thumbnailKey;

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'] as String,
        annotationDomain: json['annotation_domain'] as String,
        inspectorId: json['inspector_id'] as String,
        reportFlagged: json['report_flagged'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        status: json['status'] as String?,
        imageKey: json['image_key'] as String?,
        thumbnailKey: json['thumbnail_key'] as String?,
      );
}
