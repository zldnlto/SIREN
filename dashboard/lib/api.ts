import type {
  AnalyticsResponse,
  DashboardSummary,
  InspectionDetail,
  InspectionFilters,
  InspectionListResponse,
} from "@/types";

const BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

async function apiFetch<T>(
  path: string,
  token: string,
  params?: Record<string, string | number | undefined>
): Promise<T | null> {
  try {
    const url = new URL(`${BASE_URL}${path}`);
    if (params) {
      Object.entries(params).forEach(([k, v]) => {
        if (v !== undefined && v !== "") url.searchParams.set(k, String(v));
      });
    }
    const res = await fetch(url.toString(), {
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
    });
    if (!res.ok) return null;
    return res.json() as Promise<T>;
  } catch {
    return null;
  }
}

export async function getSummary(token: string): Promise<DashboardSummary | null> {
  return apiFetch<DashboardSummary>("/api/v1/dashboard/summary", token);
}

export async function listInspections(
  token: string,
  filters: Partial<InspectionFilters> = {}
): Promise<InspectionListResponse | null> {
  return apiFetch<InspectionListResponse>(
    "/api/v1/dashboard/inspections",
    token,
    {
      status: filters.status,
      quality_state: filters.quality_state,
      annotation_domain: filters.annotation_domain,
      from: filters.from,
      to: filters.to,
      page: filters.page ?? 1,
      limit: filters.limit ?? 20,
    }
  );
}

export async function getInspectionDetail(
  token: string,
  id: string
): Promise<InspectionDetail | null> {
  return apiFetch<InspectionDetail>(
    `/api/v1/dashboard/inspections/${id}`,
    token
  );
}

export async function getAnalytics(
  token: string
): Promise<AnalyticsResponse | null> {
  return apiFetch<AnalyticsResponse>("/api/v1/dashboard/analytics", token);
}
