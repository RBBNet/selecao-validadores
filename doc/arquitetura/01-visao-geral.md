# 1. Visão Geral da Arquitetura e Regras de Segurança

O sistema é composto por **2 contratos** a serem implementados e **3 contratos externos** do Permissionamento RBB:

![Visão Geral da Arquitetura](validator-selection.svg)


## 1.1 Contratos e Objetivos

* **`ValidatorSelectionIngress`**: Ponto de entrada fixo (fachada) para o Besu consultar validadores operacionais. Evita *hard forks* ao permitir atualização do contrato de lógica por baixo. Delega todas as chamadas de `getValidators()` ao contrato de lógica.
* **`ValidatorSelection`**: Implementa a lógica de gestão e seleção automática de validadores (modos Manual/Automatic) e integrações com o permissionamento.

## 1.2 Regras de Controle de Acesso e Papéis

| Papel | Permissões | Verificação (Requisitos de Segurança) |
|-------|-----------|-------------|
| **Governança** | Modificar parâmetros, alterar contratos de lógica, adicionar/remover elegíveis, adicionar/remover operacionais (via endereço). | Modificador `onlyGovernance` que valida via `AdminProxy.isAuthorized(msg.sender)`. |
| **Global Admin** | Adicionar ou remover operacionais da própria organização. | `AccountRulesV2.hasRole(GLOBAL_ADMIN_ROLE, msg.sender)` + `isAccountActive(msg.sender)` + correspondência do `orgId`. |
| **Local Admin** | Adicionar ou remover operacionais da própria organização. | `AccountRulesV2.hasRole(LOCAL_ADMIN_ROLE, msg.sender)` + `isAccountActive(msg.sender)` + correspondência do `orgId`. |
| **Qualquer Conta** | Acionar `executeMonitoring()` e realizar consultas `view`. | Sem restrições de acesso. |

## 1.3 Invariantes Críticas de Dados

O código deve assegurar e manter consistentes as seguintes regras:
1. **`operationalValidators ⊆ eligibleValidators`**: Um validador só pode ser operacional se for elegível.
2. **`protectedValidators ⊆ operationalValidators`**: Validadores protegidos temporariamente devem estar no conjunto operacional.
3. **Mínimo de Validadores Operacionais:**
   * A governança (remoção manual) pode remover validadores operacionais até restar no mínimo `1` validador operacional ativo no conjunto.
   * Administradores (remoção manual) podem remover validadores operacionais até restar no mínimo `4` validadores operacionais ativos no conjunto.
   * A seleção automática (remoção via monitoramento) só pode remover validadores operacionais se restarem no mínimo `4` validadores operacionais ativos no conjunto.
4. **Limite Mínimo de Inatividade (`blocksWithoutProposeThreshold`):**
   * O valor do parâmetro deve ser sempre maior ou igual à quantidade de validadores elegíveis (`blocksWithoutProposeThreshold >= eligibleValidators.length`).
   * Caso a adição de um novo validador elegível pela governança faça com que o limite seja inferior à nova quantidade de elegíveis, o parâmetro deve ser reajustado automaticamente para igualar o tamanho atual do conjunto.

## 1.4 Decisões Arquiteturais Relevantes

* <a id="da-01"></a>**DA-01 (Padrão Ingress/Facade sem Proxy de Storage):**
  * **Descrição:** O contrato `ValidatorSelection` é convencional e não utiliza proxies (como UUPS ou Proxy Transparente). A atualização é feita implantando um novo contrato estático e atualizando o endereço apontado no `ValidatorSelectionIngress`.
  * **Justificativa:** Evita a necessidade de realizar novas transições (*hard forks*) no arquivo gênesis do Besu ao atualizar a lógica do contrato. O endereço fixo configurado no Besu é o do `Ingress`. Optar por uma fachada simples em vez de proxies complexos de storage reduz drasticamente a complexidade do código, facilita a auditoria, a implementação e previne problemas associados à colisão de slots de armazenamento e à atualização do contrato de lógica, sendo o custo de gas de reimplantação irrelevante devido à baixa frequência de atualizações.
  * **Histórias de Usuário Associadas:** [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US1-3](../requisitos/01-selecao-validadores.md#us1-3), [US2-3](../requisitos/02-ingress-selecao-validadores.md#us2-3), [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3), [US5-4](../requisitos/02-ingress-selecao-validadores.md#us5-4)

* <a id="da-02"></a>**DA-02 (Validação try/catch para Interfaces Legadas):**
  * **Descrição:** A validação de que os contratos de destino (`AdminProxy`, `ValidatorSelection`) implementam funções esperadas (como `isAuthorized` ou `getValidators`) é realizada via chamadas externas protegidas por blocos `try/catch`.
  * **Justificativa:** Os contratos de permissionamento legados da RBB (como o `AdminProxy` original da gen01) não implementam o padrão ERC-165 (`supportsInterface`). Utilizar `try/catch` nas chamadas de validação permite atestar a existência e o comportamento seguro das funções de forma dinâmica sem exigir refatoração ou reimplantação dos contratos legados da rede.
  * **Histórias de Usuário Associadas:** [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US2-3](../requisitos/02-ingress-selecao-validadores.md#us2-3), [US5-1](../requisitos/01-selecao-validadores.md#us5-1), [US5-3](../requisitos/02-ingress-selecao-validadores.md#us5-3), [US5-5](../requisitos/02-ingress-selecao-validadores.md#us5-5)

* <a id="da-03"></a>**DA-03 (Desacoplamento e Baixo Acoplamento com Permissionamento):**
  * **Descrição:** O cadastro e a adição de validadores elegíveis ou operacionais pelo contrato de seleção não fazem validações diretas de estado (como verificar se o nó está ativamente permissionado) contra outros contratos de permissionamento da RBB.
  * **Justificativa:** Conforme discutido em *USSV01*, *USSV06*, *USSV08* e *USSV11*, realizar essas verificações criaria um alto acoplamento entre os contratos e aumentaria substancialmente a complexidade do código, não compensando o ganho de apenas mitigar erros operacionais (que podem ser prevenidos off-chain ou por ações da governança).
  * **Histórias de Usuário Associadas:** [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3), [US4-4](../requisitos/01-selecao-validadores.md#us4-4)

* <a id="da-04"></a>**DA-04 (Algoritmo de Monitoração com Dois Parâmetros):**
  * **Descrição:** A seleção e avaliação automática baseiam-se em dois parâmetros distintos: `blocksBetweenSelection` (intervalo de blocos para avaliação) e `blocksWithoutProposeThreshold` (limite tolerado de inatividade para proposta de blocos).
  * **Justificativa:** Esta configuração provê maior flexibilidade e responsividade para identificar e remover rapidamente nós inativos (especialmente em quedas que transpassam o ciclo nominal) sem adicionar complexidade algorítmica significativa.
  * **Histórias de Usuário Associadas:** [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3)

* <a id="da-05"></a>**DA-05 (Proteção Contra Remoção Precoce via Conjunto Temporário):**
  * **Descrição:** Utilização de um conjunto temporário de validadores protegidos (`protectedValidators`) para protegê-los de remoção na avaliação de inatividade imediata subsequente à sua inclusão ou reconfiguração.
  * **Justificativa:** Garante que validadores novos ou reativados não sejam removidos indevidamente no fechamento de um ciclo de monitoração antes de terem tido a oportunidade e o tempo necessário para propor blocos na rede.
  * **Histórias de Usuário Associadas:** [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US3-1](../requisitos/01-selecao-validadores.md#us3-1), [US3-2](../requisitos/01-selecao-validadores.md#us3-2), [US3-3](../requisitos/01-selecao-validadores.md#us3-3), [US4-1](../requisitos/01-selecao-validadores.md#us4-1), [US4-2](../requisitos/01-selecao-validadores.md#us4-2), [US4-3](../requisitos/01-selecao-validadores.md#us4-3)

* <a id="da-06"></a>**DA-06 (Remoção Agrupada de Validadores Inoperantes):**
  * **Descrição:** No ciclo de monitoração automática, todos os validadores que ultrapassarem o limite de inatividade são removidos de uma só vez (desde que respeitado o limite mínimo de 4 operacionais).
  * **Justificativa:** Prioriza a rápida convergência do consenso para o tempo nominal de geração de blocos (4 segundos no QBFT) da RBB, evitando a degradação prolongada da performance do consenso decorrente de uma remoção gradual/unitária de validadores inativos.
  * **Histórias de Usuário Associadas:** [US3-3](../requisitos/01-selecao-validadores.md#us3-3)

* <a id="da-07"></a>**DA-07 (Simplificação da Lógica de Fallback no Ingress):**
  * **Descrição:** O contrato `ValidatorSelectionIngress` atua estritamente como fachada de encaminhamento, sem a implementação de lógica interna de fallback complexa (como listas estáticas de validadores de emergência ou desvio automático para a lista de elegíveis), mas com um fallback simples e sem estado que retorna o validador do bloco atual (`block.coinbase`) em caso de falha ou retorno vazio.
  * **Justificativa:** O principal fator de segurança do `Ingress` é a simplicidade e a ausência de estado complexo, o que minimiza a probabilidade de bugs. Como o `Ingress` não pode ser atualizado sem um *hard fork*, delegar proteções de consenso (como manter no mínimo 1 ou 4 validadores) ao contrato de lógica atualizável é uma abordagem mais segura. O fallback simples para `block.coinbase` impede paradas no consenso e mantém o acoplamento mínimo.
  * **Histórias de Usuário Associadas:** [US1-2](../requisitos/02-ingress-selecao-validadores.md#us1-2), [US2-3](../requisitos/02-ingress-selecao-validadores.md#us2-3)

* <a id="da-08"></a>**DA-08 (Sem Restrição de Acesso na Função de Monitoração):**
  * **Descrição:** A função `executeMonitoring()` pode ser disparada por qualquer conta externa sem verificação de papéis (roles).
  * **Justificativa:** Nesta função, restrições de papel não eliminam potenciais vetores de DoS baseados em spam de transações. Além disso, sem controle de acesso, tornamos possível que qualquer entidade possa contribuir com o monitoramento dos validadores.
  * **Histórias de Usuário Associadas:** [US3-3](../requisitos/01-selecao-validadores.md#us3-3)

* <a id="da-09"></a>**DA-09 (Suporte ao Padrão ERC-165 para os Novos Contratos):**
  * **Descrição:** Tanto o contrato `ValidatorSelection` quanto o `ValidatorSelectionIngress` devem implementar a interface padrão **ERC-165** (`supportsInterface`) para expor e permitir a verificação das assinaturas de suas interfaces ativas.
  * **Justificativa:** Diferente dos contratos correntes da RBB (como o `AdminProxy` original da gen01) que não oferecem suporte a essa introspecção, os novos contratos inteligentes devem seguir as melhores práticas atuais de desenvolvimento na RBB, facilitando a interoperabilidade e validação dinâmica de interfaces no ecossistema sem incorrer em acoplamento rígido.
  * **Histórias de Usuário Associadas:** [US1-1](../requisitos/01-selecao-validadores.md#us1-1), [US5-2](../requisitos/01-selecao-validadores.md#us5-2)
