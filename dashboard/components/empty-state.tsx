type EmptyStateProps = {
  title?: string;
  description?: string;
  action?: { label: string; onClick: () => void };
};

export function EmptyState({
  title = "데이터가 없습니다",
  description,
  action,
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 gap-3 text-center">
      <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center">
        <svg className="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>
      <p className="font-medium text-gray-700">{title}</p>
      {description && <p className="text-sm text-gray-400">{description}</p>}
      {action && (
        <button
          onClick={action.onClick}
          className="mt-2 px-4 py-2 text-sm bg-gray-800 text-white rounded-lg hover:bg-gray-700 transition-colors"
        >
          {action.label}
        </button>
      )}
    </div>
  );
}
