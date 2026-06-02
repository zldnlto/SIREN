import { getOntologyBreadcrumb } from "@/lib/domain-labels";

export function OntologyBreadcrumb({ ontologyId }: { ontologyId: string | null }) {
  if (!ontologyId) return <span className="text-ink-tertiary text-sm">미분류</span>;
  const parts = getOntologyBreadcrumb(ontologyId);
  return (
    <nav className="flex items-center gap-1 text-sm text-ink-subtle">
      {parts.map((part, i) => (
        <span key={i} className="flex items-center gap-1">
          {i > 0 && <span className="text-ink-tertiary">/</span>}
          <span className={i === parts.length - 1 ? "font-medium text-ink" : ""}>
            {part}
          </span>
        </span>
      ))}
    </nav>
  );
}
