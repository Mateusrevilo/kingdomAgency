import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen items-center bg-background px-6 py-16 text-foreground sm:px-10">
      <div className="mx-auto w-full max-w-3xl">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
          Gestão da Igreja
        </p>

        <h1 className="mt-6 max-w-2xl text-4xl font-semibold tracking-tight sm:text-5xl">
          Uma base sólida para cuidar da comunidade.
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-600">
          O sistema está sendo construído em etapas. O acesso seguro já está
          preparado e os módulos da igreja serão adicionados gradualmente.
        </p>

        <section
          aria-labelledby="current-stage"
          className="mt-12 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8"
        >
          <p className="text-sm font-medium text-slate-500">Etapa concluída</p>
          <h2 id="current-stage" className="mt-2 text-xl font-semibold">
            Autenticação inicial
          </h2>
          <p className="mt-2 text-slate-600">
            Login, sessão segura e proteção server-side do dashboard.
          </p>
          <p className="mt-6 border-t border-slate-200 pt-5 text-sm leading-6 text-slate-500">
            Acesse sua área com as credenciais fornecidas pela administração.
          </p>
        </section>

        <Link
          className="mt-6 inline-flex rounded-lg bg-emerald-800 px-5 py-3 font-medium text-white transition-colors hover:bg-emerald-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
          href="/login"
        >
          Acessar minha conta
        </Link>

        <Link
          className="mt-6 ml-4 inline-flex rounded-lg border border-slate-300 px-5 py-3 font-medium text-slate-700 transition-colors hover:border-emerald-800 hover:text-emerald-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
          href="/planos"
        >
          Conheça os planos
        </Link>
      </div>
    </main>
  );
}
