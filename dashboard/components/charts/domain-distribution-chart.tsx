"use client";

import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { DOMAIN_LABELS } from "@/lib/domain-labels";
import { EmptyState } from "../empty-state";

type Props = {
  data: { annotation_domain: string; count: number }[];
};

export function DomainDistributionChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <EmptyState title="도메인 분포 데이터 없음" />;
  }

  const chartData = data.map((d) => ({
    name: DOMAIN_LABELS[d.annotation_domain] ?? d.annotation_domain,
    count: d.count,
  }));

  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={chartData} margin={{ top: 4, right: 8, left: -16, bottom: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis dataKey="name" tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
        <Tooltip
          contentStyle={{ fontSize: 12 }}
          formatter={(v: number) => [`${v}건`, "검사 수"]}
        />
        <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
