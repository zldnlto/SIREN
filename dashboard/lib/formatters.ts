export function formatDate(iso: string): string {
  return new Date(iso).toLocaleString("ko-KR", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDateFull(iso: string): string {
  return new Date(iso).toLocaleString("ko-KR");
}

export function formatConfidence(score: number | null | undefined): string {
  if (score == null) return "-";
  return `${(score * 100).toFixed(1)}%`;
}

export function formatConfidenceShort(score: number | null | undefined): string {
  if (score == null) return "-";
  return `${(score * 100).toFixed(0)}%`;
}

export function formatInspectionId(uuid: string): string {
  return `${uuid.slice(0, 8)}…`;
}

export function formatCount(n: number): string {
  return n.toLocaleString();
}
