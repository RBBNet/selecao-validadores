# Suíte de Testes Ponta a Ponta (E2E)

Suíte de testes ponta a ponta (*End-to-End*) para validação dos contratos `ValidatorSelection` e `ValidatorSelectionIngress` integrados a uma rede Hyperledger Besu em consenso QBFT ( cluster Docker local de 6 nós) e à pilha de permissionamento da RBB.

## 1. Escopo e Propósito

Enquanto a suíte unitária em Foundry (`forge test`) valida a lógica de execução e as transições de estado isoladas dos contratos em ambiente EVM simulado, a suíte E2E valida a integração com o nó cliente Besu e as premissas dinâmicas do consenso:

* **Correspondência do Proponente (`block.coinbase`)**: Validação de que a variável global de bloco no EVM reflete o endereço real do nó proponente do bloco QBFT.
* **Avanço Temporal e *Round-Robin***: Verificação do comportamento da rotação de validadores e cálculo de inatividade à medida que os blocos avançam autonomamente.
* **Resiliência de Quorum**: Garantia de aplicação do piso mínimo de 4 validadores operacionais para preservação do consenso contra cenários de degradação da rede.

Para a arquitetura dos contratos, consulte [`README.md`](../../README.md) e [`src/README.md`](../../src/README.md).

## 2. Pré-requisitos e Dependências

| Requisito | Componente / Ferramenta | Descrição |
| --- | --- | --- |
| **Docker** | Engine com suporte a `docker compose` | Orquestração do cluster local de 6 nós Besu QBFT |
| **Foundry** | `forge` e `cast` | Compilação de contratos, execução de scripts de deploy e chamadas JSON-RPC |

Os artefatos do cluster (imagem Docker do Besu, arquivo `genesis.json` e chaves dos nós) são provisionados automaticamente na primeira execução pelo script `test/e2e/docker/besu/setup.sh`.

## 3. Execução e Orquestração

### 3.1 Execução da Suíte Completa

Para executar sequencialmente todos os cenários com a reconstrução do ambiente:

```bash
test/e2e/run-e2e-besu.sh
```

### 3.2 Execução Seletiva e Parâmetros da CLI

O orquestrador `run-e2e-besu.sh` permite selecionar cenários específicos ou passar flags de ambiente:

```bash
# Executar um cenário específico (reaproveitando a rede ativa)
test/e2e/run-e2e-besu.sh 04

# Executar sequencialmente um subconjunto de cenários
test/e2e/run-e2e-besu.sh 05 06

# Forçar recriação do ambiente Docker antes do teste
test/e2e/run-e2e-besu.sh --fresh 04

# Listar cenários disponíveis
test/e2e/run-e2e-besu.sh --list

# Desmontar a infraestrutura Docker ao final
test/e2e/run-e2e-besu.sh --down
```

#### Execução Direta de um Cenário
Cada script de teste pode ser chamado diretamente sem o orquestrador:

```bash
test/e2e/cases/04-no-inativo-removido.sh
```

## 4. Arquitetura do Ambiente E2E e Consenso

### 4.1 Topologia da Rede Besu QBFT

O cluster consiste em 6 nós Besu em contêineres Docker (`test/e2e/docker/besu/`) operando em consenso QBFT com rotação *round-robin* (cada validador propõe 1 em cada 6 blocos em média).

Em um cluster de 6 nós ($N=6$), o quórum mínimo para validação de blocos é de $4$ assinaturas ($F=1$, onde $N \ge 3F+1$). A indisponibilidade simultânea de 3 nós paralisa a produção de blocos.

### 4.2 Modos de Integração do Consenso

A suíte valida os dois modos de seleção de validadores suportados pelo Besu:

* **`blockheader` (Modo Padrão)**: O conjunto de validadores é extraído dos cabeçalhos dos blocos. Alterações de estado nos contratos não alteram o consenso do nó; as asserções consultam o contrato Ingress via chamadas `eth_call` para validar a resposta lógica.
* **`contract` (Modo Ativo via Transição)**: Pós-transição de gênesis, o nó Besu consulta `getValidators()` no contrato Ingress a cada rodada do consenso, utilizando estritamente a lista retornada pelo contrato para validar propositores.

### 4.3 Mecanismo de Transição de Gênesis (Fork)

A alternância do modo `blockheader` para `contract` é configurada via bloco de transição (`transitions.qbft` em `genesis.json`) apontando para o endereço do `ValidatorSelectionIngress`. Como a alteração restringe-se ao bloco `config`, o *hash* do bloco gênesis permanece inalterado, permitindo a atualização *in-place*.

Cenários que realizam a transição alteram a configuração de runtime da rede. Ao serem concluídos, o orquestrador restaura automaticamente a infraestrutura no modo `blockheader` para o cenário seguinte.

### 4.4 Isolamento de Estado

* **Rede Docker Compartilhada**: A rede Docker permanece ativa entre os testes. O ambiente só é recriado se houver perda de conectividade, travamento de blocos ou pela flag `--fresh`.
* **Deploy Isolado por Teste**: Cada cenário executa a implantação de uma nova pilha de contratos (`DeployE2EStack.s.sol`), resetando o estado inicial dos contratos a cada execução.

### 4.5 Ciclo de Proteção e Prazos

 Validadores recém-promovidos ou configurados iniciam em estado **protegido** (imunes à remoção por inatividade) durante o primeiro ciclo de seleção.

* Cenários que verificam remoção por inatividade exigem **2 ciclos de seleção completos**: o primeiro consome a proteção e o segundo avalia a taxa de proposição de blocos.
* Considerando `blocksBetweenSelection = 30` e tempo de bloco de 2 segundos, cada ciclo consome cerca de 60 segundos.

## 5. Estrutura de Arquivos

Mapeamento do diretório `test/e2e/`:

| Artefato | Categoria | Descrição |
| --- | --- | --- |
| `run-e2e-besu.sh` | CLI / Orquestrador | Script principal de execução, parsing de argumentos e consolidação dos testes. |
| `cases/*.sh` | Cenários de Teste | Scripts executáveis dos cenários individuais. |
| `lib/common.sh` | Biblioteca | Utilitários de configuração, métodos auxiliares JSON-RPC e contabilização de erros. |
| `lib/net.sh` | Biblioteca | Gerenciamento do ciclo de vida dos contêineres Docker (start, stop, restart). |
| `lib/stack.sh` | Biblioteca | Deploy da pilha de contratos e transição para o modo `Automatic`. |
| `lib/cycle.sh` | Biblioteca | Monitoramento da geração de blocos e disparo dos ciclos de seleção. |
| `lib/consensus.sh` | Biblioteca | Aplicação da transição de gênesis no `genesis.json` e verificação do consenso Besu. |
| `lib/e2e.sh` | Biblioteca | Ponto de entrada modular para importação das bibliotecas `lib/*.sh`. |
| `scripts/DeployE2EStack.s.sol` | Script Solidity | Deploy da pilha inteira (`Admin`, `Organizations`, `Accounts`, `Nodes`, `Selection`, `Ingress`). |
| `scripts/DeployE2ESpareSelection.s.sol` | Script Solidity | Deploy de instância secundária de Lógica para testes de atualização no Ingress. |
| `docker/besu/` | Infraestrutura | Configurações do cluster Besu QBFT de 6 nós (`docker-compose.yml`, `Dockerfile`, `genesis.json`, `setup.sh`). |

## 6. Matriz e Especificação dos Casos de Teste

### 6.1 Matriz de Cobertura

| Caso | Identificador | Propósito | Tempo Estimado |
| --- | --- | --- | --- |
| **01** | `01-premissas-qbft` | Distribuição *round-robin* e correspondência de `block.coinbase` | ~10 s |
| **02** | `02-deploy-e-espelho` | Deploy da pilha completa e espelhamento pelo Ingress | ~10 s |
| **03** | `03-ciclo-saudavel` | Cobertura do monitoramento em operação normal sem remoções | ~2.5 min |
| **04** | `04-no-inativo-removido` | Remoção por inatividade e reinclusão via governança | ~2.5 min |
| **05** | `05-piso-veta-lote` | Aplicação do piso de resiliência ($N < 4$) vetando lote de inativos | ~2.5 min |
| **06** | `06-lote-removido-com-folga` | Remoção atômica de lote inativo mantendo margem acima do piso | ~2.5 min |
| **07** | `07-quebra-de-quorum` | Paralisação e recuperação da rede sob falha de quórum ($F \ge 3$) | ~2 min |
| **08** | `08-troca-da-logica-no-ingress` | Atualização dinâmica da Lógica no Ingress e política de *fallback* | ~25 s |
| **09** | `09-permissionamento-por-enode` | Governança baseada em *enode* contra contratos de permissionamento reais | ~40 s |
| **10** | `10-consenso-migra-para-o-contrato` | Transição de gênesis para o modo `contract` | ~3.5 min |
| **11** | `11-inatividade-real-no-consenso` | Remoção e reinclusão por inatividade com validação direta no consenso Besu | ~6 min |

### 6.2 Detalhamento dos Cenários

#### `01-premissas-qbft`
* **Escopo**: Integridade das premissas de proposição do QBFT.
* **Pré-condições**: Cluster Besu ativo em modo `blockheader`.
* **Procedimento**: Consulta o campo `miner` (`block.coinbase`) dos 6 primeiros blocos e lê a lista de validadores via RPC.
* **Critérios de Aceite**: Confirma 6 propositores distintos consecutivos (rotação *round-robin*) pertencentes ao conjunto do consenso.

#### `02-deploy-e-espelho`
* **Escopo**: Deploy da pilha E2E e vinculação com os contratos de permissionamento reais.
* **Pré-condições**: Cluster Besu ativo; conta de governança financiada.
* **Procedimento**: Executa `DeployE2EStack.s.sol`, verifica as referências dos contratos e checa o estado inicial do Ingress.
* **Critérios de Aceite**: Vinculação correta com `AdminProxy`, `AccountRulesV2Impl` e `NodeRulesV2Impl`; lista operacional inicial idêntica aos 6 nós ativos; espelhamento do Ingress compatível com a Lógica; inicialização em modo `Manual` com protegidos populados.

#### `03-ciclo-saudavel`
* **Escopo**: Monitoramento contínuo em ambiente estável no modo `Automatic`.
* **Pré-condições**: Cluster Besu ativo; pilha implantada; 6 validadores operacionais.
* **Procedimento**: Ativa o modo `Automatic`, executa 2 ciclos de seleção consecutivos e mede a amostragem de blocos.
* **Critérios de Aceite**: Proteção esvaziada ao término do 1º ciclo; zero remoções no 2º ciclo; manutenção dos 6 validadores operacionais e integridade do Ingress.

#### `04-no-inativo-removido`
* **Escopo**: Processamento automático de inatividade e fluxo de reinclusão via governança.
* **Pré-condições**: Cluster Besu ativo; pilha em modo `Automatic`; proteção inicial consumida.
* **Procedimento**: Para o contêiner Docker de 1 nó validador, executa 1 ciclo de seleção, religa o contêiner e solicita reinclusão via governança.
* **Critérios de Aceite**: Exclusão do nó inativo do conjunto operacional mantendo a elegibilidade (sobrando 5 operacionais); retorno ao conjunto operacional em estado protegido após aprovação da reinclusão.
* *Nota*: Asserção realizada no estado do contrato sob modo `blockheader`. A exclusão direta no consenso é testada no Caso 11.

#### `05-piso-veta-lote`
* **Escopo**: Veto de remoções por piso mínimo de resiliência ($N < 4$).
* **Pré-condições**: Cluster Besu ativo; pilha em modo `Automatic`.
* **Procedimento**: Configura o conjunto operacional com 3 nós reais e 3 endereços inativos (sem proposta de blocos) e executa 1 ciclo de seleção.
* **Critérios de Aceite**: Veto total da remoção pelo contrato; manutenção dos 3 nós inativos e preservação dos 6 validadores operacionais.
* *Nota*: A inatividade é simulada por endereços virtuais para evitar a paralisação do consenso provocada pela queda de 3 nós reais.

#### `06-lote-removido-com-folga`
* **Escopo**: Remoção atômica em lote quando o piso mínimo é mantido.
* **Pré-condições**: Cluster Besu ativo; pilha em modo `Automatic`.
* **Procedimento**: Expande o conjunto para 9 validadores operacionais (6 nós reais e 3 endereços inativos) e executa 1 ciclo de seleção.
* **Critérios de Aceite**: Remoção simultânea dos 3 endereços inativos em um único ciclo; manutenção dos 6 nós reais operacionais; preservação da elegibilidade dos nós removidos e atualização imediata do Ingress.

#### `07-quebra-de-quorum`
* **Escopo**: Comportamento da rede sob perda de quórum QBFT ($F \ge 3$).
* **Pré-condições**: Cluster Besu ativo em modo `Automatic`.
* **Procedimento**: Interrompe simultaneamente 3 contêineres de nós validadores, observa a rede por 30 segundos e religa os contêineres.
* **Critérios de Aceite**: Paralisação imediata da produção de blocos; preservação do estado do contrato (sem avanços de bloco); retomada automática da produção de blocos após a religação dos nós.

#### `08-troca-da-logica-no-ingress`
* **Escopo**: Substituição dinâmica do contrato de lógica no Ingress e mecanismo de *fallback*.
* **Pré-condições**: Cluster Besu ativo; pilha implantada.
* **Procedimento**: Implanta instância secundária (`DeployE2ESpareSelection.s.sol`), testa transações inválidas de atualização, atualiza o registro no Ingress, desvincula a lógica e reativa.
* **Critérios de Aceite**: Reversão das chamadas inválidas com os erros esperados (`SameAddress`, `InvalidAddress`, `InvalidValidatorSelectionContract`); atualização transparente do Ingress sem interrupção de blocos; retorno ao *fallback* (`block.coinbase`) quando a lógica é desvinculada.

#### `09-permissionamento-por-enode`
* **Escopo**: Funções orientadas a *enode* integradas aos contratos reais de permissionamento (`AccountRulesV2Impl` e `NodeRulesV2Impl`).
* **Pré-condições**: Cluster Besu ativo; pilha implantada; administrador da organização 2 configurado.
* **Procedimento**: Deriva o endereço Ethereum a partir da chave pública do *enode* de um nó Besu, executa operações de ativação/remoção por *enode* e verifica as permissões organizacionais.
* **Critérios de Aceite**: Correspondência exata entre o endereço derivado do *enode* e o proponente dos blocos; aplicação das restrições de permissão por organização e papel administrativo.

#### `10-consenso-migra-para-o-contrato`
* **Escopo**: Transição de gênesis que transfere o controle de validadores do cabeçalho do bloco para o Ingress.
* **Pré-condições**: Cluster Besu em modo `blockheader`; pilha implantada.
* **Procedimento**: Remove um validador no contrato antes da transição, aplica a transição no `genesis.json`, reinicia os nós e observa a produção de blocos.
* **Critérios de Aceite**: Consenso pré-transição ignora alterações no contrato; pós-transição, o nó removido cessa a proposição de blocos no consenso mesmo com o contêiner ativo; retorno do nó à produção de blocos após a reinclusão no contrato.

#### `11-inatividade-real-no-consenso`
* **Escopo**: Ciclo completo de remoção e reinclusão por inatividade com a rede operando no modo `contract`.
* **Pré-condições**: Cluster Besu em modo `blockheader`; pilha implantada; *enode* do `besu-node5` cadastrado na organização 2.
* **Procedimento**: Aplica a transição de gênesis, para o contêiner do nó 5, executa a seleção automática, religa o contêiner, solicita reinclusão por *enode* pelo administrador da organização e executa ciclos subsequentes.
* **Critérios de Aceite**: Nó removido no consenso Besu pós-seleção; nó permanece fora do consenso após o religamento até o envio da transação de reinclusão por *enode*; nó reincluído sobrevive a ciclos subsequentes sem a proteção inicial.

## 7. Variáveis de Ambiente

Parâmetros de execução dos scripts de teste:

| Variável | Valor Padrão | Descrição |
| --- | --- | --- |
| `E2E_RPC` | `http://localhost:8545` | Endpoint JSON-RPC do nó de referência (`besu-node0`). |
| `E2E_FRESH_NET` | `0` | Se igual a `1`, força a recriação da rede Docker (equivalente a `--fresh`). |
| `E2E_BLOCKS_BETWEEN_SELECTION` | `30` | Intervalo em blocos entre seleções automáticas (`> E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD`). |
| `E2E_BLOCKS_WITHOUT_PROPOSE_THRESHOLD` | `18` | Limite de blocos inativos tolerados (deve ser maior que a janela *round-robin* de 6 blocos). |
| `E2E_SELECTION_OFFSET` | `30` | Deslocamento inicial de blocos para agendamento da primeira seleção. |
