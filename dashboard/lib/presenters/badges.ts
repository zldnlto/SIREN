// 어떤 상태값이 어떤 의미인지 결정하는 순수 함수.
// UI(색상, 클래스)는 모른다 — 컴포넌트가 variant를 보고 결정한다.

export type BadgeVariant = "success" | "error" | "warning" | "info" | "neutral";

export type BadgeViewModel = {
  label: string;
  variant: BadgeVariant;
};

const STATUS_MAP: Record<string, BadgeViewModel> = {
  pending:    { label: "대기",   variant: "neutral" },
  processing: { label: "분석중", variant: "info" },
  completed:  { label: "완료",   variant: "success" },
  failed:     { label: "실패",   variant: "warning" },
};

const QUALITY_MAP: Record<string, BadgeViewModel> = {
  defect:  { label: "결함", variant: "error" },
  good:    { label: "정상", variant: "success" },
  normal:  { label: "정상", variant: "success" },
  unknown: { label: "미분류", variant: "neutral" },
};

export function presentStatusBadge(status: string | null): BadgeViewModel {
  if (!status) return { label: "-", variant: "neutral" };
  return STATUS_MAP[status] ?? { label: status, variant: "neutral" };
}

export function presentQualityBadge(state: string | null): BadgeViewModel {
  if (!state) return { label: "-", variant: "neutral" };
  return QUALITY_MAP[state] ?? { label: state, variant: "neutral" };
}
