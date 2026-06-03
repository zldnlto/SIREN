import 'guidance_response.dart';

class GuidanceDetail {
  const GuidanceDetail({
    required this.cause,
    required this.action,
    required this.reinspection,
    required this.caution,
  });

  final String cause;
  final List<String> action;
  final String reinspection;
  final String caution;

  factory GuidanceDetail.fromJson(Map<String, dynamic> json) => GuidanceDetail(
        cause: json['cause'] as String,
        action: (json['action'] as List<dynamic>).map((e) => e as String).toList(),
        reinspection: json['reinspection'] as String,
        caution: json['caution'] as String,
      );

  GuidanceResponse toGuidanceResponse({
    required String ontologyId,
    required String displayLabel,
    required String qualityState,
  }) {
    return GuidanceResponse(
      ontologyId: ontologyId,
      displayLabel: displayLabel,
      qualityState: qualityState,
      cause: cause,
      actionSteps: action,
      reinspectionCriteria: reinspection,
      disclaimer: caution,
    );
  }
}
