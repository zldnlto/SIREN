import { getOntologyBreadcrumb } from "@/lib/domain-labels";

export function OntologyBreadcrumb({ ontologyId }: { ontologyId: string | null }) {
  if (!ontologyId) return <span className="text-gray-400 text-sm">미분류</span>;
  const parts = getOntologyBreadcrumb(ontologyId);
  return (
    <nav className="flex items-center gap-1 text-sm text-gray-600">
      {parts.map((part, i) => (
        <span key={i} className="flex items-center gap-1">
          {i > 0 && <span className="text-gray-300">/</span>}
          <span className={i === parts.length - 1 ? "font-medium text-gray-900" : ""}>
            {part}
          </span>
        </span>
      ))}
    </nav>
  );
}
