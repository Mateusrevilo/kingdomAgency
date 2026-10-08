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
          Este sistema será construído em etapas. A fundação da aplicação está
          pronta; autenticação e funcionalidades serão adicionadas depois de
          configuradas e validadas com segurança.
        </p>

        <section
          aria-labelledby="current-stage"
          className="mt-12 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8"
        >
          <p className="text-sm font-medium text-slate-500">Etapa atual</p>
          <h2 id="current-stage" className="mt-2 text-xl font-semibold">
            Fundação da aplicação
          </h2>
          <p className="mt-2 text-slate-600">
            Next.js, TypeScript e Tailwind CSS configurados.
          </p>
          <p className="mt-6 border-t border-slate-200 pt-5 text-sm leading-6 text-slate-500">
            Próxima etapa: configurar o Supabase e estabelecer autenticação e
            sessão segura.
          </p>
        </section>
      </div>
    </main>
  );
}
