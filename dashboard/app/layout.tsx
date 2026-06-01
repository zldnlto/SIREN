import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SIREN 관리자 대시보드",
  description: "LNG 탱크 부품 검사 결과 관리자 모니터링",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
