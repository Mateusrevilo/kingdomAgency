import { logout } from "../actions";

export default function DashboardPage() {
  return (
    <main className="min-h-screen bg-background px-6 py-10 text-foreground sm:px-10">
      <div className="mx-auto max-w-4xl">
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-800">
              Gestão da Igreja
            </p>
            <h1 className="mt-3 text-3xl font-semibold tracking-tight">
              Painel inicial
            </h1>
          </div>
          <form action={logout}>
            <button
              className="rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
              type="submit"
            >
              Sair
            </button>
          </form>
        </header>

        <section className="mt-10 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold">Sessão autenticada</h2>
          <p className="mt-2 leading-7 text-slate-600">
            Sua sessão foi verificada no servidor. Os módulos e as permissões
            serão adicionados em etapas posteriores.
          </p>
        </section>
      </div>
    </main>
  );
}
