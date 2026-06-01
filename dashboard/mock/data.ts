import type {
  AnalyticsResponse,
  DashboardSummary,
  InspectionDetail,
  InspectionListResponse,
} from "@/types";

export const MOCK_SUMMARY: DashboardSummary = {
  total_inspections: 128,
  defect_count: 43,
  normal_count: 78,
  unknown_count: 3,
  failed_count: 4,
  average_confidence: 0.82,
};

const BASE_ITEMS = Array.from({ length: 10 }, (_, i) => ({
  inspection_id: `00000000-0000-0000-0000-${String(i + 1).padStart(12, "0")}`,
  inspector_id: "00000000-0000-0000-0001-000000000001",
  created_at: new Date(Date.now() - i * 3600000).toISOString(),
  completed_at: new Date(Date.now() - i * 3600000 + 7000).toISOString(),
  status: "completed" as const,
  quality_state: i % 3 === 0 ? ("defect" as const) : ("good" as const),
  annotation_domain: i % 3 === 0 ? "welding" : "surface_treatment",
  canonical_class_name: i % 3 === 0 ? "undercut" : "scratch_paint",
  ontology_id:
    i % 3 === 0
      ? "welding.undercut"
      : "surface_treatment.scratch.paint",
  confidence_score: 0.75 + (i % 5) * 0.04,
}));

export const MOCK_LIST: InspectionListResponse = {
  items: BASE_ITEMS,
  total: 128,
};

export const MOCK_DETAIL: InspectionDetail = {
  inspection_id: "00000000-0000-0000-0000-000000000001",
  inspector_id: "00000000-0000-0000-0001-000000000001",
  image_url: null,
  overlay_image_url: null,
  status: "completed",
  quality_state: "defect",
  annotation_domain: "surface_treatment",
  canonical_class_name: "scratch_paint",
  ontology_id: "surface_treatment.scratch.paint",
  confidence_score: 0.91,
  guidance: {
    cause: "표면 처리 과정에서 도장면에 물리적 접촉이 발생했을 가능성이 있습니다.",
    action: [
      "손상 부위를 육안으로 확인합니다.",
      "필요 시 재도장 또는 표면 보수를 진행합니다.",
    ],
    reinspection:
      "보수 후 동일 영역을 재촬영하여 결함 재발 여부를 확인합니다.",
    caution:
      "AI 조치 가이드는 참고용이며 최종 판단은 품질 관리자가 수행합니다.",
  },
  created_at: new Date(Date.now() - 3600000).toISOString(),
  completed_at: new Date(Date.now() - 3600000 + 7000).toISOString(),
  error_message: null,
};

export const MOCK_ANALYTICS: AnalyticsResponse = {
  domain_distribution: [
    { annotation_domain: "surface_treatment", count: 87 },
    { annotation_domain: "welding", count: 32 },
    { annotation_domain: "cutting", count: 9 },
  ],
  defect_type_distribution: [
    {
      ontology_id: "surface_treatment.scratch.paint",
      canonical_class_name: "scratch_paint",
      count: 24,
    },
    {
      ontology_id: "welding.undercut",
      canonical_class_name: "undercut",
      count: 12,
    },
    {
      ontology_id: "surface_treatment.corrosion.base",
      canonical_class_name: "corrosion_base",
      count: 7,
    },
  ],
  quality_state_distribution: [
    { label: "defect", count: 43 },
    { label: "normal", count: 78 },
    { label: "unknown", count: 7 },
  ],
};
