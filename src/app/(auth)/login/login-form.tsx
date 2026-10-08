"use client";

import { useActionState } from "react";
import { login, type LoginState } from "./actions";

const initialState: LoginState = {};

export function LoginForm() {
  const [state, formAction, pending] = useActionState(login, initialState);

  return (
    <form action={formAction} className="mt-8 space-y-5">
      <div>
        <label
          htmlFor="email"
          className="block text-sm font-medium text-slate-700"
        >
          E-mail
        </label>
        <input
          autoComplete="email"
          className="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-slate-900 shadow-sm outline-none focus:border-emerald-700 focus:ring-2 focus:ring-emerald-700/20"
          id="email"
          name="email"
          required
          type="email"
        />
      </div>

      <div>
        <label
          htmlFor="password"
          className="block text-sm font-medium text-slate-700"
        >
          Senha
        </label>
        <input
          autoComplete="current-password"
          className="mt-2 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-slate-900 shadow-sm outline-none focus:border-emerald-700 focus:ring-2 focus:ring-emerald-700/20"
          id="password"
          name="password"
          required
          type="password"
        />
      </div>

      {state.error ? (
        <p aria-live="polite" className="text-sm text-red-700" role="alert">
          {state.error}
        </p>
      ) : null}

      <button
        className="flex w-full items-center justify-center rounded-lg bg-emerald-800 px-4 py-3 font-medium text-white transition-colors hover:bg-emerald-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800 disabled:cursor-wait disabled:opacity-70"
        disabled={pending}
        type="submit"
      >
        {pending ? "Entrando..." : "Entrar"}
      </button>
    </form>
  );
}
