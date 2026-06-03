import type { BadgeViewModel } from "@/lib/presenters/badges";

// 디자인 변경은 여기만. 로직(어떤 상태 → 어떤 variant)은 lib/presenters/badges.ts에 있다.
const VARIANT_CLASSES: Record<string, string> = {
  success: "bg-[#27a644]/15 text-[#27a644]",
  error:   "bg-red-500/15 text-red-400",
  warning: "bg-orange-500/15 text-orange-400",
  info:    "bg-primary/15 text-primary",
  neutral: "bg-surface-2 text-ink-subtle",
};

export function QualityBadge({ label, variant }: BadgeViewModel) {
  if (label === "-") return <span className="text-ink-tertiary text-sm">-</span>;
  return (
    <span
      className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${VARIANT_CLASSES[variant] ?? VARIANT_CLASSES.neutral}`}
    >
      {label}
    </span>
  );
}
