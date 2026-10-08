"use server";

import { redirect } from "next/navigation";
import { loginSchema } from "@/modules/auth/schemas";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type LoginState = {
  error?: string;
};

export async function login(
  _previousState: LoginState,
  formData: FormData,
): Promise<LoginState> {
  const parsed = loginSchema.safeParse({
    email: formData.get("email"),
    password: formData.get("password"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? "Confira seus dados." };
  }

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);

  if (error) {
    if (error.status === 400) {
      return { error: "E-mail ou senha inválidos." };
    }

    if (error.status === 429) {
      return {
        error: "Muitas tentativas. Aguarde um pouco antes de tentar novamente.",
      };
    }

    console.error("Supabase password sign-in failed.", {
      code: error.code,
      status: error.status,
    });
    return { error: "Não foi possível iniciar a sessão. Tente novamente." };
  }

  redirect("/dashboard");
}
