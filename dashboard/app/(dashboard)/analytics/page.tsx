import { auth } from "@/lib/auth";
import { getAnalytics } from "@/lib/api";
import { MOCK_ANALYTICS } from "@/mock/data";
import { DefectTypeChart } from "@/components/charts/defect-type-chart";
import { DomainDistributionChart } from "@/components/charts/domain-distribution-chart";
import { QualityStateChart } from "@/components/charts/quality-state-chart";

export default async function AnalyticsPage() {
  const session = await auth();
  const token = (session as { accessToken?: string })?.accessToken ?? "";

  const analytics = (await getAnalytics(token)) ?? MOCK_ANALYTICS;

  return (
    <div className="space-y-8 max-w-6xl">
      <h1 className="text-2xl font-bold text-gray-900">분석</h1>

      <div className="grid grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-sm font-semibold text-gray-700 mb-4">결함 유형별 분포</p>
          <DefectTypeChart data={analytics.defect_type_distribution} />
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-sm font-semibold text-gray-700 mb-4">도메인별 검사 분포</p>
          <DomainDistributionChart data={analytics.domain_distribution} />
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-sm font-semibold text-gray-700 mb-4">품질 상태 분포</p>
          <QualityStateChart data={analytics.quality_state_distribution} />
        </div>
      </div>
    </div>
  );
}
