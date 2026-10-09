"use client";

import { useActionState, type FormEvent } from "react";
import {
  removeMemberAssignment,
  transferMemberAssignment,
  type MemberAssignmentActionState,
} from "./actions";

type AdminOption = {
  id: string;
  label: string;
};

type AssignmentControlsProps = {
  churchId: string;
  membershipId: string;
  adminOptions: AdminOption[];
};

const initialState: MemberAssignmentActionState = {};

function ActionFeedback({ state }: { state: MemberAssignmentActionState }) {
  if (state.error) {
    return (
      <p aria-live="polite" className="text-sm text-red-700" role="alert">
        {state.error}
      </p>
    );
  }

  if (state.success) {
    return (
      <p aria-live="polite" className="text-sm text-emerald-800" role="status">
        {state.success}
      </p>
    );
  }

  return null;
}

export function AssignmentControls({
  churchId,
  membershipId,
  adminOptions,
}: AssignmentControlsProps) {
  const [transferState, transferAction, transferPending] = useActionState(
    transferMemberAssignment,
    initialState,
  );
  const [removeState, removeAction, removePending] = useActionState(
    removeMemberAssignment,
    initialState,
  );

  function confirmRemoval(event: FormEvent<HTMLFormElement>) {
    if (!window.confirm("Remover o responsável atual e liberar esta vaga?")) {
      event.preventDefault();
    }
  }

  return (
    <div className="space-y-3">
      <form action={transferAction} className="flex flex-wrap items-end gap-2">
        <input name="churchId" type="hidden" value={churchId} />
        <input name="membershipId" type="hidden" value={membershipId} />
        <div className="min-w-48 flex-1">
          <label
            className="block text-xs font-medium text-slate-600"
            htmlFor={`admin-${membershipId}`}
          >
            Novo responsável
          </label>
          <select
            className="mt-1 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-700/20"
            defaultValue=""
            disabled={adminOptions.length === 0 || transferPending}
            id={`admin-${membershipId}`}
            name="newAdminUserId"
            required
          >
            <option disabled value="">
              {adminOptions.length === 0
                ? "Nenhum outro Secundário ativo"
                : "Selecione"}
            </option>
            {adminOptions.map((admin) => (
              <option key={admin.id} value={admin.id}>
                {admin.label}
              </option>
            ))}
          </select>
        </div>
        <button
          className="rounded-lg bg-emerald-800 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800 disabled:cursor-wait disabled:opacity-60"
          disabled={adminOptions.length === 0 || transferPending}
          type="submit"
        >
          {transferPending ? "Transferindo..." : "Transferir"}
        </button>
      </form>
      <ActionFeedback state={transferState} />

      <form action={removeAction} onSubmit={confirmRemoval}>
        <input name="churchId" type="hidden" value={churchId} />
        <input name="membershipId" type="hidden" value={membershipId} />
        <button
          className="rounded-lg border border-red-300 px-3 py-2 text-sm font-medium text-red-800 hover:bg-red-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-700 disabled:cursor-wait disabled:opacity-60"
          disabled={removePending}
          type="submit"
        >
          {removePending ? "Removendo..." : "Remover atribuição"}
        </button>
      </form>
      <ActionFeedback state={removeState} />
    </div>
  );
}
