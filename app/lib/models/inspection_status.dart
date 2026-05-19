import 'package:flutter/material.dart';

import '../core/tokens.dart';

enum InspectionStatus { pending, uploading, processing, completed, failed }

extension InspectionStatusX on InspectionStatus {
  String get label => switch (this) {
        InspectionStatus.pending => '대기',
        InspectionStatus.uploading => '업로드 중',
        InspectionStatus.processing => '분석 중',
        InspectionStatus.completed => '완료',
        InspectionStatus.failed => '실패',
      };

  Color get color => switch (this) {
        InspectionStatus.pending => AppColors.onSurfaceMuted,
        InspectionStatus.uploading => AppColors.primary,
        InspectionStatus.processing => AppColors.warning,
        InspectionStatus.completed => AppColors.good,
        InspectionStatus.failed => AppColors.critical,
      };

  bool get isInProgress =>
      this == InspectionStatus.uploading || this == InspectionStatus.processing;

  // 백엔드 status 값만 매핑. uploading/processing은 클라이언트 전용 — fromString으로 설정 불가
  static InspectionStatus fromString(String value) => switch (value) {
        'pending' => InspectionStatus.pending,
        'completed' => InspectionStatus.completed,
        'failed' => InspectionStatus.failed,
        _ => InspectionStatus.pending,
      };
}
