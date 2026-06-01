import { auth } from "@/lib/auth";
import { NavSidebar } from "@/components/nav-sidebar";
import { redirect } from "next/navigation";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();
  if (!session) redirect("/login");

  return (
    <div className="flex min-h-screen">
      <NavSidebar />
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}
