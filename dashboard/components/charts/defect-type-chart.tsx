"use client";

import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { getDisplayLabel } from "@/lib/domain-labels";
import { EmptyState } from "../empty-state";

type Props = {
  data: { ontology_id: string; canonical_class_name: string; count: number }[];
};

export function DefectTypeChart({ data }: Props) {
  if (!data || data.length === 0) {
    return <EmptyState title="결함 유형 데이터 없음" />;
  }

  const chartData = data.map((d) => ({
    name: getDisplayLabel(d.ontology_id, d.canonical_class_name),
    count: d.count,
  }));

  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={chartData} margin={{ top: 4, right: 8, left: -16, bottom: 40 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis
          dataKey="name"
          tick={{ fontSize: 11 }}
          angle={-30}
          textAnchor="end"
          interval={0}
        />
        <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
        <Tooltip
          contentStyle={{ fontSize: 12 }}
          formatter={(v: number) => [`${v}건`, "발생 수"]}
        />
        <Bar dataKey="count" fill="#ef4444" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
