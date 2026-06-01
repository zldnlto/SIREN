"use client";

import { useState } from "react";

export function ImageViewer({
  src,
  alt = "검사 이미지",
}: {
  src: string | null;
  alt?: string;
}) {
  const [error, setError] = useState(false);

  if (!src || error) {
    return (
      <div className="w-full aspect-video bg-gray-100 rounded-xl flex items-center justify-center">
        <div className="text-center text-gray-400">
          <svg className="w-12 h-12 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <p className="text-sm">이미지 없음</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full aspect-video bg-gray-100 rounded-xl overflow-hidden">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt={alt}
        className="w-full h-full object-contain"
        onError={() => setError(true)}
      />
    </div>
  );
}
