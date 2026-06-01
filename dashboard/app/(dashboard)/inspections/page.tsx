import { Suspense } from "react";
import { auth } from "@/lib/auth";
import { listInspections } from "@/lib/api";
import { MOCK_LIST } from "@/mock/data";
import { parseInspectionFilters, hasActiveFilter } from "@/lib/presenters/filter";
import { InspectionFilter } from "@/components/inspection-filter";
import { RecentInspectionsTable } from "@/components/recent-inspections-table";
import { EmptyState } from "@/components/empty-state";

type PageProps = {
  searchParams: Record<string, string | undefined>;
};

async function InspectionList({ searchParams }: PageProps) {
  const session = await auth();
  const token = (session as { accessToken?: string })?.accessToken ?? "";

  const filters = parseInspectionFilters(searchParams);
  const result = await listInspections(token, filters);
  const data = result ?? MOCK_LIST;

  if (data.items.length === 0) {
    return (
      <EmptyState
        title="검사 결과 없음"
        description={
          hasActiveFilter(filters)
            ? "필터 조건에 맞는 검사가 없습니다."
            : "아직 검사 데이터가 없습니다."
        }
      />
    );
  }

  const page = filters.page;

  return (
    <div className="space-y-4">
      <RecentInspectionsTable items={data.items} />
      <div className="flex items-center justify-between pt-2 text-sm text-gray-500">
        <p>전체 {data.total.toLocaleString()}건</p>
        <div className="flex gap-2">
          {page > 1 && (
            <a
              href={`/inspections?${new URLSearchParams({ ...searchParams, page: String(page - 1) })}`}
              className="px-3 py-1.5 border border-gray-200 rounded-lg hover:bg-gray-50"
            >
              이전
            </a>
          )}
          {data.total > page * 20 && (
            <a
              href={`/inspections?${new URLSearchParams({ ...searchParams, page: String(page + 1) })}`}
              className="px-3 py-1.5 border border-gray-200 rounded-lg hover:bg-gray-50"
            >
              다음
            </a>
          )}
        </div>
      </div>
    </div>
  );
}

export default function InspectionsPage({ searchParams }: PageProps) {
  return (
    <div className="space-y-6 max-w-6xl">
      <h1 className="text-2xl font-bold text-gray-900">검사 목록</h1>
      <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-5">
        <Suspense fallback={null}>
          <InspectionFilter />
        </Suspense>
        <Suspense
          fallback={
            <div className="py-12 text-center text-sm text-gray-400">
              불러오는 중…
            </div>
          }
        >
          <InspectionList searchParams={searchParams} />
        </Suspense>
      </div>
    </div>
  );
}
