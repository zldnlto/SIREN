import Link from "next/link";
import { StatusBadge } from "./status-badge";
import { QualityBadge } from "./quality-badge";
import { presentInspectionRow } from "@/lib/presenters/inspection";
import type { InspectionListItem } from "@/types";

// Humble Object: 표시할 데이터를 받아서 렌더링만 한다.
// 날짜 포맷, 배지 결정, 결함명 변환은 presenter에서 이미 완료된 상태로 들어온다.

export function RecentInspectionsTable({ items }: { items: InspectionListItem[] }) {
  if (items.length === 0) {
    return (
      <p className="text-sm text-ink-subtle py-6 text-center">
        최근 검사 결과가 없습니다.
      </p>
    );
  }

  const rows = items.map(presentInspectionRow);

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-hairline text-ink-subtle text-left">
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">검사 ID</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">일시</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">도메인</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">결함명</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">분석 상태</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">품질</th>
            <th className="pb-3 font-medium pr-4 text-xs uppercase tracking-wide">Confidence</th>
            <th className="pb-3 font-medium"></th>
          </tr>
        </thead>
        <tbody className="divide-y divide-hairline">
          {rows.map((row) => (
            <tr key={row.idFull} className="hover:bg-surface-2 transition-colors">
              <td className="py-3 pr-4 font-mono text-xs text-ink-tertiary">{row.id}</td>
              <td className="py-3 pr-4 text-ink-subtle">{row.date}</td>
              <td className="py-3 pr-4 text-ink-muted">{row.domain}</td>
              <td className="py-3 pr-4 text-ink-muted">{row.defectName}</td>
              <td className="py-3 pr-4"><StatusBadge {...row.status} /></td>
              <td className="py-3 pr-4"><QualityBadge {...row.quality} /></td>
              <td className="py-3 pr-4 text-ink-subtle">{row.confidence}</td>
              <td className="py-3">
                <Link
                  href={`/inspections/${row.idFull}`}
                  className="text-xs text-primary hover:text-primary-hover transition-colors"
                >
                  상세
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
