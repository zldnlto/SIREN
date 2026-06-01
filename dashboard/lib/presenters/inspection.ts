import { getDisplayLabel, DOMAIN_LABELS } from "@/lib/domain-labels";
import {
  formatDate,
  formatDateFull,
  formatConfidenceShort,
  formatInspectionId,
} from "@/lib/formatters";
import { presentStatusBadge, presentQualityBadge } from "./badges";
import type { BadgeViewModel } from "./badges";
import type { InspectionListItem, InspectionDetail } from "@/types";

export type InspectionRowViewModel = {
  id: string;
  idFull: string;
  date: string;
  domain: string;
  defectName: string;
  status: BadgeViewModel;
  quality: BadgeViewModel;
  confidence: string;
};

export type InspectionDetailViewModel = {
  idShort: string;
  domain: string;
  defectName: string;
  canonicalName: string;
  ontologyId: string;
  confidence: string;
  status: BadgeViewModel;
  quality: BadgeViewModel;
  createdAt: string;
  completedAt: string | null;
  errorMessage: string | null;
  hasImage: boolean;
  hasBreadcrumb: boolean;
};

export function presentInspectionRow(item: InspectionListItem): InspectionRowViewModel {
  return {
    id: formatInspectionId(item.inspection_id),
    idFull: item.inspection_id,
    date: formatDate(item.created_at),
    domain: DOMAIN_LABELS[item.annotation_domain] ?? item.annotation_domain ?? "미분류",
    defectName: getDisplayLabel(item.ontology_id, item.canonical_class_name),
    status: presentStatusBadge(item.status),
    quality: presentQualityBadge(item.quality_state),
    confidence: formatConfidenceShort(item.confidence_score),
  };
}

export function presentInspectionDetail(
  detail: InspectionDetail
): InspectionDetailViewModel {
  return {
    idShort: formatInspectionId(detail.inspection_id),
    domain: DOMAIN_LABELS[detail.annotation_domain] ?? detail.annotation_domain,
    defectName: getDisplayLabel(detail.ontology_id, detail.canonical_class_name),
    canonicalName: detail.canonical_class_name ?? "-",
    ontologyId: detail.ontology_id ?? "-",
    confidence: formatConfidenceShort(detail.confidence_score),
    status: presentStatusBadge(detail.status),
    quality: presentQualityBadge(detail.quality_state),
    createdAt: formatDateFull(detail.created_at),
    completedAt: detail.completed_at ? formatDateFull(detail.completed_at) : null,
    errorMessage: detail.error_message,
    hasImage: !!detail.image_url,
    hasBreadcrumb: !!detail.ontology_id,
  };
}

