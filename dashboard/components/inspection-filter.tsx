"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useCallback } from "react";

const DOMAINS = [
  { value: "", label: "전체 도메인" },
  { value: "surface_treatment", label: "표면처리" },
  { value: "welding", label: "용접" },
  { value: "cutting", label: "절단" },
];

const STATUSES = [
  { value: "", label: "전체 상태" },
  { value: "pending", label: "대기" },
  { value: "processing", label: "분석중" },
  { value: "completed", label: "완료" },
  { value: "failed", label: "실패" },
];

const QUALITY_STATES = [
  { value: "", label: "전체 품질" },
  { value: "defect", label: "결함" },
  { value: "good", label: "정상" },
];

export function InspectionFilter() {
  const router = useRouter();
  const params = useSearchParams();

  const update = useCallback(
    (key: string, value: string) => {
      const next = new URLSearchParams(params.toString());
      if (value) next.set(key, value);
      else next.delete(key);
      next.set("page", "1");
      router.push(`/inspections?${next.toString()}`);
    },
    [params, router]
  );

  const reset = () => router.push("/inspections");

  const hasFilter =
    params.has("status") ||
    params.has("quality_state") ||
    params.has("annotation_domain") ||
    params.has("from") ||
    params.has("to");

  return (
    <div className="flex flex-wrap gap-3 items-center">
      <select
        value={params.get("annotation_domain") ?? ""}
        onChange={(e) => update("annotation_domain", e.target.value)}
        className="text-sm border border-hairline rounded-md px-3 py-2 bg-surface-2 text-ink-muted focus:outline-none focus:ring-1 focus:ring-primary"
      >
        {DOMAINS.map((d) => (
          <option key={d.value} value={d.value}>{d.label}</option>
        ))}
      </select>

      <select
        value={params.get("status") ?? ""}
        onChange={(e) => update("status", e.target.value)}
        className="text-sm border border-hairline rounded-md px-3 py-2 bg-surface-2 text-ink-muted focus:outline-none focus:ring-1 focus:ring-primary"
      >
        {STATUSES.map((s) => (
          <option key={s.value} value={s.value}>{s.label}</option>
        ))}
      </select>

      <select
        value={params.get("quality_state") ?? ""}
        onChange={(e) => update("quality_state", e.target.value)}
        className="text-sm border border-hairline rounded-md px-3 py-2 bg-surface-2 text-ink-muted focus:outline-none focus:ring-1 focus:ring-primary"
      >
        {QUALITY_STATES.map((q) => (
          <option key={q.value} value={q.value}>{q.label}</option>
        ))}
      </select>

      <input
        type="date"
        value={params.get("from") ?? ""}
        onChange={(e) => update("from", e.target.value)}
        className="text-sm border border-hairline rounded-md px-3 py-2 bg-surface-2 text-ink-muted focus:outline-none focus:ring-1 focus:ring-primary"
      />
      <span className="text-ink-tertiary text-sm">~</span>
      <input
        type="date"
        value={params.get("to") ?? ""}
        onChange={(e) => update("to", e.target.value)}
        className="text-sm border border-hairline rounded-md px-3 py-2 bg-surface-2 text-ink-muted focus:outline-none focus:ring-1 focus:ring-primary"
      />

      {hasFilter && (
        <button
          onClick={reset}
          className="text-sm text-ink-subtle hover:text-ink underline"
        >
          필터 초기화
        </button>
      )}
    </div>
  );
}
