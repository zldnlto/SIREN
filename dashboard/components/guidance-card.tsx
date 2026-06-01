import type { GuidanceDetail } from "@/types";

export function GuidanceCard({ guidance }: { guidance: GuidanceDetail | null }) {
  if (!guidance) {
    return (
      <div className="rounded-xl border border-gray-200 p-5">
        <p className="text-sm font-medium text-gray-500">조치 가이드</p>
        <p className="mt-2 text-sm text-gray-400">조치 가이드 없음</p>
      </div>
    );
  }

  const sections = [
    { label: "원인 추정", content: guidance.cause },
    {
      label: "권장 조치",
      content: Array.isArray(guidance.action)
        ? guidance.action.join(" / ")
        : guidance.action,
    },
    { label: "재검사 기준", content: guidance.reinspection },
    { label: "주의사항", content: guidance.caution },
  ];

  return (
    <div className="rounded-xl border border-gray-200 p-5 space-y-4">
      <p className="text-sm font-semibold text-gray-700">조치 가이드</p>
      {sections.map(({ label, content }) => (
        <div key={label}>
          <p className="text-xs font-medium text-gray-500 mb-1">{label}</p>
          <p className="text-sm text-gray-800">{content}</p>
        </div>
      ))}
    </div>
  );
}
