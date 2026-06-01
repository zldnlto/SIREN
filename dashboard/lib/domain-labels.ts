export const DOMAIN_LABELS: Record<string, string> = {
  surface_treatment: "표면처리",
  welding: "용접",
  cutting: "절단",
};

export const QUALITY_STATE_LABELS: Record<string, string> = {
  defect: "결함",
  good: "정상",
  normal: "정상",
  unknown: "미분류",
};

export const STATUS_LABELS: Record<string, string> = {
  pending: "대기",
  processing: "분석중",
  completed: "완료",
  failed: "실패",
};

const ONTOLOGY_SLUG_MAP: Record<string, string> = {
  surface_treatment: "표면처리",
  welding: "용접",
  cutting: "절단",
  scratch: "스크래치",
  paint: "도장",
  crack: "균열",
  corrosion: "부식",
  dent: "찍힘",
  pit: "피트",
  inclusion: "개재물",
  porosity: "기공",
  undercut: "언더컷",
  overlap: "오버랩",
  spatter: "스패터",
  burr: "버",
  delamination: "박리",
  base: "모재",
  weld: "용접부",
};

export function getOntologyBreadcrumb(ontologyId: string): string[] {
  return ontologyId
    .split(".")
    .map((slug) => ONTOLOGY_SLUG_MAP[slug] ?? slug);
}

export function getDisplayLabel(
  ontologyId: string | null,
  canonicalClassName: string | null
): string {
  if (!ontologyId && !canonicalClassName) return "미분류";
  if (!ontologyId) return canonicalClassName ?? "미분류";
  const parts = getOntologyBreadcrumb(ontologyId);
  return parts.slice(-2).join(" - ");
}
