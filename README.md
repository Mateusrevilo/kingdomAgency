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

## Supabase

Crie um arquivo `.env.local` na raiz com base em `.env.example` e preencha a URL
do projeto e a chave pública publishable. Se o painel do Supabase ainda mostrar
a chave legada `anon`, ela pode ser usada como valor da variável publishable.

Essas variáveis `NEXT_PUBLIC_` são destinadas ao cliente. Nunca coloque uma
chave `service_role` nelas nem em arquivos versionados. Os clientes de servidor
e navegador ficam em `src/lib/supabase`; eles informam explicitamente se a
configuração estiver ausente ou inválida.

O projeto também possui configuração local da Supabase CLI em `supabase/`. Para
vincular uma nova cópia ao projeto remoto, autentique a CLI e execute:

```bash
npx supabase login
npx supabase link --project-ref ckavpykcnubfznerxqgl
```

O vínculo local atual já foi concluído. Ele não inicia containers, executa
migrações ou altera o banco remoto.

## Autenticação

O acesso inicial usa e-mail e senha por Supabase Auth. As contas devem ser
criadas e gerenciadas pela administração do projeto; o cadastro público está
desativado na aplicação. Sessões usam cookies SSR, renovados pelo `proxy.ts`,
e o grupo de rotas do dashboard verifica os claims no servidor.

Papéis, permissões e autorização por módulo serão implementados em uma etapa
posterior. A autenticação sozinha não concede acesso a operações
administrativas.

## Estado atual

A fundação usa Next.js App Router, TypeScript e Tailwind CSS, com login,
logout e uma rota inicial protegida. Os módulos de negócio e as permissões
ainda não foram implementados.
