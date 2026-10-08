# Gestão da Igreja

Aplicação web em desenvolvimento incremental para gerenciamento de igrejas.
O projeto começa como um monólito modular em Next.js; autenticação, banco de
dados e módulos de negócio serão adicionados em etapas.

## Requisitos

- Node.js 20.9 ou superior
- npm

## Desenvolvimento

```bash
npm install
npm run dev
```

Acesse [http://localhost:3000](http://localhost:3000).

## Verificações

```bash
npm run lint
npm run build
```

## Estado atual

A fundação usa Next.js App Router, TypeScript e Tailwind CSS. Supabase e
autenticação ainda não estão configurados. A próxima etapa é definir a
integração server-side com Supabase e o fluxo de sessão antes de criar
funcionalidades protegidas.
