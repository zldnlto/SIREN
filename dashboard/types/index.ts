export type DashboardSummary = {
  total_inspections: number;
  defect_count: number;
  normal_count: number;
  unknown_count: number;
  failed_count: number;
  average_confidence: number | null;
};

export type InspectionListItem = {
  inspection_id: string;
  inspector_id: string;
  created_at: string;
  completed_at: string | null;
  status: "pending" | "processing" | "completed" | "failed" | null;
  quality_state: "defect" | "good" | "unknown" | null;
  annotation_domain: string;
  canonical_class_name: string | null;
  ontology_id: string | null;
  confidence_score: number | null;
};

export type InspectionListResponse = {
  items: InspectionListItem[];
  total: number;
};

export type GuidanceDetail = {
  cause: string;
  action: string[];
  reinspection: string;
  caution: string;
};

export type InspectionDetail = {
  inspection_id: string;
  inspector_id: string;
  image_url: string | null;
  overlay_image_url: string | null;
  status: "pending" | "processing" | "completed" | "failed" | null;
  quality_state: "defect" | "good" | "unknown" | null;
  annotation_domain: string;
  canonical_class_name: string | null;
  ontology_id: string | null;
  confidence_score: number | null;
  guidance: GuidanceDetail | null;
  created_at: string;
  completed_at: string | null;
  error_message: string | null;
};

export type AnalyticsResponse = {
  domain_distribution: { annotation_domain: string; count: number }[];
  defect_type_distribution: {
    ontology_id: string;
    canonical_class_name: string;
    count: number;
  }[];
  quality_state_distribution: { label: string; count: number }[];
};

export type InspectionFilters = {
  status?: string;
  quality_state?: string;
  annotation_domain?: string;
  from?: string;
  to?: string;
  page: number;
  limit: number;
};
