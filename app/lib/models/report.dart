class Report {
  const Report({
    required this.id,
    required this.inspectionId,
    required this.status,
    required this.actionChecks,
    required this.createdAt,
    this.resolverId,
    this.resolvedAt,
    this.note,
  });

  final String id;
  final String inspectionId;
  final String status;
  final List<bool> actionChecks;
  final String? resolverId;
  final DateTime? resolvedAt;
  final String? note;
  final DateTime createdAt;

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      inspectionId: json['inspection_id'] as String,
      status: json['status'] as String,
      actionChecks: (json['action_checks'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          [],
      resolverId: json['resolver_id'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspection_id': inspectionId,
      'status': status,
      'action_checks': actionChecks,
      'note': note,
    };
  }
}
