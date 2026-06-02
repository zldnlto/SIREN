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
        <CartesianGrid strokeDasharray="3 3" stroke="#23252a" vertical={false} />
        <XAxis dataKey="name" tick={{ fontSize: 12, fill: "#8a8f98" }} axisLine={{ stroke: "#23252a" }} tickLine={false} />
        <YAxis tick={{ fontSize: 11, fill: "#8a8f98" }} allowDecimals={false} axisLine={false} tickLine={false} />
        <Tooltip
          contentStyle={{ fontSize: 12, background: "#141516", border: "1px solid #23252a", borderRadius: 6, color: "#f7f8f8" }}
          formatter={(v: number) => [`${v}건`, "검사 수"]}
        />
        <Bar dataKey="count" fill="#5e6ad2" radius={[3, 3, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
