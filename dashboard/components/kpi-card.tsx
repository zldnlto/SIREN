import type { KpiViewModel } from "@/lib/presenters/kpi";

// 디자인 변경은 여기만. 어떤 KPI가 어떤 variant인지는 lib/presenters/kpi.ts에 있다.
const VARIANT_VALUE_CLASSES: Record<string, string> = {
  default: "text-gray-900",
  success: "text-green-600",
  error:   "text-red-600",
  warning: "text-orange-500",
  info:    "text-blue-600",
  neutral: "text-gray-500",
};

export function KpiCard({ label, value, sub, variant }: KpiViewModel) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 flex flex-col gap-1">
      <p className="text-sm text-gray-500">{label}</p>
      <p className={`text-3xl font-bold ${VARIANT_VALUE_CLASSES[variant] ?? VARIANT_VALUE_CLASSES.default}`}>
        {value}
      </p>
      {sub && <p className="text-xs text-gray-400">{sub}</p>}
    </div>
  );
}
