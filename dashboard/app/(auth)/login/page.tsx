"use client";

import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useState } from "react";

const DEMO_ID = "999999";
const DEMO_PW = "1234";

export default function LoginPage() {
  const router = useRouter();
  const [employeeId, setEmployeeId] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function login(id: string, pw: string) {
    setError("");
    setLoading(true);
    const result = await signIn("credentials", { employee_id: id, password: pw, redirect: false });
    setLoading(false);
    if (result?.error) {
      setError("사번 또는 비밀번호가 올바르지 않습니다.");
    } else {
      router.push("/");
      router.refresh();
    }
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    await login(employeeId, password);
  }

  function loginAsDemo() {
    login(DEMO_ID, DEMO_PW);
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-canvas">
      <div className="w-full max-w-sm bg-surface-1 rounded-lg border border-hairline p-8">
        <div className="mb-8 text-center">
          <p className="text-xs text-primary uppercase tracking-widest mb-2 font-medium">SIREN</p>
          <h1 className="text-xl font-semibold text-ink tracking-tight">관리자 로그인</h1>
        </div>
        <form onSubmit={handleSubmit} method="post" className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-ink-subtle mb-1.5 uppercase tracking-wide">
              사번
            </label>
            <input
              name="employee_id"
              type="text"
              required
              placeholder="EMP-001"
              value={employeeId}
              onChange={(e) => setEmployeeId(e.target.value)}
              className="w-full border border-hairline rounded-md px-3.5 py-2.5 text-sm bg-surface-2 text-ink placeholder:text-ink-tertiary focus:outline-none focus:ring-1 focus:ring-primary"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-ink-subtle mb-1.5 uppercase tracking-wide">
              비밀번호
            </label>
            <input
              name="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border border-hairline rounded-md px-3.5 py-2.5 text-sm bg-surface-2 text-ink focus:outline-none focus:ring-1 focus:ring-primary"
            />
          </div>
          {error && (
            <p className="text-sm text-red-400 bg-red-500/10 border border-red-500/20 rounded-md px-3 py-2">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary text-white rounded-md py-2.5 text-sm font-medium hover:bg-primary-hover transition-colors disabled:opacity-50"
          >
            {loading ? "로그인 중…" : "로그인"}
          </button>
        </form>

        <div className="mt-4 pt-4 border-t border-hairline">
          <button
            type="button"
            onClick={loginAsDemo}
            disabled={loading}
            className="w-full border border-hairline rounded-md py-2.5 text-sm text-ink-subtle hover:bg-surface-2 hover:text-ink transition-colors disabled:opacity-50"
          >
            데모 계정으로 로그인
            <span className="ml-2 text-ink-tertiary text-xs">아이디 {DEMO_ID} · 비밀번호 {DEMO_PW}</span>
          </button>
        </div>

        <p className="mt-5 text-xs text-center text-ink-tertiary">
          AI 분석 결과는 현장 품질 판단을 보조하기 위한 참고 정보입니다.
        </p>
      </div>
    </div>
  );
}
