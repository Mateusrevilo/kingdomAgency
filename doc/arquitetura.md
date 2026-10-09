# Arquitetura do Sistema

## 1. Princípios

- Aplicação web como monólito modular em Next.js App Router e TypeScript.
- Supabase fornece inicialmente PostgreSQL, Auth e, se necessário,
  armazenamento; o domínio não deve depender de detalhes do fornecedor sem
  necessidade.
- PostgreSQL é a autoridade para integridade, isolamento e regras concorrentes.
- Autorização é aplicada no servidor e reforçada por RLS.
- Identidade, conta, vínculo à igreja, papel, permissões, escopo e capacidade
  são conceitos distintos.
- Construção incremental: documentar e aprovar o modelo antes de criar
  migrações ou funcionalidades novas.
- Sem Docker nesta fase; preservar portabilidade para PostgreSQL próprio no
  futuro.

## 2. Componentes e limites

### 2.1 Next.js

O App Router organiza rotas, layouts, Server Components, Client Components,
Server Actions e Route Handlers. Server Components são o padrão para leitura e
renderização. Client Components ficam para interações que precisem de estado no
navegador.

Server Actions processam operações originadas pela interface. Route Handlers
atendem APIs HTTP, webhooks e integrações externas. Ambos validam entrada,
identidade, contexto e autorização no servidor; uma rota protegida não deve
confiar apenas na navegação ou nos controles visuais.

### 2.2 Supabase Auth e sessão

A autenticação existente usa Supabase Auth com cliente SSR baseado em cookies.
O `src/proxy.ts` renova tokens e protege as rotas iniciais. A sessão responde
“quem está autenticado”; ela não determina, por si só, qual papel essa pessoa
tem em cada igreja.

O perfil da aplicação deve associar a conta Supabase Auth à entidade da pessoa,
sem tornar a tabela interna de perfis uma cópia indiscriminada dos dados do
provedor. Segredos de serviço nunca são enviados ao browser.

### 2.3 Domínio e acesso a dados

Módulos como pessoas, igrejas, membros, permissões, eventos e contribuições
mantêm suas validações próximas ao domínio. Services são usados para regras de
negócio coordenadas ou reutilizadas. Repositories isolam acesso quando
necessário para testes ou portabilidade; não são obrigatórios para toda
consulta simples.

```text
Interface
  → Server Component / Server Action / Route Handler
  → validação de entrada
  → identidade e contexto de igreja
  → autorização e regra de domínio
  → acesso a dados
  → PostgreSQL via Supabase, protegido por RLS
```

Uma migração futura para PostgreSQL próprio também exige substituir ou
reimplementar Auth e Storage caso tenham sido utilizados; abstrair o banco não
torna automaticamente esses serviços portáveis.

## 3. Modelo de identidade e autorização

### 3.1 Conceitos separados

1. **Pessoa (`people`)**: identidade civil/de contato no domínio. Pode existir
   sem acesso digital e pertence a uma única igreja.
2. **Conta (`profiles`)**: identidade de autenticação, ligada ao ID de
   `auth.users` e, quando reivindicada/verificada, a uma pessoa. Na criação de
   igreja, a pessoa fundadora é vinculada imediatamente à conta do Sênior.
3. **Igreja (`churches`)**: tenant que delimita dados e administração.
4. **Vínculo (`church_memberships`)**: participação de uma pessoa em uma igreja,
   com estado próprio. Uma pessoa não terá vínculos em mais de uma igreja.
5. **Papel (`church_user_roles`)**: função da conta no contexto de uma igreja.
6. **Permissão (`permissions`)**: capacidade nomeada sobre recurso/operação.
7. **Escopo (`member_assignments`)**: vínculos de membros que um administrador
   pode gerir.
8. **Limite (`admin_member_limits`)**: capacidade máxima de membros atribuídos
   ao Administrador Secundário naquela igreja.

Uma pessoa pode existir sem conta ou ser membro sem conta; uma conta comum não
vira membro automaticamente; e um membro não recebe permissão administrativa
por ser membro. Visitantes são anônimos: não possuem conta nem perfil em
`auth.users`. Contas autenticadas destinam-se a membros e administradores.
Vincular uma conta a um cadastro de membro existente exigirá convite da igreja
e verificação do e-mail.

Cada igreja terá um slug no domínio da aplicação no MVP. Domínios ou
subdomínios personalizados ficam para uma etapa futura. O visitante recebe da
igreja o link da página pública; o slug do link delimita cada consulta anônima
ao tenant indicado. Não haverá diretório ou seletor de igrejas. Como o link é
público e não identifica seu destinatário, quem também receber o link de outra
igreja poderá ver somente o conteúdo público que ela publicou. Não é possível
restringir o acesso com base em quem recebeu ou compartilhou uma URL pública.
Dados e recursos privados permanecem isolados por tenant e nunca são
autorizados apenas por conhecer um slug.

### 3.2 Perfis e acesso efetivo

| Perfil | Acesso proposto |
|---|---|
| Visitante (anônimo) | Somente conteúdo publicado como público no tenant indicado pelo link; sem conta ou funcionalidades autenticadas. |
| Membro | Conteúdo público, dados próprios e participação permitida; sem gestão administrativa implícita. |
| Administrador Secundário | Permissões delegadas pelo Sênior, escopo restrito a membros atribuídos e limite de capacidade. |
| Administrador Sênior | Acesso administrativo total no tenant; não sujeito ao limite de membros dos Secundários. |

O papel Sênior deve ser protegido contra alterações feitas por Secundários. O
acesso total é derivado de regra controlada, não de uma lista de permissões que
um Secundário possa editar. Cada igreja deve manter ao menos um Administrador
Sênior ativo; não se permite desativar ou remover o último.

Permissões devem ser granulares, por exemplo `members.read_assigned`,
`members.create`, `groups.manage`, `events.manage`,
`contributions.read_own` e `contributions.read_all`. Permissões de leitura
própria e leitura administrativa não são equivalentes. O Sênior recebe acesso
administrativo derivado e controlado; concessões individuais restringem os
Secundários.

#### Matriz operacional proposta

| Operação | Visitante anônimo | Membro | Administrador Secundário | Administrador Sênior |
|---|---|---|---|---|
| Ler conteúdo publicado como público | Sim, somente no tenant do slug acessado | Sim | Sim | Sim |
| Ler ou alterar dados privados próprios | Não | Sim, somente campos/recursos próprios permitidos | Sim, dados próprios | Sim, dados próprios |
| Consultar dados de membros | Não | Não | Somente membros atribuídos e com permissão | Todos os membros da própria igreja |
| Cadastrar membro e atribuição inicial | Não | Não | Com `members.create`, dentro da capacidade | Sim, na própria igreja |
| Transferir/remover atribuição ou alterar limite | Não | Não | Não | Sim; somente dentro da própria igreja |
| Gerir grupos, eventos, cultos, serviços ou mídias | Não | Não | Somente com concessão explícita e no tenant | Sim, no tenant |
| Declarar contribuição própria | Não | Sim | Sim, apenas se também for membro e para si | Sim, apenas se também for membro e para si |
| Consultar contribuições de terceiros ou confirmar recebimento | Não | Não | Não por padrão; exige concessão explícita do Sênior | Sim, no tenant |
| Gerir papéis, permissões, limites e configurações da igreja | Não | Não | Não | Sim, no tenant |
| Consultar auditoria administrativa | Não | Não | Não por padrão | Sim, no tenant |

Esta matriz é a base aprovada para detalhamento, não uma autorização já
implementada. Todas as ações autenticadas também exigem vínculo ativo,
permissão atual e escopo correspondente; o Sênior não pode remover ou
desativar o último Sênior ativo da igreja.

### 3.3 Fluxos

Autenticação:

```text
Login
  → Supabase Auth valida credenciais
  → cookies SSR mantêm sessão
  → proxy renova token
  → servidor valida claims e identifica a conta
```

Autorização:

```text
Requisição autenticada
  → identidade da conta
  → pessoa associada e igreja/contexto solicitado
  → confirmação de vínculo ativo à igreja
  → papel e permissões atuais
  → escopo/atribuição e limite, quando aplicável
  → operação autorizada no servidor e filtrada por RLS
```

Uma pessoa sem sessão pode ler conteúdo explicitamente público somente no
tenant resolvido pelo slug do link. Isso não restringe quais links públicos
essa pessoa anônima pode receber ou abrir; tampouco concede acesso a dados
privados. Membros consultam somente os próprios registros privados.
Secundários consultam apenas dados autorizados e membros sob sua
responsabilidade. Sêniores administram dados dentro do tenant correspondente.

## 4. Modelo relacional

A lista abaixo descreve o modelo aprovado. A migration
`20261009175000_core_tenancy_authorization.sql` cria as entidades-base de
tenant, identidade, autorização e atribuições. Conteúdo, finanças, RPCs de
escrita e integração da aplicação ainda não estão implementados.

| Tabela/entidade | Chaves, relação e integridade |
|---|---|
| `churches` | PK da igreja; `slug` único; raiz das FKs e políticas de tenant. |
| `people` | Pessoa registrada internamente, com dados minimizados e `church_id`; `UNIQUE(church_id, id)` para FKs tenant-scoped. Visitantes anônimos da página pública não geram linha. |
| `profiles` | PK/FK para `auth.users.id`; associação opcional e única a `people`, concluída por convite verificado ou no provisionamento da igreja pelo Sênior fundador. |
| `church_memberships` | PK `id`; vínculo de membro com `church_id`, `person_id`, estado e datas; FK composta para `people(church_id,id)` e `UNIQUE(person_id)` para impedir vínculo com mais de uma igreja. |
| `roles` / `church_user_roles` | Catálogo de papéis reservados e associação contextual entre igreja, conta e papel; recomendação de um papel-base por conta/igreja. |
| `permissions` / `role_permissions` | Catálogo estável de ações e permissões padrão por papel; o Sênior é protegido por regra de sistema, não por concessão editável por Secundário. |
| `permission_packages` / `package_permissions` / `admin_package_assignments` | Modelos de pacotes e sua atribuição contextual a Secundários; pacotes incluem secretaria, programação, grupos, conteúdo e finanças de alto privilégio. |
| `admin_permission_overrides` | Concessões ou negações específicas, escopadas por igreja e usuário, com concessor/revogação; somente Sênior altera. |
| `member_assignments` | Histórico entre vínculo e conta responsável, com início, encerramento, autor e motivo; no máximo uma atribuição aberta por membro. Encerramento registra transferência ou remoção explícita. |
| `admin_member_limits` | Uma capacidade por igreja e Administrador Secundário; limite não negativo. Mudanças são também auditadas. |
| `groups` / `group_memberships` | Grupos tenant-scoped e participação de membros; FKs compostas impedem associar membro de outra igreja. |
| `events` / `event_registrations` | Eventos e inscrições tenant-scoped; chave única evita inscrição duplicada. |
| `worship_services` / `services` | Cultos e oportunidades de serviço voluntário, cada qual com estado e visibilidade próprios. |
| `media_content` | Mídia tenant-scoped, privada por padrão; associações tipadas a cultos/eventos impedem referências cruzadas entre igrejas. |
| `contribution_declarations` | Declaração do membro, com valor `numeric`, tipo, moeda e vínculo; membro só cria/lê as próprias declarações. Estado de conciliação é derivado dos lançamentos. |
| `treasury_entries` | Confirmação/lançamento da tesouraria, com ator e data; pode referenciar uma declaração ou existir sem declaração, sem representar processamento de pagamento. |
| `service_participations` | Relação entre membro e serviço voluntário; FKs compostas e constraint única contra participação duplicada. |
| `audit_logs` | Tenant, ator, ação, alvo e instante; append-only para papéis de aplicação e sem cópia desnecessária de dados sensíveis. |

Dados pertencentes a uma igreja carregam `church_id` e, sempre que relacionam
duas entidades tenant-scoped, usam FKs compostas que incluam essa chave. Além
disso, unicidade por pessoa impede vínculo a mais de uma igreja. Índices devem
começar pelas chaves de tenant nas consultas tenant-scoped e incluir pessoa,
estado, data ou responsável conforme os padrões reais de leitura.

Visitantes que a equipe queira acompanhar são registros internos criados por
uma ação administrativa; não são contas nem representam os visitantes
anônimos que consultam o site público.

### 4.1 Convenções de colunas e integridade

- IDs de domínio são UUIDs; `churches.id` é a raiz do tenant e todo dado
  pertencente a igreja carrega `church_id`.
- Datas são `timestamptz`, armazenadas em UTC. Tabelas mutáveis têm
  `created_at` e `updated_at`; transições de estado relevantes também entram
  em `audit_logs`.
- `churches` tem `slug` obrigatório e único, normalizado em minúsculas e
  validado para conter somente caracteres de URL permitidos.
- `people` tem `UNIQUE(church_id, id)`. `church_memberships` contém
  `church_id`, `person_id`, `status` (`active`/`inactive`) e datas, com FK composta para
  `people(church_id,id)`, `UNIQUE(person_id)` e `UNIQUE(church_id,id)`.
  Estados permitidos são definidos por constraint/catálogo; não se cria uma
  segunda associação histórica para a mesma pessoa.
- `profiles.id` referencia `auth.users.id`; `person_id` é nullable e único.
  E-mail verificado e convites são responsabilidade do Supabase Auth, não uma
  segunda fonte de verdade mantida no perfil.
- `church_user_roles` usa chave composta `(church_id,user_id)` para manter um
  papel-base por conta/igreja. `admin_permission_overrides` guarda concessões
  ou negações adicionais/revogáveis, com igreja, usuário, permissão, concessor e instante
  de revogação; um índice único parcial por igreja, usuário e permissão
  (somente quando a concessão não está revogada) impede duplicatas ativas.
- `role_permissions` tem chave composta `(role_id,permission_id)`.
  `permissions.key` e `roles.key` são únicos e estáveis. A conta que concede
  uma permissão precisa ser Sênior ativo no mesmo tenant.
- `member_assignments` registra `church_id`, vínculo, responsável, autor,
  início e campos de encerramento (`ended_at`, `ended_by`, `end_reason`).
  `end_reason` distingue transferência e remoção; um índice único parcial
  permite no máximo uma atribuição aberta por vínculo. A atribuição aberta
  continua contando mesmo se a membership ficar inativa.
- `admin_member_limits` tem chave `(church_id,admin_user_id)` e
  `max_members >= 0`. Cada Secundário ativo precisa de uma linha de limite
  antes de receber atribuições. O alvo deve ser Secundário ativo no mesmo tenant;
  alterações de limite e de atribuição validam papel/escopo dentro da operação
  transacional, não por dados enviados pelo navegador.
- Conteúdo publicável usa estado de publicação e visibilidade explícitos.
  Somente a combinação `visibility = public` e `status = published` libera
  leitura anônima; os padrões são privado e não publicado. Mídia e relações
  tipadas com eventos/cultos carregam o mesmo `church_id`.
- Relações de associação usam FKs compostas com `church_id`; inscrições e
  participações têm unicidade pelo par de entidade e membership, impedindo
  duplicidade e associação entre tenants.
- Valores financeiros usam `numeric`, nunca ponto flutuante, e guardam código
  de moeda. Os valores permitidos para moeda e tipo de contribuição devem ser
  configurados antes das migrations, sem presumir moeda única.

Essas constraints são invariantes de projeto. Algumas, como garantir pelo
menos um Sênior ativo e validar que o responsável possui papel Secundário,
dependem de operações transacionais no banco, pois envolvem mais de uma linha.

### 4.2 Escopo e transferência de membros

Está definido que haverá um único responsável atual por vínculo de membro. Cada
atribuição contém igreja, vínculo do membro, conta responsável, criador,
instante inicial, instante final opcional e motivo. Ao cadastrar um membro, um
Administrador Secundário torna-se automaticamente o responsável inicial.
Somente o Administrador Sênior pode transferir o membro para outro responsável.
A transferência encerra a atribuição vigente e cria outra atomicamente; não
apaga nem reescreve o histórico.

O limite é contado como o número de atribuições atuais não removidas por
Administrador Secundário naquela igreja. A contagem não depende do estado do
vínculo: inativar o vínculo do membro não encerra a atribuição nem libera a
vaga. Somente a remoção explícita da atribuição pelo Sênior libera capacidade.
Não contam contas, visitantes nem atribuições históricas encerradas. A
alteração do limite é exclusiva do Sênior.

O Sênior pode reduzir o limite abaixo da quantidade já atribuída. Nesse estado
temporário acima do teto, novas atribuições e transferências para esse
administrador ficam bloqueadas até que a contagem esteja abaixo do novo limite.

Não basta consultar a contagem na aplicação antes de inserir: requisições
concorrentes poderiam ambas ver uma vaga. A operação deve usar transação/RPC no
PostgreSQL para:

1. validar o ator e o escopo do tenant;
2. bloquear a linha de limite do Secundário;
3. confirmar que a contagem atual está abaixo do limite configurado;
4. contar todas as atribuições atuais não removidas, inclusive as de vínculos
   inativos;
5. inserir/encerrar atribuições e gravar auditoria na mesma transação.

Transferências que bloqueiam duas capacidades devem adquirir locks em ordem
estável e confirmar ambas as contagens na mesma transação. Se a condição não
for atendida, a operação falha inteira, sem deixar associação parcial. Ao
atingir o teto, orientar a solicitar ao Sênior a remoção de uma atribuição ou o
aumento do limite.

### 4.3 Declarações e confirmações da tesouraria

`contribution_declarations` registra o que o membro declara; `treasury_entries`
registra valores efetivamente recebidos/confirmados pela tesouraria. Uma
declaração pode ter vários lançamentos parciais, e um lançamento pode existir
sem declaração prévia. Um lançamento sem declaração não cria automaticamente
uma declaração em nome do membro.

Cada declaração guarda igreja, membership do declarante, valor positivo em
`numeric`, moeda, tipo e instante declarado. Cada lançamento guarda igreja,
valor positivo, moeda, instante de recebimento, ator que registrou e,
opcionalmente, declaração e membership identificada. A relação opcional usa
FKs compostas para garantir que declaração, membership e lançamento pertençam
à mesma igreja; se houver declaração, o membership identificado deve ser o
mesmo declarante. A ausência de declaração não impede um lançamento interno.

O estado financeiro da declaração (pendente, parcial ou integralmente
confirmada) é derivado dos lançamentos válidos, não mantido como campo
independente. Em uma transação/RPC, o banco bloqueia a declaração, valida
moeda e tenant e recusa qualquer lançamento que faça o total confirmado
ultrapassar o valor declarado. Lançamento e auditoria são gravados na mesma
transação. Apenas usuários com `contributions.confirm` podem confirmar; o
Sênior tem essa permissão no tenant, e Secundários não a recebem por padrão.

Em relação a estornos e correções, o modelo-base deve preservar o histórico:
não se apaga, não se sobrescreve nem se reescreve um lançamento existente.
Um ajuste cria um novo registro vinculado ao lançamento original com `kind`
(`reversal`/`correction`), `amount`, motivo, usuário da ação e data. O ajuste
também deve respeitar a mesma igreja e a mesma moeda do lançamento original.
Uma correção parcial é permitida; o valor total de ajuste não pode exceder o
valor do lançamento original em uma mesma correção/estorno.

O catálogo de contribuições do MVP é:
- `tithe` (dízimo);
- `offering` (oferta);
- `special_contribution` (contribuição específica);
- `other` (outra), habilitada por configuração do Sênior.
Todos os valores usam `numeric(18,2)` e a moeda é sempre `BRL`. O campo
`currency_code` pode ser mantido fixo em `BRL` por garantia documental, mas
não deve ser um input livre do cliente.

As permissões por pacote seguirão o modelo:
- `secretariat`: gestão de membros atribuídos, visitantes e registros básicos;
- `programming`: cultos, eventos, agenda e serviços;
- `groups`: grupos, voluntariado e participação;
- `content`: publicação e mídia do tenant;
- `finance_high_privilege`: conferência e confirmação financeira, acessível ao
  Sênior por padrão e só concedida por pacote específico a um Secundário
  quando formalmente autorizado.

Cada pacote pode ser ajustado pelo Sênior por usuário e igreja; não é uma
lista fixa inalterável. O Sênior permanece o único perfil capaz de conceder,
revogar, criar ou alterar limites e pacotes para Secundários. O pacote de
finanças não entra entre as permissões normais por padrão.

Esta proposta não processa pagamentos. Não se deve apagar ou sobrescrever um
recebimento sem trilha de auditoria.

## 5. Isolamento multi-tenant e RLS

O banco deve ser desenhado para multi-tenancy desde o início. Toda tabela de
domínio que contenha dados de uma igreja carrega `church_id` ou referencia
uma chave que o determine sem ambiguidade. Cada solicitação determina o
contexto da igreja por associação confiável no servidor; não aceita como prova
de autorização um `church_id`, papel, escopo ou responsável fornecido pelo
cliente.

RLS deverá:

- liberar leitura anônima apenas para conteúdo marcado como público e publicado;
- restringir dados privados de membro à pessoa autenticada e ao vínculo da
  igreja apropriado;
- limitar administradores secundários às permissões concedidas e aos membros
  com atribuição atual não removida;
- permitir ao Administrador Sênior administração dentro da igreja;
- impedir acesso cruzado entre tenants em todas as entidades relacionadas;
- proteger alterações de papéis, permissões e limites contra administradores
  sem competência.

Server Actions, Route Handlers e Services verificam as mesmas regras antes das
operações, mas RLS permanece uma barreira independente contra consultas
indevidas. Funções usadas por políticas devem evitar recursão, fixar com
segurança `search_path` quando aplicável e não confiar em parâmetros fornecidos
livremente pelo usuário. A chave `service_role` não deve ser usada para
contornar RLS no fluxo normal.

## 6. Áreas e módulos previstos

### Área pública

- página inicial e informações da igreja;
- cultos ao vivo e gravações publicados;
- agenda, eventos e horários públicos;
- grupos e iniciativas definidos como públicos;
- orientações públicas sobre contribuições;
- oportunidades de voluntariado abertas.

### Área do membro

- dashboard pessoal e perfil;
- contribuições próprias;
- eventos, inscrições e participações próprias;
- serviços voluntários;
- grupos aos quais o membro tem acesso.

### Área administrativa secundária

- dashboard com dados permitidos;
- membros sob responsabilidade;
- gestão de grupos, atividades, cultos e eventos delegados;
- relatórios da área autorizada;
- utilização da capacidade atribuída.

### Área administrativa sênior

- visão geral e membros/visitantes do tenant;
- administradores secundários, distribuição e limites;
- permissões, cultos, eventos, grupos, serviços e mídia;
- contribuições, relatórios, configurações e auditoria.

Menu e páginas refletem permissões para orientar a experiência, mas chamadas
diretas a endpoints e ações também precisam ser protegidas no servidor e no
banco.

## 7. Auditoria, privacidade e observabilidade

Auditar criação, alteração e desativação de usuários, mudanças de permissões e
limites, transferências de membros e mudanças críticas de configuração.
Registrar ator, igreja, ação, alvo, data/hora e contexto mínimo necessário,
evitando replicar credenciais ou dados pessoais desnecessários.

Dados pessoais, financeiros e religiosos exigem controle de acesso restrito,
minimização e retenção alinhados à LGPD. Erros de autorização e falhas de
infraestrutura não devem ser convertidos em respostas que pareçam sucesso.
Rate limiting é relevante especialmente para login e operações de alto risco.

## 8. Decisões de negócio confirmadas

- Cada igreja usa um slug no domínio da aplicação no MVP; domínios
  personalizados ficam para depois.
- Cada pessoa pertence a uma única igreja; a aplicação poderá atender várias.
- Cada membro tem um único responsável atual. O Secundário que cadastra o
  membro recebe a atribuição inicial; somente o Sênior transfere membros.
- A capacidade conta atribuições atuais não removidas, inclusive quando o
  vínculo de membro está inativo. Somente o Sênior remove atribuições e libera
  vagas.
- Reduzir o limite abaixo da contagem atual é permitido, mas bloqueia novas
  atribuições até que a contagem esteja abaixo do novo limite.
- Visitantes acessam anonimamente, sem conta, somente o conteúdo publicado da
  igreja indicada pelo link. Não há diretório ou seletor de outras igrejas.
  Como links públicos são compartilháveis e não identificam destinatários,
  qualquer pessoa que receba o link público de outra igreja também poderá ver
  o conteúdo que ela publicou; dados privados continuam isolados. Contas de
  membros são associadas a cadastros existentes por convite e verificação de
  e-mail.
- O registro de contribuição feito pelo membro é uma declaração; a tesouraria
  confirma o recebimento separadamente. Confirmações parciais são permitidas
  em lançamentos múltiplos, e a tesouraria também pode registrar recebimento
  sem declaração prévia. O total confirmado não pode ultrapassar a declaração;
  isso é validado atomicamente. Estornos e correções preservam o histórico por
  novos lançamentos vinculados ao original; ajustes parciais e integrais são
  permitidos, sem exceder o valor original.
- Cultos, grupos, eventos e mídias são privados por padrão. A publicação exige
  ação explícita de administrador autorizado.
- Administradores Secundários não recebem acesso financeiro administrativo
  por padrão; o Sênior delega permissões específicas.
- Cada igreja deve manter ao menos um Administrador Sênior ativo.

Essas decisões orientam o modelo. Qualquer alteração futura que mude acesso,
capacidade ou privacidade requer nova confirmação antes de ser implementada.

## 9. Estado de implementação

Foi criada e aplicada ao projeto Supabase a migration-base
`20261009175000_core_tenancy_authorization.sql`, com igrejas, pessoas,
vínculos, papéis, permissões por pacotes, limites, atribuições, auditoria e
políticas iniciais de leitura. O SQL foi executado em PostgreSQL temporário,
com verificações básicas de isolamento e permissões.

A migration `20261009180500_church_and_member_rpcs.sql` foi criada, validada em
PostgreSQL temporário e aplicada ao Supabase; o lint remoto não encontrou erros
de schema. Ela adiciona RPCs para provisionar uma igreja e o primeiro Sênior,
configurar Secundários (incluindo pacotes e exceções), cadastrar membros com
atribuição inicial e impor a capacidade dentro de transações. Também impede
remover ou desativar o último Sênior ativo. Ainda não implementa
os módulos de conteúdo/financeiro nem integração com a aplicação Next.js.
A migration `20261009182000_member_assignment_management.sql` foi aplicada ao
Supabase e o lint remoto não encontrou erros. Ela adiciona RPCs do Sênior para
transferir ou remover atribuições, mantendo o histórico e registrando auditoria.

## 10. Roadmap incremental

1. Fundação Next.js, TypeScript e Tailwind — concluída.
2. Clientes Supabase SSR, configuração e vínculo local — concluída.
3. Login/logout, sessão SSR e proteção inicial do dashboard — concluída; sem
   papéis ou autorização por módulo.
4. Decisões de negócio para perfis, multi-tenancy e limites — concluídas nesta
   etapa documental.
5. Decisões de negócio, modelo relacional e matriz de permissões — concluídos.
6. Migration-base de tenant e autorização — criada, validada em PostgreSQL
   temporário e aplicada ao Supabase.
7. RPCs para provisionamento, configuração de Secundários e cadastro de
   membros — criadas, validadas em PostgreSQL temporário e aplicadas ao
   Supabase.
8. RPCs de transferência/remoção de atribuições — migration validada e aplicada
   ao Supabase. Integração Next.js pendente.
9. Conteúdo público com publicação explícita.
10. Portal pessoal do membro e autoatendimento permitido.
11. Gestão completa de membros, atribuições e capacidade.
12. Administração Sênior, delegação, auditoria e relatórios.
13. Cultos, eventos, contribuições e serviços voluntários em etapas próprias.

Membros avançados, visitantes, ministérios, células, eventos avançados,
financeiro administrativo amplo, estoque, patrimônio, WhatsApp e IA ficam fora
do MVP atual até priorização explícita.

## 11. Estado atual

O código atual oferece fundação Next.js, integração cliente/servidor com
Supabase, login por e-mail/senha, logout e proteção inicial de dashboard. Ainda
não existem no código os quatro perfis, papéis por igreja, associação de
pessoas/contas, autorização administrativa, multi-tenancy de domínio,
atribuições, limites, módulos de negócio, migrações de domínio ou políticas
RLS. Os itens descritos neste documento são requisitos e propostas para
revisão, não funcionalidades prontas.
