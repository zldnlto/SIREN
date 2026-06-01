import type { InspectionFilters } from "@/types";

type ActiveFilters = Partial<Omit<InspectionFilters, "page" | "limit">>;

export function hasActiveFilter(filters: ActiveFilters): boolean {
  return Object.values(filters).some((v) => v !== undefined && v !== "");
}

export function parseInspectionFilters(
  searchParams: Record<string, string | undefined>
): ActiveFilters & { page: number; limit: number } {
  return {
    status: searchParams.status,
    quality_state: searchParams.quality_state,
    annotation_domain: searchParams.annotation_domain,
    from: searchParams.from,
    to: searchParams.to,
    page: Number(searchParams.page ?? 1),
    limit: 20,
  };
}
