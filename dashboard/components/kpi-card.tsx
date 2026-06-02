import type { KpiViewModel } from "@/lib/presenters/kpi";

// 디자인 변경은 여기만. 어떤 KPI가 어떤 variant인지는 lib/presenters/kpi.ts에 있다.
const VARIANT_VALUE_CLASSES: Record<string, string> = {
  default: "text-ink",
  success: "text-[#27a644]",
  error:   "text-red-400",
  warning: "text-orange-400",
  info:    "text-primary",
  neutral: "text-ink-subtle",
};

export function KpiCard({ label, value, sub, variant }: KpiViewModel) {
  return (
    <div className="bg-surface-1 rounded-lg border border-hairline p-5 flex flex-col gap-1">
      <p className="text-xs text-ink-subtle uppercase tracking-wide">{label}</p>
      <p className={`text-3xl font-bold ${VARIANT_VALUE_CLASSES[variant] ?? VARIANT_VALUE_CLASSES.default}`}>
        {value}
      </p>
      {sub && <p className="text-xs text-ink-tertiary">{sub}</p>}
    </div>
  );
}
