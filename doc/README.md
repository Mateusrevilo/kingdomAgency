# Documentação do Sistema

## 1. Introdução

A presente documentação descreve a proposta e a base tecnológica do sistema Kingdown, uma solução web para gestão de igrejas e organizações religiosas. O objetivo principal é disponibilizar um ambiente digital para o controle de membros, eventos, finanças, ministérios e demais atividades administrativas, com foco em organização, rastreabilidade e segurança da informação.

O projeto foi inicializado com a estrutura de desenvolvimento em Next.js, utilizando TypeScript e Tailwind CSS. A solução está em fase de fundamentação arquitetural, com evolução planejada em etapas para incorporar autenticação, banco de dados, módulos de negócio e integrações específicas do contexto eclesiástico.

## 2. Objetivo do sistema

O sistema tem como finalidade centralizar e apoiar as operações administrativas de uma igreja, promovendo:

- cadastro e manutenção de membros;
- organização de ministérios e grupos de atuação;
- gerenciamento de eventos e frequências;
- acompanhamento de contribuições e finanças;
- controle de acesso e autenticação para usuários internos;
- geração de relatórios e consultas operacionais;
- suporte à gestão administrativa e pastoral.

## 3. Escopo

O escopo inicial do sistema contempla a base técnica e a estrutura conceitual da aplicação. Em termos de desenvolvimento, a etapa atual inclui a criação da fundação da solução, com o ambiente web configurado e a base de interface pronta para expansão.

As futuras entregas do projeto incluem:

- autenticação e autorização de usuários;
- integração com banco de dados relacional;
- módulos de membros, eventos e finanças;
- painel administrativo e dashboards;
- proteção de rotas e controle de permissões;
- implementação de regras de negócio específicas da organização.

## 4. Stack tecnológica

A solução utiliza as seguintes tecnologias:

- Next.js 16
- React 19
- TypeScript
- Tailwind CSS
- App Router do Next.js

## 5. Requisitos do ambiente

Para executar o projeto localmente, são necessários:

- Node.js 20.9 ou superior;
- npm;
- ambiente de desenvolvimento compatível com aplicações web em Next.js.

## 6. Configuração e execução

### 6.1 Instalação das dependências

```bash
npm install
```

### 6.2 Execução em ambiente de desenvolvimento

```bash
npm run dev
```

### 6.3 Acesso local

A aplicação pode ser acessada em:

```text
http://localhost:3000
```

## 7. Scripts disponíveis

```bash
npm run dev
npm run build
npm run start
npm run lint
```

## 8. Estrutura do projeto

```text
kingdown/
├── src/
│   └── app/
│       ├── layout.tsx
│       ├── page.tsx
│       └── globals.css
├── public/
├── package.json
├── tsconfig.json
├── next.config.ts
├── eslint.config.mjs
├── README.md
├── doc/
│   ├── README.md
│   └── arquitetura.md
└── .gitignore
```

## 9. Estado atual da implementação

A base inicial da aplicação já foi estruturada e validada, incluindo:

- criação do projeto com Next.js;
- configuração do ambiente em TypeScript;
- uso de Tailwind CSS para estilização;
- estrutura inicial de layout e página principal.

No momento, o sistema ainda não possui:

- integração com banco de dados definitiva;
- autenticação funcional;
- módulos de negócios completos;
- regras de acesso e autorização implementadas.

## 10. Fase atual e próximos passos

A solução encontra-se em fase inicial de desenvolvimento, com foco em estabelecer a base estrutural e tecnológica adequada para expansão. As próximas etapas estratégicas incluem:

1. configuração do Supabase para persistência e autenticação;
2. definição dos modelos de dados centrais;
3. implementação de autenticação e sessões seguras;
4. criação dos módulos iniciais de membros, frequência e dashboard;
5. proteção de rotas e controle de permissões por perfil;
6. evolução para funcionalidades administrativas e pastorais avançadas.

## 11. Documentação relacionada

- [Arquitetura do Sistema](./arquitetura.md)

## 12. Considerações finais

O projeto encontra-se em desenvolvimento incremental e ainda não deve ser considerado pronto para produção. A arquitetura atual foi concebida para permitir crescimento ordenado, modularização tecnológica e evolução contínua dos módulos conforme as necessidades operacionais da igreja forem definidas e validadas.
