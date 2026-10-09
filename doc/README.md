# Requisitos e visão do sistema

## 1. Objetivo

O Kingdom é um sistema web para apoiar a gestão de igrejas, com áreas públicas,
funcionalidades para membros e ferramentas administrativas. O projeto é um
monólito modular em Next.js, TypeScript, Supabase e PostgreSQL. Nesta fase não
utiliza Docker.

Esta documentação atualiza os requisitos de perfis e gestão de membros. Ela
descreve decisões propostas para orientar uma futura modelagem; não representa
funcionalidades, tabelas ou políticas RLS já implementadas.

## 2. Perfis de acesso

O sistema distingue a pessoa, sua conta de acesso, seu vínculo com uma igreja,
seu papel naquela igreja e as permissões efetivas. Uma pessoa poderá ter
cadastro de membro sem conta de acesso. A existência de uma conta, ou de um
vínculo de membro, não concede privilégios administrativos automaticamente.

| Perfil | Conteúdo público | Dados pessoais e participação | Gestão de membros | Administração |
|---|---|---|---|---|
| Visitante (anônimo) | Consulta somente conteúdo público da igreja indicada pelo link | Não tem conta nem acesso a dados pessoais ou funcionalidades autenticadas | Não | Não |
| Membro | Acesso integral ao conteúdo publicado | Consulta e atualiza campos próprios permitidos; consulta as próprias contribuições, inscrições e participações | Não automaticamente | Somente responsabilidades e permissões expressamente concedidas |
| Administrador Secundário | Sim | Recursos próprios e administrativos dentro das permissões e do escopo | Apenas membros atualmente atribuídos a ele, conforme permissões | Módulos e ações delegados pelo Sênior; sujeito ao limite configurado |
| Administrador Sênior | Sim | Recursos próprios e dados administrativos da igreja | Todos os membros e visitantes da igreja | Administração total dentro da igreja; não sujeito ao limite de membros |

Cada pessoa pertence a uma única igreja. O sistema poderá atender múltiplas
igrejas, cada uma com URL própria por slug no domínio da aplicação no MVP;
domínios personalizados ficam para uma etapa futura. O visitante recebe da
igreja o link da página pública, sem criar conta. Cada requisição pública fica
limitada ao tenant indicado pelo link. Não haverá diretório ou seletor de
igrejas. Se também receber o link público de outra igreja, poderá consultar
somente o conteúdo que essa outra igreja publicou: um link público não
identifica a pessoa nem permite controlar quais outros links ela recebeu.
Dados e áreas privadas permanecem isolados por igreja.

A interface poderá adaptar menus e ações ao perfil, mas a autorização deverá
ser verificada no servidor e no banco; esconder controles na interface não
protege os dados.

## 3. Requisitos funcionais

### 3.1 Área pública

Não exige login para consultar informações que a igreja tenha publicado como
públicas. Poderá oferecer:

- página inicial e informações da igreja;
- cultos, horários, locais e transmissões ao vivo;
- gravações anteriores, quando disponibilizadas;
- agenda, eventos e atividades;
- grupos e iniciativas sociais com visibilidade pública;
- orientações públicas sobre dízimos e ofertas;
- oportunidades públicas de voluntariado;
- acesso anônimo à página pública da igreja indicada pelo link enviado por ela,
  sem conta, vínculo de membro ou seletor de outras igrejas.

Visitantes não acessam informações privadas de membros, dados administrativos
ou relatórios financeiros internos. A URL determina o tenant da consulta:
alterar o slug não concede acesso a registros privados daquela ou de outra
igreja.

### 3.2 Área do membro

Além do conteúdo público, membros autenticados poderão:

- consultar e atualizar dados pessoais especificamente permitidos;
- consultar somente as próprias contribuições;
- registrar dízimos e ofertas pelos meios que venham a ser definidos;
- inscrever-se em eventos e serviços voluntários;
- consultar as próprias inscrições e participações;
- consultar grupos e atividades aos quais tenham acesso.

Ser membro não permite consultar ou administrar outros membros. Uma
responsabilidade adicional, como liderança de grupo, exige autorização
específica e limitada ao respectivo escopo.

### 3.3 Administrador Secundário

O Sênior define as permissões administrativas, o escopo e a capacidade de cada
Secundário. Conforme as concessões, o Secundário poderá:

- consultar, cadastrar ou atualizar membros sob sua responsabilidade;
- acompanhar visitantes;
- gerir grupos, atividades, cultos, eventos e serviços;
- consultar relatórios limitados à área autorizada;
- visualizar a utilização da própria capacidade de membros.

Um Secundário não pode alterar suas próprias permissões ou limite, conceder
permissões, acessar membros fora de seu escopo, modificar ou rebaixar o Sênior,
nem ultrapassar a capacidade configurada.

Ao cadastrar um membro, o Secundário que o cadastrou torna-se seu responsável
inicial. Somente o Administrador Sênior poderá transferir o membro para outro
responsável. Contas de membros são criadas ou convidadas pela igreja. A
associação da conta a um cadastro existente ocorre por convite da igreja,
aceito após verificação do e-mail; visitantes não possuem conta.

Como o cadastro cria uma atribuição automaticamente, o sistema deve recusar a
operação quando o Secundário que cadastrou não tiver capacidade disponível.

### 3.4 Administrador Sênior

O Sênior tem acesso administrativo total dentro da igreja. Poderá gerir
usuários e administradores, permissões, limites, membros, visitantes, grupos,
cultos, eventos, contribuições, relatórios, configurações e auditoria. Não
estará sujeito ao limite de membros dos Secundários.

As regras devem impedir que um Secundário altere o papel ou as permissões do
Sênior. Cada igreja deve manter ao menos um Administrador Sênior ativo; não se
permite remover ou desativar o último.

## 4. Responsabilidade e limite de membros

### Regra definida

O limite é a quantidade máxima de **atribuições atuais** a um Administrador
Secundário, por igreja. Cada membro pode ter somente um responsável atual.
Uma atribuição continua ocupando vaga mesmo que o vínculo do membro seja
inativado; somente a remoção explícita da atribuição pelo Administrador Sênior
libera capacidade. Não corresponde à quantidade de contas, visitantes ou
histórico de atribuições encerradas. Cada pessoa pertence a uma única igreja.

Uma transferência, autorizada somente ao Administrador Sênior, encerra a
atribuição vigente e cria a nova atribuição sem apagar o histórico. A
transferência deve respeitar a capacidade do novo responsável.

### Operações e integridade

- O limite é configurado exclusivamente pelo Administrador Sênior.
- Reduzir o limite abaixo da quantidade já atribuída é permitido, mas bloqueia
  novas atribuições até a contagem atual ficar abaixo do novo limite.
- O servidor valida permissão, igreja e escopo antes de solicitar uma alteração.
- A operação que atribui ou transfere membros deve validar capacidade dentro
  de uma transação no PostgreSQL.
- A transação bloqueia a linha de capacidade pertinente, conta atribuições
  atuais não removidas, mesmo quando o vínculo do membro está inativo, e grava
  a mudança somente se a operação não ultrapassar a capacidade.
- Em transferências que envolvam duas capacidades, os bloqueios devem ser
  obtidos em ordem estável e as alterações concluídas atomicamente.
- A inativação do vínculo não remove automaticamente a atribuição nem libera
  vaga; o Administrador Sênior deve removê-la explicitamente.
- Ao atingir a capacidade, a operação é recusada; a interface deve orientar a
  liberar uma vaga ou solicitar aumento ao Sênior.

Uma validação apenas no navegador ou um padrão “contar e depois inserir” sem
bloqueio transacional não evita ultrapassagem por requisições simultâneas.

## 5. Modelo relacional aprovado como base

O modelo-base abaixo foi aprovado e está sendo implementado incrementalmente.
A migration inicial cria somente a base de identidade, tenant, autorização e
atribuições; esta lista também descreve módulos ainda futuros.

| Entidade | Responsabilidade |
|---|---|
| `churches` | Igreja e slug único; raiz do isolamento multi-tenant. |
| `people` / `church_memberships` | Pessoa registrada internamente e seu vínculo de membro com estado; uma pessoa pertence a uma só igreja. Visitante anônimo não gera registro. |
| `profiles` | Conta ligada a `auth.users` e, após convite/verificação, a no máximo uma pessoa. |
| `roles` / `church_user_roles` | Papéis contextuais à igreja; não decorrem da mera existência de uma conta. |
| `permissions` / `permission_packages` / `package_permissions` / `admin_package_assignments` / `admin_permission_overrides` | Catálogo, pacotes ajustáveis e exceções individuais; somente o Sênior delega. |
| `member_assignments` / `admin_member_limits` | Responsabilidade atual e histórica de membros e capacidade por Secundário. |
| `groups` / `group_memberships` | Grupos tenant-scoped e participação de membros da mesma igreja. |
| `events` / `event_registrations` / `worship_services` | Eventos, inscrições e cultos com estado e visibilidade explícitos. |
| `services` / `service_participations` | Oportunidades e participações em serviços voluntários. |
| `media_content` | Transmissões e gravações privadas por padrão e publicadas explicitamente. |
| `contribution_declarations` / `treasury_entries` | Declaração do membro separada da confirmação/lançamento da tesouraria. |
| `audit_logs` | Registro append-only de ações administrativas relevantes. |

Entidades relacionadas devem usar FKs compostas com `church_id` para impedir
relações entre igrejas; unicidade por pessoa impede vínculo em mais de uma
igreja. A especificação técnica completa e a matriz operacional estão em
[arquitetura](./arquitetura.md).

## 6. Autenticação e autorização

O fluxo de autenticação já implementado usa Supabase Auth, cookies SSR e
verificação server-side de claims:

```text
Login
  → Supabase Auth valida credenciais
  → sessão é mantida em cookies SSR
  → proxy renova a sessão e protege rotas
  → servidor identifica a conta
```

A autorização multi-igreja proposta acrescenta:

```text
Conta autenticada
  → pessoa e igreja/contexto
  → vínculo e papel naquela igreja
  → permissões administrativas efetivas
  → escopo atual de membros e limite aplicável
  → autorização no servidor e reforço por RLS
```

Login não equivale a autorização. Claims identificam a sessão; permissões
revogáveis e escopos devem ser consultados de fonte confiável no servidor e no
banco, em vez de depender exclusivamente de informação enviada pelo navegador
ou de claims antigos.

Como regra-base, visitantes anônimos leem apenas conteúdo público publicado no
tenant do slug acessado; membros acessam somente os próprios dados; Secundários
atuam com concessão explícita e no escopo de membros atribuídos; Sêniores
administram dentro do próprio tenant. A matriz detalhada aprovada como base
está em [arquitetura](./arquitetura.md).

## 7. Segurança, privacidade e auditoria

- Visitantes consultam somente conteúdo explicitamente público.
- Membros acessam somente seus próprios dados privados.
- Administradores Secundários acessam somente ações autorizadas e membros no
  escopo atual.
- Administradores Seniores acessam dados apenas dentro do contexto da igreja
  ativa.
- RLS deve reforçar o isolamento por igreja, usuário e escopo, sem confiar em
  `church_id`, papel ou IDs recebidos livremente do cliente.
- Server Actions, Route Handlers e serviços validam entrada, identidade e
  autorização antes de qualquer operação protegida.
- Limites e transferências exigem integridade transacional resistente a
  concorrência.
- Alterações administrativas, permissões, limites e transferências devem ser
  auditáveis.
- Chaves secretas, especialmente `service_role`, permanecem server-side e fora
  do controle de versão.
- Dados pessoais e financeiros requerem minimização, acesso restrito e
  retenção adequada à LGPD.

## 8. Decisões de negócio definidas

As seguintes regras foram confirmadas e devem orientar a modelagem posterior:

1. **Endereços das igrejas:** no MVP, cada igreja terá um slug no domínio da
   aplicação; domínio personalizado fica para depois.
2. **Pertencimento:** cada pessoa pertence a uma única igreja. A aplicação
   poderá atender diversas igrejas, isolando seus dados.
3. **Responsabilidade:** um único Administrador Secundário é responsável por
   cada membro por vez.
4. **Cadastro por Secundário:** o membro criado por um Secundário é atribuído
   automaticamente a esse administrador.
5. **Capacidade:** a contagem considera atribuições atuais não removidas.
   Inativar o vínculo não libera vaga; o Sênior deve remover a atribuição.
6. **Transferências:** somente o Administrador Sênior pode transferir membros
   entre responsáveis.
7. **Redução do limite:** pode deixar a quantidade atual temporariamente acima
   do novo teto; enquanto estiver acima, nenhuma nova atribuição é permitida.
8. **Acesso de visitantes:** visitantes são anônimos e não criam conta. A igreja
   envia o link da página pública, que só apresenta conteúdo publicado naquele
   tenant. Não há diretório ou seletor de outras igrejas. Como o link é público
   e não identifica quem o recebeu, qualquer pessoa que também receba o link
   público de outra igreja poderá ver somente o conteúdo que ela publicou.
   Contas de membros são vinculadas a cadastros existentes por convite da igreja
   e verificação do e-mail.
9. **Contribuições:** o registro feito pelo membro é uma declaração; a
   tesouraria confirma o recebimento separadamente. São permitidas confirmações
   parciais em vários lançamentos, e a tesouraria pode registrar recebimento
   sem declaração prévia. O total confirmado não pode ultrapassar a declaração.
   O histórico de lançamentos e ajustes é imutável: estorno ou correção cria um
   novo registro vinculado ao original, sem apagar ou reescrever o anterior.
   Isso não implica integração de pagamento.
10. **Publicação:** cultos, grupos, eventos e mídias são privados por padrão;
    um administrador autorizado deve marcá-los explicitamente como públicos.
11. **Finanças de Secundários:** nenhum acesso financeiro administrativo por
    padrão; o Sênior concede permissões específicas.
12. **Continuidade administrativa:** cada igreja deve manter ao menos um
    Administrador Sênior ativo; não se permite remover/desativar o último.

As regras de limite, convite, visibilidade e acesso financeiro também se
aplicam às Server Actions, Route Handlers e políticas do banco; não são
somente comportamentos de interface.

## 9. Estado das migrations

A migration `20261009175000_core_tenancy_authorization.sql` foi aplicada ao
Supabase e cria a base de igrejas, pessoas, vínculos, papéis, permissões por
pacote, limites, atribuições, auditoria e políticas iniciais de leitura. Ela
ainda não cria os módulos de conteúdo ou financeiro.

A migration `20261009180500_church_and_member_rpcs.sql` também foi aplicada ao
Supabase. Ela adiciona RPCs para criar igreja com o primeiro Administrador
Sênior, configurar Secundários (limites, pacotes e exceções de permissão) e
cadastrar membros com atribuição inicial em transação. A capacidade é
serializada com bloqueio da linha de limite; a operação falha sem inserir dados
quando o limite é atingido. Também protege o último Sênior ativo. Ainda faltam
integrar os RPCs à aplicação. A migration
`20261009182000_member_assignment_management.sql` foi validada em PostgreSQL
temporário e aplicada ao Supabase; o lint remoto não encontrou erros. Ela
adiciona RPCs do Sênior para transferir e remover atribuições, preservando
histórico e registrando auditoria.

## 10. Roadmap do MVP

1. Fundação Next.js, TypeScript e Tailwind CSS — concluída.
2. Integração base com Supabase e vínculo local do projeto — concluída.
3. Login, logout, sessão SSR e proteção inicial de rota — concluída; ainda sem
   autorização por perfil ou papel.
4. Atualização e confirmação das decisões de negócio — documentação desta
   etapa concluída.
5. Modelo relacional e decisões de negócio — aprovados.
6. Migration base de tenant e autorização — criada, validada em PostgreSQL
   temporário e aplicada ao projeto Supabase.
7. RPCs transacionais iniciais — migration criada, validada em PostgreSQL
   temporário, aplicada ao Supabase e lint remoto sem erros.
8. RPCs de transferência/remoção de atribuições — migration aplicada ao
   Supabase e lint remoto sem erros. Integrar os RPCs à aplicação em etapa
   posterior.
9. Módulos de conteúdo e financeiro.
10. Área pública e publicação controlada de cultos, agenda, grupos e mídias.
11. Área do membro e dados pessoais próprios.
12. Gestão de membros, atribuições e capacidade dos Administradores
   Secundários.
13. Administração sênior, permissões, relatórios e auditoria.
14. Contribuições e serviços voluntários conforme as regras definidas.

## 11. Estado de implementação

A aplicação tem fundação Next.js, integração cliente/servidor com Supabase e
autenticação inicial por e-mail e senha. A migration-base de multi-tenancy,
perfis, permissões, atribuições e políticas de leitura está no banco remoto.
A próxima migration, com RPCs transacionais para criação e configuração,
existe apenas localmente até sua aplicação. Os módulos de domínio e a
integração dessas operações com a interface ainda não estão implementados.
