import 'package:flutter/material.dart';

import '../core/tokens.dart';

enum DefectSeverity { good, warning, defect, critical }

extension DefectSeverityX on DefectSeverity {
  String get label => switch (this) {
        DefectSeverity.good => '양호',
        DefectSeverity.warning => '주의',
        DefectSeverity.defect => '결함',
        DefectSeverity.critical => '위험',
      };

  Color get color => switch (this) {
        DefectSeverity.good => AppColors.good,
        DefectSeverity.warning => AppColors.warning,
        DefectSeverity.defect => AppColors.defect,
        DefectSeverity.critical => AppColors.critical,
      };

  Color get containerColor => switch (this) {
        DefectSeverity.good => AppColors.severityGoodContainer,
        DefectSeverity.warning => AppColors.severityWarningContainer,
        DefectSeverity.defect => AppColors.severityDefectContainer,
        DefectSeverity.critical => AppColors.severityCriticalContainer,
      };

  // 백엔드 quality_state("good" | "defect") → 2단계 매핑
  static DefectSeverity fromQualityState(String qualityState) =>
      qualityState == 'good' ? DefectSeverity.good : DefectSeverity.defect;

  // confidence 기반 4단계 매핑 — 모델 평가 후 threshold 튜닝 필요 (현재 placeholder)
  // confidence < 0.50 은 inference pipeline에서 필터링되어 이 함수에 도달하지 않는다고 가정
  static DefectSeverity fromDetection(
    String qualityState,
    double confidence,
  ) {
    if (qualityState == 'good') return DefectSeverity.good;
    if (confidence >= 0.88) return DefectSeverity.critical;
    if (confidence >= 0.70) return DefectSeverity.defect;
    return DefectSeverity.warning; // 0.50 ≤ confidence < 0.70
  }
}
