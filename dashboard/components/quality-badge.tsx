import type { BadgeViewModel } from "@/lib/presenters/badges";

// 디자인 변경은 여기만. 로직(어떤 상태 → 어떤 variant)은 lib/presenters/badges.ts에 있다.
const VARIANT_CLASSES: Record<string, string> = {
  success: "bg-green-100 text-green-700",
  error:   "bg-red-100 text-red-700",
  warning: "bg-orange-100 text-orange-700",
  info:    "bg-blue-100 text-blue-700",
  neutral: "bg-gray-100 text-gray-500",
};

export function QualityBadge({ label, variant }: BadgeViewModel) {
  if (label === "-") return <span className="text-gray-400 text-sm">-</span>;
  return (
    <span
      className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${VARIANT_CLASSES[variant] ?? VARIANT_CLASSES.neutral}`}
    >
      {label}
    </span>
  );
}
