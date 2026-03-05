# Smart Contract `ValidatorSelection`

O contrato inteligente `ValidatorSelection` é responsável pelo gerenciamento dinâmico, monitoramento de disponibilidade (liveness) e rotação automática de validadores na Rede Blockchain Brasil (RBB).

## 📋 Visão Geral

O objetivo principal deste contrato é garantir a saúde e a performance da rede, monitorando quais validadores estão produzindo blocos e removendo automaticamente aqueles que ficarem inativos (offline) por um período superior ao limiar configurado.

O sistema classifica os validadores em dois grupos:

1. **Validadores Elegíveis (`ElegibleValidators`):** Nós aprovados pela governança que possuem permissão para validar, mas podem estar desligados ou em manutenção.
2. **Validadores Operacionais (`OperationalValidators`):** O subconjunto de nós elegíveis que está ativamente participando do consenso e propondo blocos.

## ⚙️ Funcionalidades Principais

### 1. Monitoramento de Liveness (Heartbeat)

A função `monitorsValidators()` atua como o mecanismo de verificação da rede.

* Ela identifica o `block.coinbase` (autor do bloco atual).
* Atualiza o registro `lastBlockProposedBy` para esse validador.
* Verifica se o ciclo atual (`blocksBetweenSelection`) foi concluído.

### 2. Seleção e Remoção Automática

Quando o bloco atual atinge o `nextSelectionBlock`, o contrato executa a lógica de saneamento:

1. Itera sobre todos os **Validadores Operacionais**.
2. Verifica a diferença entre o bloco atual e o último bloco proposto pelo validador.
3. Se a diferença for maior que `blocksWithoutProposeThreshold`, o validador é considerado inativo.
4. **Trava de Segurança:** O validador inativo é removido da lista operacional **apenas se** a rede mantiver, no mínimo, **4 validadores ativos** (requisito para tolerância a falhas em consenso QBFT).

### 3. Gestão de Organizações (Soberania Local)

O contrato permite que administradores de uma organização específica gerenciem seus próprios nós sem depender de uma votação de governança central para operações cotidianas:

* Um administrador da "Org A" pode adicionar ou remover um nó da "Org A" da lista de operacionais (desde que o nó já seja elegível).
* Isso é garantido pelo modificador `onlySameOrganization`, que valida o `orgId` do remetente e do nó alvo no contrato `NodeRules`.

## 📊 Parâmetros de Configuração

Os seguintes parâmetros podem ser ajustados via governança:

| Parâmetro | Descrição |
| :--- | :--- |
| `blocksBetweenSelection` | O intervalo de blocos (época) entre cada execução da lógica de verificação/remoção. |
| `blocksWithoutProposeThreshold` | O número máximo de blocos que um validador pode ficar sem propor antes de ser marcado para remoção. |
| `nextSelectionBlock` | O número do bloco onde a próxima verificação de seleção ocorrerá. |

## 🔐 Controle de Acesso

O contrato implementa controle de acesso granular:

* **`onlyGovernance`**: Acesso irrestrito. Pode alterar parâmetros globais e forçar a adição/remoção de qualquer validador.
* **`onlyActiveAdmin`**: Requer que o chamador tenha a role `GLOBAL_ADMIN_ROLE` ou `LOCAL_ADMIN_ROLE` e esteja ativo no `AccountRules`.
* **`onlySameOrganization`**: Garante que o administrador pertença à mesma organização do nó que está sendo manipulado.

## 🚀 Fluxo Lógico

Abaixo, um diagrama simplificado do fluxo da função `monitorsValidators`:

```mermaid
graph TD
    A[Chamada monitorsValidators] --> B{Já registrou este bloco?}
    B -- Sim --> C[Fim]
    B -- Não --> D[Registra block.coinbase]
    D --> E{É bloco de Seleção?}
    E -- Não --> C
    E -- Sim --> F[Verifica Inatividade]
    F --> G{Tempo s/ propor > Threshold?}
    G -- Sim --> H[Marca para Remoção]
    H --> I{Restarão >= 4 Validadores?}
    I -- Sim --> J[Remove Validador Operacional]
    I -- Não --> K[Mantém Validador por Segurança]
    J --> L[Atualiza nextSelectionBlock]
    K --> L
    L --> C
