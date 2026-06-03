"use client";

import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { QUALITY_STATE_LABELS } from "@/lib/domain-labels";
import { EmptyState } from "../empty-state";

type Props = {
  data: { label: string; count: number }[];
};

const COLORS: Record<string, string> = {
  defect: "#ef4444",
  normal: "#22c55e",
  good: "#22c55e",
  unknown: "#9ca3af",
};

export function QualityStateChart({ data }: Props) {
  if (!data || data.length === 0 || data.every((d) => d.count === 0)) {
    return <EmptyState title="품질 상태 데이터 없음" />;
  }

  const chartData = data
    .filter((d) => d.count > 0)
    .map((d) => ({
      name: QUALITY_STATE_LABELS[d.label] ?? d.label,
      value: d.count,
      color: COLORS[d.label] ?? "#9ca3af",
    }));

  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie
          data={chartData}
          cx="50%"
          cy="50%"
          innerRadius={60}
          outerRadius={100}
          dataKey="value"
          label={({ name, value }) => `${name}: ${value}`}
          labelLine={false}
        >
          {chartData.map((entry, i) => (
            <Cell key={i} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{ fontSize: 12, background: "#141516", border: "1px solid #23252a", borderRadius: 6, color: "#f7f8f8" }}
          formatter={(v: number) => [`${v}건`]}
        />
      </PieChart>
    </ResponsiveContainer>
  );
}
