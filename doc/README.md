# Seleção de Validadores RBB — Repositório de Documentação

Este repositório organiza as especificações funcionais, histórias de usuário, diagramas de arquitetura e detalhamento técnico do mecanismo de seleção de validadores *on-chain* da Rede Blockchain Brasil (RBB).

---

## Organização do Repositório

A documentação está estruturada em três áreas principais para facilitar a navegação e manutenção:

### 1. [Requisitos](requisitos/)
Contém a especificação de negócio e histórias de usuário (US) detalhando o comportamento esperado de cada componente:
*   [01. Lógica de Seleção de Validadores *on-chain*](requisitos/01-selecao-validadores.md) — Requisitos e critérios de aceitação do contrato de lógica.
*   [02. Ingress de Seleção de Validadores](requisitos/02-ingress-selecao-validadores.md) — Requisitos do contrato fachada/ingress usado para evitar *hard forks*.

### 2. [Arquitetura](arquitetura/)
Apresenta o fluxo de design macro do sistema e decisões de alto nível:
*   [01. Visão Geral da Arquitetura](arquitetura/01-visao-geral.md) — Visão geral de componentes, fluxo de atores, invariantes críticas de dados e controle de acesso.
*   [Diagrama de Arquitetura (SVG)](arquitetura/validator-selection.svg) — Representação visual do fluxo de chamadas e integrações do sistema.

### 3. [Especificação Técnica](especificacao-tecnica/)
Fornece o detalhamento técnico de engenharia diretamente direcionado ao desenvolvedor dos contratos inteligentes:
*   [01. Modelo de Contratos](especificacao-tecnica/01-modelo-contratos.md) — Definição do layout de storage, interfaces Solidity, eventos para logs de auditoria e erros customizados.
*   [02. Detalhamento de Funções e Algoritmos](especificacao-tecnica/02-especificacao-funcoes.md) — Regras de transição, validações e fluxos de algoritmos passo a passo para cada função.

