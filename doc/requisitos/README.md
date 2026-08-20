# Sistema de Seleção de Validadores *on-chain*

Este documento descreve o escopo funcional e a organização das histórias de usuário do Sistema de Seleção de Validadores *on-chain* da RBB. 

A solução é projetada como um sistema único a nível de negócio, estruturado em dois componentes para garantir a flexibilidade técnica e a governança operacional da rede:

1. **Acesso e Roteamento (Ingress)**: Funciona como ponto de acesso fixo para o cliente Besu, delegando as chamadas de consenso e permitindo a evolução da lógica sem necessidade de *hard forks* na rede. Suas histórias de usuário detalhadas estão descritas em [02-ingress-selecao-validadores.md](02-ingress-selecao-validadores.md).
2. **Mecanismo e Lógica de Seleção (Lógica)**: Contrato inteligente responsável por gerenciar as regras de elegibilidade, o monitoramento de desempenho e o consenso dos nós validadores. Suas histórias de usuário detalhadas estão descritas em [01-selecao-validadores.md](01-selecao-validadores.md).

---

## Visão Geral do Escopo

O escopo do sistema de seleção de validadores é organizado em 5 épicos de negócio, abrangendo as interações de governança, monitoramento automático de integridade do consenso e acesso do cliente Besu QBFT:

| Épico | Objetivo | Histórias (Lógica) | Histórias (Ingress) |
| :--- | :--- | :--- | :--- |
| **1. Implantação e migração para seleção on-chain** | Realizar a transição do consenso baseado em *block header* para a seleção via *smart contracts*, implantando e inicializando os componentes. | - [US1-1: Implantar código de seleção de validadores](01-selecao-validadores.md#us1-1)<br>- [US1-3: Configurar Besu para seleção via smart contract](01-selecao-validadores.md#us1-3) | - [US1-2: Implantar código do Ingress](02-ingress-selecao-validadores.md#us1-2) |
| **2. Consulta dos conjuntos de validadores** | Disponibilizar transparência, auditoria de configurações e informações sobre os conjuntos de validadores na rede. | - [US2-1: Consultar validadores operacionais](01-selecao-validadores.md#us2-1)<br>- [US2-2: Consultar validadores elegíveis](01-selecao-validadores.md#us2-2) | - [US2-3: Redirecionar consulta pelo Besu](02-ingress-selecao-validadores.md#us2-3)<br>- [US2-4: Consultar endereços no Ingress](02-ingress-selecao-validadores.md#us2-4) |
| **3. Operação automática da seleção de validadores** | Controlar a execução automática da monitorização de desempenho e reajustes automáticos de consenso. | - [US3-1: Alterar modo de operação da seleção](01-selecao-validadores.md#us3-1)<br>- [US3-2: Configurar parâmetros de seleção automática](01-selecao-validadores.md#us3-2)<br>- [US3-3: Executar monitoração automática de validadores](01-selecao-validadores.md#us3-3) | *N/A (Lógica sob responsabilidade do contrato de seleção)* |
| **4. Administração manual de validadores** | Permitir a intervenção manual de administradores e da governança na composição dos conjuntos de validadores. | - [US4-1: Adicionar validador elegível como operacional](01-selecao-validadores.md#us4-1)<br>- [US4-2: Remover validador operacional](01-selecao-validadores.md#us4-2)<br>- [US4-3: Adicionar validador elegível](01-selecao-validadores.md#us4-3)<br>- [US4-4: Remover validador elegível](01-selecao-validadores.md#us4-4) | *N/A (Lógica sob responsabilidade do contrato de seleção)* |
| **5. Governança e evolução do contrato** | Administrar a atualização dos contratos inteligentes, garantindo compatibilidade técnica e conformidade. | - [US5-1: Atualizar o código de seleção](01-selecao-validadores.md#us5-1)<br>- [US5-2: Consultar compatibilidade de interface](01-selecao-validadores.md#us5-2) | - [US5-3: Atualizar endereço do contrato de seleção](02-ingress-selecao-validadores.md#us5-3)<br>- [US5-4: Remover endereço do contrato de seleção](02-ingress-selecao-validadores.md#us5-4)<br>- [US5-5: Atualizar endereço do contrato de Admin](02-ingress-selecao-validadores.md#us5-5)<br>- [US5-6: Remover endereço do contrato de Admin](02-ingress-selecao-validadores.md#us5-6) |

---

## Detalhamento dos Épicos

### Épico 1: Implantação e migração para seleção on-chain

**Objetivo:** Realizar a transição completa da seleção de validadores via *block header* para *smart contracts*, configurando a infraestrutura inicial do Ingress e do contrato de Lógica de seleção de validadores na rede Besu.

* **Histórias de Lógica de Seleção:**
  * **[US1-1 (01-selecao-validadores.md)](01-selecao-validadores.md#us1-1):** Implantar código de seleção de validadores. Define parâmetros de monitoramento (`blocksBetweenSelection`, `blocksWithoutProposeThreshold`) e listas iniciais de validadores.
  * **[US1-3 (01-selecao-validadores.md)](01-selecao-validadores.md#us1-3):** Configurar a rede Besu para utilização da seleção de validadores via *smart contract*. Configuração no arquivo gênesis da rede Besu QBFT.
* **Histórias de Ingress:**
  * **[US1-2 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us1-2):** Implantar código do Ingress da seleção de validadores. Configuração do Ingress como fachada, apontando para o contrato de lógica e o contrato de Admin.

---

### Épico 2: Consulta dos conjuntos de validadores

**Objetivo:** Disponibilizar transparência, auditabilidade e permitir a integração direta do cliente Besu para obter o conjunto de validadores operacionais e elegíveis e os endereços de governança configurados.

* **Histórias de Lógica de Seleção:**
  * **[US2-1 (01-selecao-validadores.md)](01-selecao-validadores.md#us2-1):** Consultar validadores operacionais. Retorna os validadores participando ativamente do consenso.
  * **[US2-2 (01-selecao-validadores.md)](01-selecao-validadores.md#us2-2):** Consultar validadores elegíveis. Retorna os nós credenciados pela governança.
* **Histórias de Ingress:**
  * **[US2-3 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us2-3):** Redirecionar consulta de validadores operacionais pelo Besu. O Ingress recebe a requisição do Besu e repassa a chamada ao contrato de seleção de validadores.
  * **[US2-4 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us2-4):** Consultar endereços registrados no Ingress. Permite verificar quais endereços do contrato de seleção de validadores e do Admin Proxy estão configurados no Ingress.

---

### Épico 3: Operação automática da seleção de validadores

**Objetivo:** Controlar e monitorar o funcionamento automático do consenso da rede por meio de algoritmos de avaliação contínua de desempenho.

* **Histórias de Lógica de Seleção:**
  * **[US3-1 (01-selecao-validadores.md)](01-selecao-validadores.md#us3-1):** Alterar modo de operação da seleção. Permite transitar o contrato de seleção entre os modos Manual e Automático.
  * **[US3-2 (01-selecao-validadores.md)](01-selecao-validadores.md#us3-2):** Configurar parâmetros de seleção automática de validadores. Permite reconfigurar os limites do ciclo de monitoração.
  * **[US3-3 (01-selecao-validadores.md)](01-selecao-validadores.md#us3-3):** Executar monitoração automática de validadores. Aciona a avaliação e a remoção automática de nós inoperantes (com verificação de limite de segurança mínimo de 4 nós operacionais).
* **Histórias de Ingress:**
  * *N/A — Toda a lógica de monitoramento automático reside e é executada no contrato de seleção de validadores.*

---

### Épico 4: Administração manual de validadores

**Objetivo:** Permitir intervenções pontuais humanas e da governança na composição dos conjuntos de validadores cadastrados na rede.

* **Histórias de Lógica de Seleção:**
  * **[US4-1 (01-selecao-validadores.md)](01-selecao-validadores.md#us4-1):** Adicionar validador elegível como validador operacional. Ação manual de estabelecimento de nós operacionais.
  * **[US4-2 (01-selecao-validadores.md)](01-selecao-validadores.md#us4-2):** Remover validador operacional. Permite desligamento imediato para manutenção planejada.
  * **[US4-3 (01-selecao-validadores.md)](01-selecao-validadores.md#us4-3):** Adicionar validador elegível. Permite a inclusão de novos nós na lista de credenciados pela governança.
  * **[US4-4 (01-selecao-validadores.md)](01-selecao-validadores.md#us4-4):** Remover validador elegível. Exclusão definitiva de um nó da elegibilidade de consenso.
* **Histórias de Ingress:**
  * *N/A — O gerenciamento e a administração manual de validadores são operados no contrato de seleção de validadores.*

---

### Épico 5: Governança e evolução do contrato

**Objetivo:** Administrar o ciclo de vida técnico e o reponteiramento dos contratos de seleção e de governança na rede sem interrupção de serviço ou necessidade de hard-fork.

* **Histórias de Lógica de Seleção:**
  * **[US5-1 (01-selecao-validadores.md)](01-selecao-validadores.md#us5-1):** Atualizar o código de seleção de validadores.
  * **[US5-2 (01-selecao-validadores.md)](01-selecao-validadores.md#us5-2):** Consultar se o contrato de seleção de validadores implementa uma interface especificada (suporte a ERC-165).
* **Histórias de Ingress:**
  * **[US5-3 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us5-3):** Atualizar o endereço do contrato de seleção de validadores no Ingress. Permite reponteirar a fachada para uma nova versão de lógica.
  * **[US5-4 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us5-4):** Remover o endereço do contrato de seleção de validadores no Ingress.
  * **[US5-5 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us5-5):** Atualizar o endereço do contrato de Admin no Ingress.
  * **[US5-6 (02-ingress-selecao-validadores.md)](02-ingress-selecao-validadores.md#us5-6):** Remover o endereço do contrato de Admin no Ingress.
