import { auth } from "@/lib/auth";
import { getAnalytics, getSummary, listInspections } from "@/lib/api";
import { MOCK_ANALYTICS, MOCK_LIST, MOCK_SUMMARY } from "@/mock/data";
import { presentKpis } from "@/lib/presenters/kpi";
import { KpiCard } from "@/components/kpi-card";
import { RecentInspectionsTable } from "@/components/recent-inspections-table";
import { DefectTypeChart } from "@/components/charts/defect-type-chart";
import { DomainDistributionChart } from "@/components/charts/domain-distribution-chart";

export default async function OverviewPage() {
  const session = await auth();
  const token = (session as { accessToken?: string })?.accessToken ?? "";

  const [summary, list, analytics] = await Promise.all([
    getSummary(token),
    listInspections(token, { limit: 10 }),
    getAnalytics(token),
  ]);

  const kpis = presentKpis(summary ?? MOCK_SUMMARY);
  const items = list?.items ?? MOCK_LIST.items;
  const a = analytics ?? MOCK_ANALYTICS;

  return (
    <div className="space-y-8 max-w-6xl">
      <div>
        <h1 className="text-2xl font-semibold text-ink tracking-tight">검사 현황 개요</h1>
        <p className="text-sm text-ink-subtle mt-1">LNG 탱크 부품 검사 결과 모니터링</p>
      </div>

      <div className="grid grid-cols-5 gap-4">
        {kpis.map((kpi) => (
          <KpiCard key={kpi.label} {...kpi} />
        ))}
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div className="bg-surface-1 rounded-lg border border-hairline p-5">
          <p className="text-xs font-medium text-ink-subtle uppercase tracking-wide mb-4">도메인별 검사 분포</p>
          <DomainDistributionChart data={a.domain_distribution} />
        </div>
        <div className="bg-surface-1 rounded-lg border border-hairline p-5">
          <p className="text-xs font-medium text-ink-subtle uppercase tracking-wide mb-4">결함 유형별 분포</p>
          <DefectTypeChart data={a.defect_type_distribution} />
        </div>
      </div>

      <div className="bg-surface-1 rounded-lg border border-hairline p-5">
        <p className="text-xs font-medium text-ink-subtle uppercase tracking-wide mb-4">최근 검사 목록</p>
        <RecentInspectionsTable items={items} />
      </div>
    </div>
  );
}
