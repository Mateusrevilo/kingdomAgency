# Página pública de planos

## 1. Identificação

- **Produto:** Kingdom
- **Rota:** `/planos`
- **Público:** visitantes que receberam um link de apresentação ou contratação
- **Autenticação:** não necessária para visualizar a página
- **Implementação:** `src/app/planos/page.tsx` e `src/app/planos/page.module.css`

## 2. Objetivo

A página apresenta a proposta comercial do Kingdom para igrejas interessadas
em organizar sua gestão. Ela explica os benefícios da solução, apresenta
níveis de pacote e recursos adicionais em consideração, e encaminha clientes
existentes à tela de login.

A rota é independente do fluxo autenticado do dashboard. Seu endereço pode
ser compartilhado diretamente com visitantes. A página inicial também contém
um link para `/planos`.

## 3. Conteúdo e navegação

A página é composta pelas seguintes áreas:

1. **Cabeçalho:** marca Kingdom, navegação por âncoras para benefícios, planos
   e dúvidas, e acesso à tela de login.
2. **Apresentação:** mensagem principal, resumo do produto e links para as
   seções de benefícios e planos.
3. **Benefícios:** centralização de informações, simplificação da rotina e
   possibilidade de evolução gradual.
4. **Planos propostos:** Essencial, Crescimento e Completo, com listas
   ilustrativas de recursos.
5. **Possibilidades adicionais:** módulos sob medida, acesso da equipe e
   acompanhamento da implantação.
6. **Dúvidas frequentes:** esclarecimentos sobre escolha do plano, módulos
   individuais e estado de disponibilidade.
7. **Contato e rodapé:** orientação para conversar com quem compartilhou o
   link e atalho de acesso para clientes.

Os links de navegação usam âncoras na própria página:

- `#beneficios`
- `#planos`
- `#perguntas`
- `#como-contratar`

O botão “Já sou cliente” e os links de acesso encaminham para `/login`. A
página não possui formulário de contratação ou processamento de pagamentos.

## 4. Pacotes apresentados

| Pacote | Proposta de conteúdo |
|---|---|
| Essencial | Cadastro e consulta de membros, organização de grupos e acesso da equipe administrativa |
| Crescimento | Recursos do Essencial, eventos, presença e relatórios |
| Completo | Recursos do Crescimento, gestão financeira, permissões e acompanhamento administrativo ampliado |

Os módulos sob medida são apresentados como uma possibilidade de composição
do pacote conforme as necessidades da igreja. Os nomes, recursos e níveis são
uma proposta para apresentação; não constituem confirmação de que cada
funcionalidade já esteja disponível no produto.

## 5. Condições comerciais e limitações

- Os preços não foram definidos; a página informa “Sob consulta”.
- Disponibilidade, condições e funcionalidades devem ser confirmadas com a
  equipe responsável.
- A página informa que o sistema está em desenvolvimento.
- Contratação e pagamento online não estão disponíveis.
- O contato comercial depende da pessoa ou equipe que compartilhou o link.
- Nenhum plano deve ser interpretado como uma assinatura ativa ou como
  confirmação de funcionalidades implementadas.

Antes de habilitar a venda, definir valores e condições, confirmar a
disponibilidade de cada recurso e atualizar o conteúdo para corresponder ao
produto efetivamente entregue.

## 6. Apresentação visual e acessibilidade

A página usa estilos locais em CSS Modules. O layout adapta cabeçalho,
conteúdo e cartões a telas menores e respeita a preferência do navegador por
redução de movimento. A navegação tem rótulos acessíveis e as perguntas
frequentes usam elementos HTML expansíveis.

A regra do Turbopack em `next.config.ts` limita o loader do Tailwind ao arquivo
`globals.css`, para que os estilos CSS Modules da página sejam compilados
separadamente e aplicados corretamente.

## 7. Metadados

A rota define título e descrição próprios para identificação no navegador e
compartilhamento:

- **Título:** Planos | Kingdom
- **Descrição:** Conheça os planos propostos do Kingdom para organizar a
  gestão da sua igreja.
