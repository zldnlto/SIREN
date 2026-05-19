class DetectedDefect {
  const DetectedDefect({
    required this.ontologyId,
    required this.displayLabel,
    required this.qualityState,
    required this.canonicalClassName,
    required this.annotationDomain,
    required this.confidenceScore,
    this.bbox,
    this.gradcamKey,
  });

  final String ontologyId;
  final String displayLabel;
  final String qualityState; // "defect" | "good"
  final String canonicalClassName;
  final String annotationDomain;
  final double confidenceScore;
  final List<double>? bbox;
  final String? gradcamKey;

  factory DetectedDefect.fromJson(Map<String, dynamic> json) => DetectedDefect(
        ontologyId: json['ontology_id'] as String? ?? '',
        displayLabel: json['display_label'] as String? ?? '',
        qualityState: json['quality_state'] as String,
        canonicalClassName: json['canonical_class_name'] as String,
        annotationDomain: json['annotation_domain'] as String? ?? '',
        confidenceScore: (json['confidence_score'] as num).toDouble(),
        bbox: (json['bbox'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
        gradcamKey: json['gradcam_key'] as String?,
      );
}
