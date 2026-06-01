import { formatCount, formatConfidence } from "@/lib/formatters";
import type { BadgeVariant } from "./badges";
import type { DashboardSummary } from "@/types";

export type KpiViewModel = {
  label: string;
  value: string;
  sub?: string;
  variant: "default" | BadgeVariant;
};

export function presentKpis(summary: DashboardSummary): KpiViewModel[] {
  return [
    {
      label: "총 검사 수",
      value: formatCount(summary.total_inspections),
      variant: "default",
    },
    {
      label: "결함 발견",
      value: formatCount(summary.defect_count),
      variant: "error",
    },
    {
      label: "정상 판정",
      value: formatCount(summary.normal_count),
      variant: "success",
    },
    {
      label: "분석 실패",
      value: formatCount(summary.failed_count),
      variant: "warning",
    },
    {
      label: "평균 Confidence",
      value: formatConfidence(summary.average_confidence),
      sub: "완료된 검사 기준",
      variant: "default",
    },
  ];
}
