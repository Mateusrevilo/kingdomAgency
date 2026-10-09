import { z } from "zod";

const assignmentFields = {
  churchId: z.string().uuid("Igreja inválida."),
  membershipId: z.string().uuid("Membro inválido."),
};

export const transferMemberAssignmentSchema = z.object({
  ...assignmentFields,
  newAdminUserId: z.string().uuid("Selecione um Administrador Secundário."),
});

export const removeMemberAssignmentSchema = z.object(assignmentFields);
