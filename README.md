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

## Requisitos e arquitetura

Os perfis de acesso, as decisões de negócio, a proposta multi-igreja, o escopo
e os limites de membros e as regras de segurança estão descritos em
[doc/README.md](./doc/README.md) e [doc/arquitetura.md](./doc/arquitetura.md).
O modelo multi-tenant e as políticas iniciais de leitura já foram aplicados ao
Supabase; as operações de escrita e os módulos de negócio ainda estão sendo
implementados incrementalmente.

## Autenticação

O acesso inicial usa e-mail e senha por Supabase Auth. A implementação atual
ainda não oferece cadastro público. Visitantes acessam anonimamente, sem conta,
somente o conteúdo publicado da igreja indicada pelo link público enviado por
ela. O link não identifica nem restringe seu destinatário: quem também receber
o link público de outra igreja poderá consultar somente o conteúdo que ela
publicou. Dados privados permanecem isolados por igreja. Contas de membros
serão vinculadas a cadastros existentes por convite e verificação de e-mail.
Sessões usam cookies SSR, renovados pelo `proxy.ts`, e o grupo de rotas do
dashboard verifica os claims no servidor.

O banco já contém papéis, pacotes de permissões, RLS inicial e RPCs para
provisionamento, configuração de Secundários, cadastro de membros com limite
transacional e transferência/remoção auditada de atribuições. O dashboard
permite ao Administrador Sênior transferir e remover atribuições; as demais
operações e as permissões por módulo ainda não estão integradas à aplicação.
A autenticação sozinha não concede acesso a operações administrativas.

## Estado atual

A fundação usa Next.js App Router, TypeScript e Tailwind CSS, com login,
logout e uma rota inicial protegida. O modelo e as políticas-base estão
aplicados no Supabase; os módulos de negócio e a integração da aplicação ainda
não foram implementados.
