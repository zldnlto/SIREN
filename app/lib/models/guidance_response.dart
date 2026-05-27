class SopChunk {
  const SopChunk({
    required this.section,
    required this.content,
    required this.chunkIndex,
  });

  final String section;
  final String content;
  final int chunkIndex;

  factory SopChunk.fromJson(Map<String, dynamic> json) => SopChunk(
        section: json['section'] as String,
        content: json['content'] as String,
        chunkIndex: json['chunk_index'] as int,
      );
}

class GuidanceResponse {
  const GuidanceResponse({
    required this.ontologyId,
    required this.displayLabel,
    required this.qualityState,
    required this.cause,
    required this.actionSteps,
    required this.reinspectionCriteria,
    required this.disclaimer,
    this.referencedDoc,
    this.sopExcerpt,
  });

  final String ontologyId;
  final String displayLabel;
  final String qualityState;
  final String cause;
  final List<String> actionSteps;
  final String reinspectionCriteria;
  final String disclaimer;
  final String? referencedDoc;
  final List<SopChunk>? sopExcerpt;

  factory GuidanceResponse.fromJson(Map<String, dynamic> json) => GuidanceResponse(
        ontologyId: json['ontology_id'] as String,
        displayLabel: json['display_label'] as String,
        qualityState: json['quality_state'] as String,
        cause: json['cause'] as String,
        actionSteps: (json['action_steps'] as List<dynamic>).map((e) => e as String).toList(),
        reinspectionCriteria: json['reinspection_criteria'] as String,
        disclaimer: json['disclaimer'] as String,
        referencedDoc: json['referenced_doc'] as String?,
        sopExcerpt: json['sop_excerpt'] == null
            ? null
            : (json['sop_excerpt'] as List<dynamic>)
                .map((e) => SopChunk.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}
