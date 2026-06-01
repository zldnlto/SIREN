import Link from "next/link";
import { auth } from "@/lib/auth";
import { getInspectionDetail } from "@/lib/api";
import { MOCK_DETAIL } from "@/mock/data";
import { presentInspectionDetail } from "@/lib/presenters/inspection";
import { ImageViewer } from "@/components/image-viewer";
import { OntologyBreadcrumb } from "@/components/ontology-breadcrumb";
import { GuidanceCard } from "@/components/guidance-card";
import { StatusBadge } from "@/components/status-badge";
import { QualityBadge } from "@/components/quality-badge";

export default async function InspectionDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const session = await auth();
  const token = (session as { accessToken?: string })?.accessToken ?? "";

  const raw = (await getInspectionDetail(token, params.id)) ?? MOCK_DETAIL;
  const detail = presentInspectionDetail(raw);

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="flex items-center gap-3">
        <Link href="/inspections" className="text-sm text-gray-400 hover:text-gray-700">
          ← 목록으로
        </Link>
        <span className="text-gray-300">|</span>
        <h1 className="text-xl font-bold text-gray-900 font-mono">{detail.idShort}</h1>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <p className="text-xs font-medium text-gray-500 mb-3">원본 이미지</p>
            <ImageViewer src={raw.image_url} alt="검사 이미지" />
          </div>
          {raw.overlay_image_url && (
            <div className="bg-white rounded-xl border border-gray-200 p-4">
              <p className="text-xs font-medium text-gray-500 mb-3">AI 분석 결과</p>
              <ImageViewer src={raw.overlay_image_url} alt="AI 분석 오버레이" />
            </div>
          )}
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
            <p className="text-sm font-semibold text-gray-700">검사 정보</p>

            <div className="grid grid-cols-2 gap-x-4 gap-y-3 text-sm">
              <div>
                <p className="text-xs text-gray-500 mb-1">분석 상태</p>
                <StatusBadge {...detail.status} />
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">품질 상태</p>
                <QualityBadge {...detail.quality} />
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">도메인</p>
                <p className="text-gray-800">{detail.domain}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Confidence</p>
                <p className="text-gray-800">{detail.confidence}</p>
              </div>
              <div className="col-span-2">
                <p className="text-xs text-gray-500 mb-1">결함명 (내부)</p>
                <p className="text-gray-800 font-mono text-xs">{detail.canonicalName}</p>
              </div>
              <div className="col-span-2">
                <p className="text-xs text-gray-500 mb-1">Ontology ID</p>
                <p className="text-gray-800 font-mono text-xs">{detail.ontologyId}</p>
              </div>
              <div className="col-span-2">
                <p className="text-xs text-gray-500 mb-1">결함 분류 경로</p>
                <OntologyBreadcrumb ontologyId={raw.ontology_id} />
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">생성 시간</p>
                <p className="text-xs text-gray-600">{detail.createdAt}</p>
              </div>
              {detail.completedAt && (
                <div>
                  <p className="text-xs text-gray-500 mb-1">완료 시간</p>
                  <p className="text-xs text-gray-600">{detail.completedAt}</p>
                </div>
              )}
            </div>

            {detail.errorMessage && (
              <div className="bg-orange-50 rounded-lg p-3">
                <p className="text-xs font-medium text-orange-700 mb-1">오류 메시지</p>
                <p className="text-xs text-orange-600">{detail.errorMessage}</p>
              </div>
            )}
          </div>

          <GuidanceCard guidance={raw.guidance} />

          <div className="bg-blue-50 rounded-xl p-4">
            <p className="text-xs text-blue-700">
              AI 분석 결과는 현장 품질 판단을 보조하기 위한 참고 정보입니다.
              최종 판정은 검사원 또는 품질 관리자의 확인이 필요합니다.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
