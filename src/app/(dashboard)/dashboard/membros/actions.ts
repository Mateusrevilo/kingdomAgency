"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import {
  removeMemberAssignmentSchema,
  transferMemberAssignmentSchema,
} from "@/modules/members/schemas";

export type MemberAssignmentActionState = {
  error?: string;
  success?: string;
};

async function getAuthenticatedSupabase() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.getClaims();

  if (error) {
    throw error;
  }

  if (typeof data?.claims?.sub !== "string") {
    redirect("/login");
  }

  return supabase;
}

function getRpcErrorMessage(
  code: string | undefined,
  operation: "transferir" | "remover",
) {
  if (code === "42501") {
    return "Somente o Administrador Sênior pode alterar atribuições.";
  }

  if (code === "23514") {
    return "O limite do Administrador Secundário de destino foi atingido.";
  }

  if (code === "55000") {
    return "O Administrador Secundário ainda não possui limite configurado.";
  }

  if (code === "22023") {
    return "A atribuição não está mais disponível ou os dados selecionados são inválidos.";
  }

  if (code === "28000") {
    return "Sua sessão expirou. Entre novamente para continuar.";
  }

  console.error(`Falha ao ${operation} atribuição de membro.`, { code });
  return `Não foi possível ${operation} a atribuição. Tente novamente.`;
}

export async function transferMemberAssignment(
  _previousState: MemberAssignmentActionState,
  formData: FormData,
): Promise<MemberAssignmentActionState> {
  const parsed = transferMemberAssignmentSchema.safeParse({
    churchId: formData.get("churchId"),
    membershipId: formData.get("membershipId"),
    newAdminUserId: formData.get("newAdminUserId"),
  });

  if (!parsed.success) {
    return {
      error: parsed.error.issues[0]?.message ?? "Confira os dados da transferência.",
    };
  }

  const supabase = await getAuthenticatedSupabase();
  const { error } = await supabase.rpc("transfer_member_assignment", {
    p_church_id: parsed.data.churchId,
    p_membership_id: parsed.data.membershipId,
    p_new_admin_user_id: parsed.data.newAdminUserId,
  });

  if (error) {
    return { error: getRpcErrorMessage(error.code, "transferir") };
  }

  revalidatePath("/dashboard/membros");
  return { success: "Responsável atualizado." };
}

export async function removeMemberAssignment(
  _previousState: MemberAssignmentActionState,
  formData: FormData,
): Promise<MemberAssignmentActionState> {
  const parsed = removeMemberAssignmentSchema.safeParse({
    churchId: formData.get("churchId"),
    membershipId: formData.get("membershipId"),
  });

  if (!parsed.success) {
    return {
      error: parsed.error.issues[0]?.message ?? "Confira os dados da remoção.",
    };
  }

  const supabase = await getAuthenticatedSupabase();
  const { error } = await supabase.rpc("remove_member_assignment", {
    p_church_id: parsed.data.churchId,
    p_membership_id: parsed.data.membershipId,
  });

  if (error) {
    return { error: getRpcErrorMessage(error.code, "remover") };
  }

  revalidatePath("/dashboard/membros");
  return { success: "A atribuição foi removida e a vaga liberada." };
}
