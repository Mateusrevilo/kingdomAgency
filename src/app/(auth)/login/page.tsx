import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { LoginForm } from "./login-form";

export const instant = false;

export default async function LoginPage() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getClaims();

  if (error) {
    throw error;
  }

  if (data?.claims) {
    redirect("/dashboard");
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-6 py-16">
      <section className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-sm sm:p-10">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-800">
          Gestão da Igreja
        </p>
        <h1 className="mt-5 text-3xl font-semibold tracking-tight text-slate-950">
          Acesse sua conta
        </h1>
        <p className="mt-3 text-slate-600">
          Entre com o e-mail e a senha fornecidos pela administração.
        </p>
        <LoginForm />
      </section>
    </main>
  );
}
