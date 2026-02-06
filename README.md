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