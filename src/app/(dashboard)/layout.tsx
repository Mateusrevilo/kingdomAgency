import type { ReactNode } from "react";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const instant = false;

export default async function DashboardLayout({
  children,
}: {
  children: ReactNode;
}) {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getClaims();

  if (error) {
    throw error;
  }

  if (!data?.claims) {
    redirect("/login");
  }

  return children;
}
