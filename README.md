# Seleção de Validadores - Rede Blockchain Brasil (RBB)

Este repositório contém artefatos de código para implementação de mecanismo de **"seleção de validadores"**, responsável pelo gerenciamento dinâmico, monitoramento de disponibilidade (liveness) e rotação automática de validadores na Rede Blockchain Brasil (RBB). Tal mecanismo foi projetado de forma a possibilitar a manutenção de níveis de serviço (SLA) dentro de certos parâmetros desejados para a operação da rede.

O mecanismo consiste em duas partes:
1. *Smart contract* responsável por determinar quais nós podem e quais nós efetivamente devem fazer parte do consenso da rede, de acordo com regras e critérios pré-estabelecidos.
2. Aplicação de monitoração, executada pelos partícipes da rede, que acionam, de forma periódica, o *smart contract* mencionado.

De maneira geral, o funcionamento ocorre da seguinte maneira:
1. Cada partícipe executa a aplicação de monitoração.
2. Periodicamente, cada instância da aplicação de monitoração, em cada partícipe, envia transações ao *smart contract* de seleção de validadores.
3. Ao receber as transações, o *smart contract* "contabiliza" a produção de blocos de cada nó validador, avaliando se algum nó está inoperante (sem produzir blocos), de acordo com certos critérios e parâmetros.
   1. A depender do comportamento detectado, o *smart contract* pode remover, automaticamente, validadores do consenso.

Desta forma, nós validadores "improdutivos" são rapidamente removidos do consenso, evitando falhas nos *rounds* de consenso e estabilizando o tempo de produção de blocos próximo de seu valor nominal.

Os partícipes que tiverem seus validadores removidos automaticamente, podem, através de uma simples operação no *smart contract*, solicitar a re-inclusão de seus nós assim que tiverem investigado, diagnosticado e resolvido os problemas de operação, voltando a resiliência da rede ao seu patamar esperado.

**Observação**: Para que esse mecanismo de seleção funcione, é necessário que a [rede (Besu) seja configurada](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) para [seleção de validadores por *smart contract*](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators-using-a-smart-contract), ao invés da [seleção por cabeçalho de bloco (*block header*)](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators-using-block-headers) padrão.
## Implantação e transição do genesis (US1-1, US1-2 e US1-3)

A implantação do mecanismo segue uma sequência obrigatória, pois o construtor do
`ValidatorSelectionIngress` valida que a lógica registrada retorna ao menos 1 validador
operacional (`getValidators().length >= 1`):

1. **Implantar a Lógica** (`ValidatorSelection`, US1-1): `forge script script/Deploy.s.sol`
   com os parâmetros em `script/data/config.json`. O contrato inicia em modo Manual e
   apenas com o conjunto de validadores elegíveis populado.
2. **Ativar os validadores operacionais** (US4-1): a governança adiciona os validadores
   iniciais ao conjunto operacional (`addOperationalValidatorByAddress`/`addOperationalValidator`).
3. **Implantar o Ingress** (`ValidatorSelectionIngress`, US1-2): preencher
   `contracts.validatorSelection` em `script/data/config.json` com o endereço da Lógica e
   executar `forge script script/DeployIngress.s.sol`. O endereço do Ingress é fixo e
   será o ponto de acesso permanente do Besu (DA-01).
4. **Aplicar a transição no genesis** (US1-3): adicionar a transição QBFT no arquivo
   genesis de **todos os nós da rede**, apontando para o endereço do Ingress — ver o
   modelo em `script/data/genesis-transition.example.json` e a
   [documentação do Besu](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods).
   A partir do bloco da transição, o Besu passa a consultar `getValidators()` no Ingress
   e o mecanismo anterior por *block header* deixa de ser utilizado.

Os critérios de aceite da US1-3 (uso efetivo do contrato pelo consenso) são verificados
na rede Besu após a aplicação da transição, fora do escopo deste repositório.
