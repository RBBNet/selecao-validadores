# Histórias de Usuário — Lógica de Seleção de Validadores *on-chain*

## Sumário

1. [Introdução](#introducao)
2. [Visão Geral do Escopo](#visao-geral)
3. [Detalhamento](#detalhamento)
   - [Épico 1: Implantação e migração para seleção on-chain](#epico-1)
     - [US1-1: Implantar código de seleção de validadores](#us1-1)
     - [US1-3: Configurar a rede Besu para utilização da seleção de validadores via smart contract](#us1-3)
   - [Épico 2: Consulta dos conjuntos de validadores](#epico-2)
     - [US2-1: Consultar validadores operacionais](#us2-1)
     - [US2-2: Consultar validadores elegíveis](#us2-2)
   - [Épico 3: Operação automática da seleção de validadores](#epico-3)
     - [US3-1: Alterar modo de operação da seleção](#us3-1)
     - [US3-2: Configurar parâmetros de seleção automática de validadores](#us3-2)
     - [US3-3: Executar monitoração automática de validadores](#us3-3)
   - [Épico 4: Administração manual de validadores](#epico-4)
     - [US4-1: Adicionar validador elegível como validador operacional](#us4-1)
     - [US4-2: Remover validador operacional](#us4-2)
     - [US4-3: Adicionar validador elegível](#us4-3)
     - [US4-4: Remover validador elegível](#us4-4)
   - [Épico 5: Governança e evolução do contrato](#epico-5)
     - [US5-1: Atualizar o código de seleção de validadores](#us5-1)
     - [US5-2: Consultar se o contrato de seleção de validadores implementa uma interface especificada](#us5-2)
     - [US5-7: Atualizar o endereço do contrato de Admin na Lógica](#us5-7)
     - [US5-8: Atualizar o endereço do contrato de Regras de Contas na Lógica](#us5-8)
     - [US5-9: Atualizar o endereço do contrato de Regras de Nós na Lógica](#us5-9)

---

## 1. Introdução <a id="introducao"></a>

**Data da liberação do documento:** 22/05/2026

**Objetivo:**

Este documento detalha as histórias de usuário e regras de negócio para a Lógica de Seleção de Validadores *on-chain* da RBB, cobrindo o gerenciamento de estados, regras de transição de conjuntos de validadores e os fluxos de monitoramento automático e manual do consenso.

---

## 2. Visão Geral do Escopo <a id="visao-geral"></a>

| Épico | Objetivo | Histórias |
| :--- | :--- | :--- |
| **1. Implantação e migração para seleção on-chain** | Realizar a transição da seleção via *block header* para *smart contract* | - US1-1: Implantar código de seleção de validadores<br>- US1-3: Configurar Besu para utilização da seleção via *smart contract* |
| **2. Consulta dos conjuntos de validadores** | Disponibilizar transparência e auditabilidade dos conjuntos de validadores gerenciados pelo código *on-chain*. | - US2-1: Consultar validadores operacionais<br>- US2-2: Consultar validadores elegíveis |
| **3. Operação automática da seleção de validadores** | Controlar o funcionamento automático do consenso e da monitorização. | - US3-1: Alterar modo de operação da seleção<br>- US3-2: Configurar parâmetros de seleção automática de validadores<br>- US3-3: Executar monitoração automática de validadores |
| **4. Administração manual de validadores** | Permitir intervenção humana no conjunto de validadores | - US4-1: Adicionar validador elegível como validador operacional<br>- US4-2: Remover validador operacional<br>- US4-3: Adicionar validador elegível<br>- US4-4: Remover validador elegível |
| **5. Governança e evolução do contrato** | Administrar o ciclo de vida técnico do mecanismo *on-chain* | - US5-1: Atualizar o código de seleção de validadores<br>- US5-2: Consultar se o contrato de seleção de validadores implementa uma interface especificada<br>- US5-7: Atualizar o endereço do contrato de Admin na Lógica<br>- US5-8: Atualizar o endereço do contrato de Regras de Contas na Lógica<br>- US5-9: Atualizar o endereço do contrato de Regras de Nós na Lógica |

---

## 3. Detalhamento <a id="detalhamento"></a>

### Épico 1: Implantação e migração para seleção on-chain <a id="epico-1"></a>

**Objetivo:** Realizar a transição da seleção de validadores via *block header* para *smart contract*.

#### US1-1: Implantar código de seleção de validadores <a id="us1-1"></a>

##### 1. História do Usuário

**Como** Usuário da RBB  
**Quero** implantar o código de seleção de validadores  
**Para** permitir a transição da seleção de validadores da rede de *block header* para *smart contract*

##### 2. Pré-requisitos

* Os contratos de permissionamento (`AdminProxy`, `AccountRulesV2` e `NodeRulesV2`) já devem existir na rede.
* O código do *smart contract* de seleção de validadores já deve estar disponível para implantação.

##### 3. Descrição

3.1. O objetivo desta história é permitir a implantação e a inicialização do *smart contract* responsável pela seleção de validadores da RBB, preparando-o para substituir o mecanismo atual baseado em *block header*.

Durante a implantação, devem ser informados os endereços dos contratos de permissionamento utilizados pela solução. Em seguida, o *smart contract* deve ser inicializado com os parâmetros iniciais de funcionamento, o modo inicial de operação e os conjuntos iniciais de validadores.

Ao término desta história, o *smart contract* estará devidamente configurado e apto a ser utilizado pela rede.

3.2. Fluxo principal:

1. Devem ser informados ao sistema **obrigatoriamente**:
   - Os endereços dos contratos de permissionamento da RBB (`AdminProxy`, `AccountRulesV2` e `NodeRulesV2`).
   - A lista inicial de endereços dos nós validadores.
   - Os parâmetros iniciais de configuração:
     - `blocksBetweenSelection`
     - `blocksWithoutProposeThreshold`
2. O sistema deve validar:
   - Se os endereços dos contratos de permissionamento da RBB são válidos.
   - Se a lista inicial de endereços dos nós validadores está de acordo com a regra 4.7.
   - Se os parâmetros iniciais de configuração seguem as regras definidas in 4.6.
3. Se todas as validações forem atendidas, o *smart contract* deve ser inicializado com os seguintes parâmetros:
   - Modo de operação = manual.
   - Conjunto de validadores elegíveis = lista inicial de endereços dos nós validadores informada.
   - Conjunto de validadores operacionais = lista inicial de endereços dos nós validadores informada.
   - Conjunto de validadores protegidos = lista inicial de endereços dos nós validadores informada.
4. Caso qualquer uma das validações não seja atendida, a transação é revertida, retornando um erro de validação (endereço inválido) ao usuário.

##### 4. Regras de Negócio

4.1. Esta história será executada uma única vez.

4.2. O *smart contract* gerenciará 3 conjuntos de validadores:
* Elegíveis ao consenso (definidos pela governança)
* Operacionais (que efetivamente fazem parte do consenso e devem estar contidos nos elegíveis)
* Protegidos (temporariamente protegidos contra a remoção automática, incluindo recém-adicionados e operacionais após transição de modo ou atualização de parâmetros, e que devem estar contidos nos operacionais).

4.3. A qualquer momento, todos os validadores do conjunto de operacionais devem estar contidos também no conjunto de elegíveis.

4.4. A qualquer momento, todos os validadores do conjunto de protegidos devem estar contidos também no conjunto de operacionais.

4.5. A seleção de validadores terá dois modos de operação: Manual e Automatic.
* No momento da implantação do código, o modo de operação será ajustado para Manual. No modo Manual somente ocorrerão modificações nos conjuntos de validadores (operacionais, elegíveis e protegidos) através de ação humana.
* No modo Automatic o código poderá selecionar e decidir remover automaticamente validadores do conjunto de validadores operacionais.

4.6. Devem ser informados os parâmetros obrigatórios:
* `blocksBetweenSelection`: Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores.
  - Esse valor deve ser maior ou igual a 1.
* `blocksWithoutProposeThreshold`: Limite de blocos tolerado para que um validador permaneça sem propor blocos.
  - Acima desse limite o validador deverá ser pré-selecionado para remoção do conjunto de validadores operacionais.
  - Esse limite deve ser maior ou igual ao número de validadores elegíveis.

4.7. Deve ser informada **obrigatoriamente** uma lista inicial de endereços de nós validadores, garantindo que ao menos 1 endereço válido seja informado e que não existam endereços duplicados.

##### 5. Critérios de Aceite

5.1. A execução desta história deve ocorrer apenas uma única vez na rede.  
5.2. O sistema deve exigir a informação dos endereços dos contratos `AdminProxy`, `AccountRulesV2` e `NodeRulesV2`, validando que todos foram informados antes da conclusão da implantação.  
5.3. O sistema deve exigir e validar a inserção de uma lista inicial de endereços de nós validadores, garantindo que ao menos 1 nó válido seja fornecido.  
5.4. O sistema deve validar os parâmetros iniciais obrigatórios de entrada: `blocksBetweenSelection` e `blocksWithoutProposeThreshold`, conforme regra 4.6.  
5.5. Após a inicialização do contrato, todos os nós informados devem pertencer simultaneamente aos conjuntos de validadores elegíveis e operacionais.  
5.6. O conjunto de validadores protegidos deve ser inicializado contendo a lista inicial de validadores.  
5.7. O modo inicial de operação do contrato deve ser configurado como “manual” após a implantação.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Deveríamos colocar critérios adicionais para validar o conjunto de validadores, como, por exemplo, verificar que estão devidamente permissionados, que estão ativos, que há apenas 1 por organização, etc? | Seriam implementações possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos. |
| **2** | Ao invés de utilizar 2 parâmetros - `blocksBetweenSelection` e `blocksWithoutProposeThreshold` - seria o caso de utilizar apenas um para controlar o ciclo de monitoração? Com 2 parâmetros o algoritmo, apesar de mais flexível e responsivo (quedas que ultrapassem o ciclo), não fica mais complexo? | Avaliou-se que a implementação com 2 parâmetros não fica muito mais complexa, podendo-se manter as vantagens desejadas. Caso quaisquer problemas de implementação sejam detectados na operação da monitoração durante a implementação e testes do *smart contract*, essa decisão poderá ser revista. |

---

#### US1-3: Configurar a rede Besu para utilização da seleção de validadores via smart contract <a id="us1-3"></a>

##### 1. História do Usuário

**Como** Administrador da RBB  
**Quero** que a rede Besu passe a utilizar o mecanismo de seleção de validadores baseado em *smart contract*  
**Para** que o consenso da rede utilize o código *on-chain* implantado, em substituição ao mecanismo atualmente utilizado.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é configurar a rede Besu por meio da aplicação de uma transição no arquivo gênesis, para que o mecanismo de seleção de validadores passe a utilizar o *smart contract* previamente implantado, substituindo definitivamente o modelo anteriormente utilizado.

##### 4. Regras de Negócio

4.1. Deve existir uma transição no arquivo gênesis da rede Besu que altere o mecanismo de seleção de validadores ([transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods)).  
4.2. Após a transição, a seleção de validadores deve ser realizada pelo *smart contract* previamente implantado.

##### 5. Critérios de Aceite

5.1. Após a aplicação da transição no arquivo gênesis, a rede Besu deve utilizar o *smart contract* de seleção de validadores para determinar os validadores responsáveis pela produção de blocos.  
5.2. Após a aplicação da transição no arquivo gênesis, o mecanismo anterior de seleção por *block header* não deve mais ser utilizado.

---

### Épico 2: Consulta dos conjuntos de validadores <a id="epico-2"></a>

**Objetivo:** Disponibilizar transparência e auditabilidade dos conjuntos de validadores gerenciados pelo código *on-chain*.

#### US2-1: Consultar validadores operacionais <a id="us2-1"></a>

##### 1. História do Usuário

**Como** Qualquer conta da rede ou Besu  
**Quero** consultar o conjunto de validadores operacionais  
**Para** obter os validadores utilizados pelo algoritmo de consenso da RBB

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir que o cliente Besu ou qualquer observador externo consulte, em tempo real, o conjunto de validadores operacionais gerenciado pelo *smart contract* de seleção de validadores, identificando quais validadores participam ativamente do algoritmo de consenso da RBB.

##### 4. Regras de Negócio

4.1. Qualquer conta da rede ou o Besu tem permissão para consultar o conjunto de validadores operacionais.

##### 5. Critérios de Aceite

5.1. Qualquer conta da rede ou o cliente Besu deve possuir permissão para invocar a função de consulta.  
5.2. A chamada à função deve retornar com sucesso uma lista contendo a totalidade dos endereços dos nós registrados no conjunto de validadores operacionais no momento.

---

#### US2-2: Consultar validadores elegíveis <a id="us2-2"></a>

##### 1. História do Usuário

**Como** Qualquer conta da rede  
**Quero** consultar o conjunto de validadores elegíveis  
**Para** identificar os validadores aptos a participar do consenso da RBB

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir a consulta pública del conjunto de validadores elegíveis gerenciado pelo *smart contract* de seleção de validadores, proporcionando transparência sobre quais nós estão autorizados pela governança a participar do consenso da RBB.

##### 4. Regras de Negócio

4.1. Qualquer conta da rede possui permissão para consultar o conjunto de validadores elegíveis.

##### 5. Critérios de Aceite

5.1. Qualquer conta presente na rede deve possuir permissão para consultar o conjunto de nós elegíveis.  
5.2. A execução bem-sucedida da consulta deve retornar de forma clara a listagem completa do conjunto de validadores elegíveis.

---

### Épico 3: Operação automática da seleção de validadores <a id="epico-3"></a>

**Objetivo:** Controlar o funcionamento automático do consenso e da monitorização.

#### US3-1: Alterar modo de operação da seleção <a id="us3-1"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** alterar o modo de operação da seleção de validadores  
**Para** definir se a seleção de validadores ocorrerá de forma manual ou automática

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é fornecer à governança da RBB a capacidade regulatória de alterar o estado operacional do contrato do modo Manual para o Automático e vice-versa.  
O contrato é inicializado em modo manual durante a implantação (ver US1-1), podendo posteriormente ser alterado por esta história.

3.2. Fluxo principal:

1. Deve ser informado ao sistema o modo de operação desejado:
   - Manual ou Automatic
2. O sistema deve validar:
   - Se o usuário pode executar a alteração do modo de operação da seleção.
   - Se o modo de operação informado é “Manual” ou “Automatic”.
3. Si a validação for atendida, o sistema deve executar a alteração do modo de operação conforme as regras 4.2 e 4.3.
4. Caso qualquer validação não seja atendida, a operação deve ser revertida:
   - Indicando erro de permissão de acesso, caso executada por usuário diferente da Governança.
   - Indicando erro de modo de operação inválido, caso o modo de operação enviado seja diferente de “Manual” ou “Automatic”.

##### 4. Regras de Negócio

4.1. Apenas a governança possui autorização para realizar a mudança de modo.

4.2. Se o modo selecionado for Manual:
* O modo de operação deve ser alterado para “Manual”.
* As modificações nos conjuntos passam a ser regidas estritamente pela Governança.

4.3. Se o modo selecionado for Automatic:
* O estado do contrato passa a ser Automatic.
* O conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos.
* As informações de produção de blocos pelos validadores devem ser inicializadas.
* Um novo ciclo de monitoração automática deve ser iniciado.

##### 5. Critérios de Aceite

5.1. Apenas a Governança da rede possui autorização legítima para efetuar a mudança de modo.  
5.2. Caso o modo seja alterado para "Automatic", o sistema deve obrigatoriamente popular o conjunto de validadores protegidos com todos os validadores operacionais ativos, inicializar os dados de produção de blocos e iniciar um novo ciclo de monitoração.  
5.3. Caso o modo selecionado for “Manual”, o sistema deve atualizar seu estado para “Manual”, mantendo futuras alterações dos conjuntos exclusivamente por ações manuais.  
5.4. Ao finalizar a transição de estado, o contrato deve emitir um evento registrando de forma explícita o modo de operação selecionado.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Devemos manter a semântica de dois modos ou devemos apenas indicar quando a seleção automática estiver ligada ou desligada? Afinal, mesmo no modo automático as ações manuais podem ser realizadas. | Avaliou-se que, do ponto de vista de implementação, há pouca diferença entre usar "uma variável de estado" ou "uma flag de funcionalidade". Por outro lado, a semântica de "estado de operação" pareceu ser apropriada para representar o funcionamento do *smart contract* e, portanto, foi mantida. |

---

#### US3-2: Configurar parâmetros de seleção automática de validadores <a id="us3-2"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** configurar os parâmetros de seleção automática de validadores  
**Para** ajustar as regras do ciclo de monitoração e seleção de validadores

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir que os parâmetros da seleção automática de validadores sejam configurados e refinados pela governança para ajustar as regras do ciclo de monitoração e seleção.

3.2. Fluxo principal:

1. Devem ser informados ao sistema **obrigatoriamente**:
   - `blocksBetweenSelection`: Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores.
   - `blocksWithoutProposeThreshold`: Limite de blocos tolerado para que um validador permaneça sem propor blocos.
2. O sistema deve validar:
   - Se `blocksBetweenSelection` é >= 1.
   - Se `blocksWithoutProposeThreshold` é >= ao número de validadores elegíveis.
3. Se todas as validações forem atendidas, o sistema deve atualizar os parâmetros e executar as ações previstas nas regras 4.3 e 4.4.
4. Caso qualquer validação não seja atendida: ver item 3.3.

3.3. Cenários de exceção e erro:

1. Parâmetro `blocksBetweenSelection` inválido:
   - Reverter a operação.
   - Retornar um erro para o contexto de `blocksBetweenSelection` inválido.
2. Parâmetro `blocksWithoutProposeThreshold` inválido:
   - Reverter a operação.
   - Retornar um erro para o contexto de `blocksWithoutProposeThreshold` inválido.

##### 4. Regras de Negócio

4.1. Apenas a governança pode realizar esta configuração.

4.2. Regra de Estouro do Limite: Acima do limite definido em `blocksWithoutProposeThreshold`, o validador deverá ser pré-selecionado para remoção do conjunto de validadores operacionais.

4.3. Ao aplicar a nova configuração dos parâmetros, o conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos.

4.4. Ao aplicar a nova configuração, as informações de produção de blocos pelos validadores devem ser inicializadas e um novo ciclo de monitoração automática deve ser iniciado.

##### 5. Critérios de Aceite

5.1. A execução deste ajuste deve ser exclusiva da governança.  
5.2. O sistema deve validar e exigir a inserção simultânea e obrigatória de ambos os parâmetros.  
5.3. A transação deve ser rejeitada e revertida caso o parâmetro `blocksBetweenSelection` seja menor que 1.  
5.4. A transação deve ser rejeitada caso o limite definido em `blocksWithoutProposeThreshold` seja menor que o número atual de validadores elegíveis cadastrados.  
5.5. Ao salvar com sucesso as novas configurações, o conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos, os históricos de blocos devem ser reiniciados e um novo ciclo deve ser aberto.  
5.6. O contrato deve emitir um evento registrando os novos valores configurados para ambos os parâmetros.

---

#### US3-3: Executar monitoração automática de validadores <a id="us3-3"></a>

##### 1. História do Usuário

**Como** Qualquer conta da rede  
**Quero** acionar a execução da monitoração automática de validadores,  
**Para** garantir a manutenção automática do conjunto de validadores operacionais por meio da verificação de desempenho na produção de blocos

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.
* US3-1: Alterar modo de operação da seleção.
* US3-2: Configurar parâmetros de seleção automática de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é acionar a lógica interna do *smart contract* para avaliar individualmente o desempenho dos nós na produção de blocos atuais e remover de forma automatizada aqueles que forem detectados como inoperantes.

##### 4. Regras de Negócio

4.1. A monitoração automática deve respeitar as regras de consistência entre os conjuntos de validadores (elegíveis, operacionais e protegidos) definidas na US1-1.

4.2. Qualquer conta pode acionar a monitoração.

4.3. Elegibilidade da monitoração: a lógica de monitoração automática só deve prosseguir se o modo de operação estiver definido como Automatic e se a monitoração ainda não tiver sido executada para o bloco atual. Caso contrário, a monitoração é encerrada imediatamente.

4.4. Ao passar na elegibilidade da execução, o sistema deve:
* Registrar o processamento da monitoração para o bloco atual.
* Contabilizar o bloco atual na métrica de desempenho do validador que o produziu.

4.5. A avaliação do conjunto de validadores só deve acontecer se o bloco atual corresponder ao intervalo de blocos definido no parâmetro `blocksBetweenSelection`. Caso não seja o momento do ciclo, a monitoração é encerrada.

4.6. No momento da seleção, o sistema deve avaliar individualmente cada validador operacional. Se um validador estiver há mais blocos sem propor bloco do que o limite estipulado em `blocksWithoutProposeThreshold`, ele deve ser pré-selecionado para remoção do consenso.

4.7. Para cada validador pré-selecionado para remoção, o sistema deve verificar se ele está contido no conjunto de validadores protegidos:
* Caso afirmativo: O validador é protegido e mantido no conjunto de validadores operacionais.

4.8. Caso o validador pré-selecionado não pertença ao conjunto de protegidos, a exclusão dependerá da quantidade mínima de segurança da rede:
* Remoção Autorizada: Se ao menos 4 validadores operacionais permanecerem ativos na rede após a exclusão do nó avaliado, o sistema deve:
  - Emitir um evento indicando o validador operacional que está sendo removido.
  - Remover o validador do conjunto de validadores operacionais, mantendo-o apenas como validador elegível.
* Remoção Vetada: Se a exclusão deixar a rede com menos de 4 validadores operacionais, o nó inoperante deve ser mantido como validador operacional para proteger o consenso.

4.9. Após processar as avaliações e remoções do período, o sistema deve obrigatoriamente resetar o estado realizando os seguintes passos:
* Esvaziar completamente o conjunto de validadores protegidos.
* Inicializar (zerar) as informações acumuladas de produção de blocos de todos os validadores.
* Iniciar um novo ciclo de monitoração automática.
* Emitir um evento final indicando a realização da seleção automática de validadores, informando detalhadamente a listagem de validadores operacionais resultante.

##### 5. Critérios de Aceite

5.1. A função deve aceitar chamadas de qualquer conta da rede, mas a lógica só prossegue se o modo estiver definido como "Automatic" e se o bloco atual ainda não tiver sido processado. Caso contrário, encerra imediatamente.  
5.2. A execução deve emitir um evento registrando seu acionamento a cada chamada.  
5.3. Quando a monitoração prosseguir após a validação de elegibilidade, o sistema deve registrar que o bloco atual foi processado para monitoração e contabilizar a produção do bloco para o respectivo validador.  
5.4. A avaliação detalhada e seleção só ocorrerão se o bloco atual atingir o intervalo parametrizado em `blocksBetweenSelection`.  
5.5. Nós operacionais que excederem o limite sem propor blocos (`blocksWithoutProposeThreshold`) devem ser pré-selecionados para remoção, exceto se constarem no conjunto de "protegidos" (que possuem imunidade no ciclo corrente).  
5.6. Caso ocorra a remoção de um nó (removendo-o do conjunto de validadores operacionais), o sistema deve validar se restam ao menos 4 nós operacionais ativos. Se restar menos que 4, a exclusão é vetada por segurança. Em caso de exclusão efetivada, um evento específico identificando o validador removido deve ser disparado.  
5.7. Ao fechar a avaliação do ciclo, o sistema deve executar as ações definidas em 4.9.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Vamos deixar a função de monitoração "aberta" para qualquer conta executar? Valeria restringir o acesso para evitar possíveis ataques de DOS? | A princípio esse ataque (gasto excessivo de *gas*) estará presente também através da chamada a outros contratos. Logo, não parece valer a pena implementar controle específico para esse caso. |
| **2** | No evento de seleção de validadores, seria interessante acrescentar alguma informação, como o conjunto de validadores selecionados ou ao menos a quantidade de validadores selecionados? | A princípio, para fins de transparência e auditabilidade, sim. Caso se verifique que isso acarreta em alto consumo de *gas* isso poderá ser revisto. |
| **3** | Deve-se remover somente 1 validador a cada seleção? Isso dá mais chance de validadores eventualmente se recuperarem. Por outro lado, torna mais lenta a convergência da rede para seu valor nominal de 4s para produção de blocos. | Decidiu-se priorizar a convergência do consenso para o valor nominal de produção de blocos, removendo-se todos os validadores inoperantes possíveis de uma vez. |
| **4** | Como podemos proteger a seleção de validadores de falhas mais amplas do envio de transações de monitoração? Por exemplo, se todos os partícipes utilizarem uma mesma implementação para envio de transações de monitoração que se torne vulnerável a um ataque que a torne inoperante (*zero-day attack*) e algum partícipe, isoladamente, consiga corrigir a vulnerabilidade reabilitando a monitoração de forma pontual, distorcendo os dados de monitoração e levando a seleção à remoção equivocada de validadores em massa. | Apesar de possível, o cenário de falha "catastrófica" da monitoração foi avaliado como pouco provável. Chegou-se a avaliar a implementação de mecanismo que quantificasse a quantidade de blocos monitorados, de forma que a seleção automática só ocorresse caso uma quantidade mínima de blocos tenha sido monitorado. Porém, verificou-se que tal implementação levaria a dilema adicional: o mecanismo teria que optar entre proteger a rede de excluir equivocadamente validadores funcionais ou de impedir a exclusão de validadores inoperantes. Dada a avaliação de baixa probabilidade de ocorrência de falha generalizada, do aumento de complexidade de implementação e da salva-guarda de que, mesmo em caso de falha generalizada, no pior caso, a rede se manter funcionando com 4 validadores, optou-se por não implementar mecanismos de proteção contra falhas de monitoração. |
| **5** | O evento de monitoração deve ser emitido para todas as transações ou somente no caso de ser a primeira transação de monitoração do bloco? Afinal, o registro de um evento facilitaria a auditoria (para fins de OLA), porém causaria um gasto de *gas* adicional e a auditoria poderia ser feita de outras formas. | De forma conceitual, a emissão do evento para toda transação parece mais adequado. Portanto, essa será a definição inicial de requisito, sendo cabíveis eventuais reavaliações no caso de testes (em tempo de desenvolvimento) comprovarem que o gasto de *gas* atinja níveis indesejados. |

### Épico 4: Administração manual de validadores <a id="epico-4"></a>

**Objetivo:** Permitir gerenciamento humano no conjunto de validadores.

#### US4-1: Adicionar validador elegível como validador operacional <a id="us4-1"></a>

##### 1. História do Usuário

**Como** Administrador ou Governança da RBB  
**Quero** adicionar um validador elegível ao conjunto de validadores operacionais via seu endereço ou via sua chave pública (enodeHigh e enodeLow)  
**Para** restabelecer manualmente a participação ativa de um nó no algoritmo de consenso da rede

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir que um administrador autorizado ou a governança insira manualmente um nó elegível de volta no consenso operacional, restabelecendo imediatamente a sua participação ativa na rede. Esta operação deve poder ser realizada informando diretamente o endereço do validador ou, alternativamente, informando a sua chave pública (representada por `enodeHigh` e `enodeLow`).

3.2. Fluxo principal:

1. Deve ser informado ao sistema **obrigatoriamente**:
   - O endereço do nó validador (`validator`) ou, alternativamente, as duas partes de sua chave pública (`enodeHigh` e `enodeLow`) que permitam derivar o seu endereço.
2. O sistema deve validar:
   - Se o endereço informado ou o endereço derivado a partir de `enodeHigh` e `enodeLow` (obtido a partir dos 20 bytes menos significativos do hash `keccak256` das partes do enode concatenadas) é válido.
3. Se todas as validações forem atendidas:
   - O sistema deve realizar a adição do validador.
4. Caso qualquer uma das validações não seja atendida, a operação é revertida, retornando erro correspondente.

##### 4. Regras de Negócio

4.1. A execução desta história deve garantir as regras de consistência entre os conjuntos de validadores definidas na US1-1.

4.2. A ação é restrita a Administradores Globais ou Administradores Locais (desde que estejam ativos e vinculados a organizações ativas) ou à Governança.

4.3. Administradores de organizações possuem restrição de escopo: somente podem adicionar nós vinculados à sua própria organização.
- Quando executado por um Administrador, a operação deve ser realizada via enode (`enodeHigh` e `enodeLow`) para permitir a validação do vínculo do nó à organização no contrato de regras de nós.

4.4. A governança possui privilégios totais e pode adicionar nós de quaisquer organizações, podendo executar a operação tanto via endereço (`address`) quanto via enode (`enodeHigh` e `enodeLow`).

4.5. O nó informado não pode estar contido no grupo de validadores operacionais.

4.6. O nó informado deve pertencer ao grupo de validadores elegíveis.

4.7. O nó processado deve ser inserido no conjunto de validadores operacionais.

4.8. O nó processado deve ser inserido no conjunto de validadores protegidos.

4.9. Um evento deve ser emitido registrando o endereço do nó.

##### 5. Critérios de Aceite

5.1. A ação deve validar se o executor é um Administrador Global, um Administrador Local ativo (de organização ativa) ou a própria Governança. Administradores ficam restritos a nós da sua própria organização.  
5.2. O executor deve fornecer o endereço do nó validador desejado ou, alternativamente, os parâmetros `enodeHigh` e `enodeLow` correspondentes.  
5.3. O sistema deve validar se o endereço (informado ou derivado) pertence ao grupo de elegíveis e rejeitar a ação se ele já constar no grupo de operacionais.  
5.4. Ao concluir, o nó deve ser registrado no conjunto de operacionais e injetado no conjunto de protegidos (para proteção temporária contra o monitoramento autônomo).  
5.5. Após a conclusão da história, o nó deve permanecer pertencendo ao conjunto de validadores elegíveis e passar a integrar simultaneamente o conjunto de validadores operacionais.  
5.6. O contrato deve emitir um evento registrando com sucesso o endereço do nó adicionado.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Na emissão do evento, seria o caso de identificar a organização que efetuou a ação? | Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada. |
| **2** | Como garantir que um validador adicionado ao fim de um ciclo de monitoração automática não seja automaticamente removido por não ter tido tempo de produzir blocos? | Foi adotada a solução do conjunto de validadores protegidos. |
| **3** | Deveríamos colocar critérios adicionais para validar o endereço adicionado, como, por exemplo, verificar que está devidamente permissionado ou que está ativo? | Várias implementações seriam possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos. |

---

#### US4-2: Remover validador operacional <a id="us4-2"></a>

##### 1. História do Usuário

**Como** Administrador ou Governança da RBB  
**Quero** remover um validador do conjunto de validadores operacionais via seu endereço ou via sua chave pública (enodeHigh e enodeLow)  
**Para** interromper manualmente a participação ativa de um nó no algoritmo de consenso da rede.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir a remoção manual imediata de um validador do grupo de consenso para atender a necessidades e fins operacionais específicos, como manutenções programadas de infraestrutura. Esta operação deve poder ser realizada informando diretamente o endereço do validador ou, alternativamente, informando a sua chave pública (representada por `enodeHigh` e `enodeLow`).

3.2. Fluxo principal:

1. Deve ser informado ao sistema **obrigatoriamente**:
   - O endereço do nó validador (`validator`) ou, alternativamente, as duas partes de sua chave pública (`enodeHigh` e `enodeLow`) que permitam derivar o seu endereço.
2. O sistema deve validar:
   - Se o endereço informado ou o endereço derivado a partir de `enodeHigh` e `enodeLow` (obtido a partir dos 20 bytes menos significativos do hash `keccak256` das partes do enode concatenadas) é válido.
3. Se todas as validações forem atendidas:
   - O sistema deve realizar a remoção do validador.
4. Caso qualquer uma das validações não seja atendida, a operação deve reverter, retornando erro correspondente.

##### 4. Regras de Negócio

4.1. Somente Administradores Globais ou Locais ativos (de organizações ativas) ou da Governança podem executar essa ação.

4.2. Administradores somente podem remover nós vinculados às suas organizações.
- Quando executado por um Administrador, a operação deve ser realizada via enode (`enodeHigh` e `enodeLow`) para permitir a validação do vínculo do nó à organização no contrato de regras de nós.

4.3. A governança pode remover nós de quaisquer organizações, podendo executar a operação tanto via endereço (`address`) quanto via enode (`enodeHigh` e `enodeLow`).

4.4. O endereço do nó (informado ou derivado) deve estar no conjunto de validadores operacionais.

4.5. O nó somente será removido se ao menos N validadores permanecerem no conjunto de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.
* Para um Administrador, N = 4;
* Para a Governança, N = 1.

4.6. O nó é removido do conjunto de validadores operacionais.

4.7. O nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto.

4.8. Um evento deve ser emitido registrando o endereço do nó.

##### 5. Critérios de Aceite

5.1. A execução deve validar as permissões de Administradores Globais, Locais ativos ou Governança, respeitando os limites organizacionais de cada administrador.  
5.2. O executor deve fornecer o endereço do nó validador ou, alternativamente, os parâmetros `enodeHigh` e `enodeLow` correspondentes.  
5.3. O endereço fornecido ou derivado deve ser validado e obrigatoriamente pertencer ao conjunto operacional.  
5.4. A transação só pode ser concluída com sucesso se restarem no mínimo N nós validadores no conjunto operacional após a saída do nó em questão. Caso contrário, a história é interrompida com erro.  
* Se for executada por um Administrador, N = 4;  
* Se for executada pela Governança, N = 1.  
5.5. O nó deve ser removido do grupo operacional e também expurgado do conjunto de protegidos caso esteja lá.  
5.6. O contrato deve disparar um evento registrando o endereço do nó que foi desativado manualmente.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Faz sentido implementar função para remoção de validador operacional? | Sim. A função pode ser usada em casos como de manutenção programada, onde o nó já vai ficar indisponível e, ao invés de esperar remoção via monitoramento, é possível remover o nó imediatamente. |
| **2** | Na emissão do evento, seria o caso de identificar a organização que efetuou a ação? | Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada. |

---

#### US4-3: Adicionar validador elegível <a id="us4-3"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** adicionar um novo nó ao conjunto de validadores elegíveis via seu endereço ou via sua chave pública (enodeHigh e enodeLow)  
**Para** expandir o grupo de nós credenciados e aptos a compor o consenso da rede.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir a inclusão de novos nós na lista de elegibilidade determinada pela governança da RBB, concedendo também a opção de inserção imediata e efetiva nas atividades de consenso da rede. Esta inclusão pode ser realizada via endereço do validador ou, alternativamente, via chave pública do nó (representada por `enodeHigh` e `enodeLow`).

Toda inclusão bem-sucedida deve disparar um evento público informando o endereço do nó cadastrado para fins de auditabilidade e transparência. Adicionalmente, o sistema deve ajustar de forma autônoma os parâmetros de limites de tolerância a falhas caso o tamanho da lista de elegibilidade ultrapasse a configuração vigente.

3.2. Fluxo principal:

1. Deve ser informado ao sistema **obrigatoriamente**:
   - O endereço do nó validador (`validator`) ou, alternativamente, as duas partes de sua chave pública (`enodeHigh` e `enodeLow`) que permitam derivar o seu endereço.
2. O sistema deve validar:
   - Se o endereço informado ou o endereço derivado a partir de `enodeHigh` e `enodeLow` (obtido a partir dos 20 bytes menos significativos do hash `keccak256` das partes do enode concatenadas) é válido.
3. Se todas as validações forem atendidas:
   - O sistema deve realizar a inclusão do validador.
4. Caso qualquer uma das validações não seja atendida, a operação deve reverter, indicando erro de endereço inválido.

##### 4. Regras de Negócio

4.1. A execução desta história deve garantir as regras de consistência entre os conjuntos de validadores definidas na US1-1.

4.2. Somente a governança pode realizar a adição de novos nós elegíveis.

4.3. O nó informado não deve estar no conjunto de validadores elegíveis.

4.4. O nó informado deve ser adicionado ao conjunto de validadores elegíveis.

4.5. Deve ser informado se o nó será automaticamente adicionado como validador operacional. Em caso afirmativo:
* O nó é adicionado ao conjunto de validadores operacionais.
* O nó é adicionado ao conjunto de validadores protegidos.

4.6. Caso o valor informado para o parâmetro `blocksWithoutProposeThreshold` seja inferior à quantidade atual de validadores elegíveis, o contrato deve ajustar automaticamente o parâmetro para que o seu valor seja igualado ao total de nós elegíveis da rede.
* Nesse caso, um evento deve ser emitido obrigatoriamente, registrando:
  - a. O valor do parâmetro `blocksBetweenSelection`, independentemente de ter sofrido alteração nesta transação.
  - b. O valor final configurado para o parâmetro `blocksWithoutProposeThreshold`.

4.7. Um evento deve ser emitido, registrando o endereço do nó validador adicionado.

##### 5. Critérios de Aceite

5.1. A execução deve ser exclusiva da governança da RBB.  
5.2. A governança deve parametrizar o endereço do nó (ou os valores de `enodeHigh` e `enodeLow`) e indicar a flag de ativação operacional imediata.  
5.3. O sistema deve validar que o endereço (informado ou derivado) não existe previamente no conjunto de elegíveis.  
5.4. Se a flag de ativação operacional for verdadeira, o nó deve ser simultaneamente adicionado aos conjuntos operacional e de protegidos.  
5.5. Se a nova contagem total de nós elegíveis ultrapassar o limite atual de `blocksWithoutProposeThreshold`, o contrato deve reajustar automaticamente esse parâmetro para que seu valor se iguale à quantidade total de elegíveis da rede.  
5.6. Caso ocorrer a correção automática descrita acima, o sistema deve disparar um evento obrigatório registrando o valor vigente de `blocksBetweenSelection` e o novo limite recalculado de `blocksWithoutProposeThreshold`.  
5.7. Em qualquer fluxo de adição bem-sucedido, o contrato deve emitir obrigatoriamente um evento público registrando o endereço do nó que foi adicionado ao conjunto de validadores elegíveis.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Como garantir que um validador adicionado ao fim de um ciclo de monitoração automática não seja automaticamente removido por não ter tido tempo de produzir blocos? | Foi adotada a solução do conjunto de validadores protegidos. |
| **2** | Deveríamos colocar critérios adicionais para validar o endereço adicionado, como, por exemplo, verificar que está devidamente permissionado ou que está ativo? | Várias implementações seriam possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos. |
| **3** | É o caso de se flexibilizar a inclusão de validadores elegíveis sem obrigatoriamente torná-los operacionais ao mesmo tempo? Atualmente o processo de governança, sempre que decide pela inclusão de um novo validador ao consenso da rede, o faz de maneira imediata e efetiva. | Avaliou-se que, apesar de pouco provável que a flexibilidade seja necessária, sua implementação é simples e permite que possíveis alterações futuras de processo de governança sejam implementadas sem que sejam necessário atualizar o *smart contract*. |

---

#### US4-4: Remover validador elegível <a id="us4-4"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** remover um nó do conjunto de validadores elegíveis via seu endereço ou via sua chave pública (enodeHigh e enodeLow)  
**Para** impedir sua participação no consenso da rede

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir que a governança retire definitivamente a elegibilidade de um nó validador, o que resultará na sua remoção do consenso caso ele esteja operacional no momento do comando. Esta remoção pode ser realizada informando diretamente o endereço do validador ou, alternativamente, informando a sua chave pública (representada por `enodeHigh` e `enodeLow`).

3.2. Fluxo principal:

1. Deve ser informado ao sistema **obrigatoriamente**:
   - O endereço do nó validador (`validator`) ou, alternativamente, as duas partes de sua chave pública (`enodeHigh` e `enodeLow`) que permitam derivar o seu endereço.
2. O sistema deve validar:
   - Se o endereço informado ou o endereço derivado a partir de `enodeHigh` e `enodeLow` (obtido a partir dos 20 bytes menos significativos do hash `keccak256` das partes do enode concatenadas) é válido.
3. Se todas as validações forem atendidas:
   - O sistema deve realizar a remoção do validador.
4. Caso qualquer uma das validações não seja atendida, a operação deve reverter, indicando erro correspondente.

##### 4. Regras de Negócio

4.1. Somente a governança pode remover um nó validador elegível.

4.2. O nó a ser removido deve estar no conjunto de validadores elegíveis.

4.3. O nó informado será removido do conjunto de validadores elegíveis.

4.4. O nó informado será removido do conjunto de validadores operacionais, se estiver nesse conjunto.  
O nó somente será removido se ao menos 1 validador permanecer no conjunto de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.

4.5. O nó informado é removido do conjunto de validadores protegidos, se estiver nesse conjunto.

4.6. Um evento deve ser emitido registrando o endereço do nó que teve sua elegibilidade revogada.

4.7. Caso o nó removido pertença ao conjunto de validadores operacionais no momento da remoção, um evento específico de remoção operacional manual deve ser emitido adicionalmente.

##### 5. Critérios de Aceite

5.1. Somente o papel de governança pode invocar a remoção.  
5.2. O executor deve fornecer o endereço do nó validador ou, alternativamente, os parâmetros `enodeHigh` e `enodeLow` correspondentes.  
5.3. O endereço fornecido ou derivado deve ser validado e obrigatoriamente constar no rol de elegíveis.  
5.4. Caso o nó esteja inserido no conjunto de operacionais, o sistema deve validar se ao menos 1 nó operacional permanecerá ativo após sua saída. Caso a regra seja violada, encerra com erro.  
5.5. O sistema deve remover o nó avaliado de todos os conjuntos ativos (elegíveis, operacionais e protegidos).  
5.6. O contrato deve emitir um evento registrando o endereço do nó que teve sua elegibilidade revogada.  
5.7. Caso o nó a ser removido seja de fato um validador operacional, o sistema deve também disparar um evento específico registrando a remoção do nó do grupo de validadores operacionais.

---

### Épico 5: Governança e evolução do contrato <a id="epico-5"></a>

**Objetivo:** Administrar o ciclo de vida técnico do mecanismo *on-chain*.

#### US5-1: Atualizar o código de seleção de validadores <a id="us5-1"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o código de seleção de validadores  
**Para** garantir a evolução técnica e a atualização contínua do contrato inteligente, assegurando a continuidade de funcionamento do consenso da rede.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo dessa história é permitir que a governança defina um novo endereço de *smart contract* de seleção de validadores, garantindo de forma transparente a evolução contínua e a atualização técnica do ciclo de vida desse mecanismo. 

Durante a execução da atualização, o sistema deve validar não apenas a compatibilidade técnica do novo endereço (se implementa as funções necessárias), mas também realizar uma chamada de teste para garantir que o novo contrato retorne uma lista ativa de validadores funcional (tamanho mínimo de 1), evitando o travamento completo do consenso da rede Besu por erro de apontamento.

##### 4. Regras de Negócio

4.1. O novo contrato de seleção de validadores já deve ter sido implantado.

4.2. Somente a governança pode executar esta atualização de código.

4.3. A governança deve informar o endereço do novo contrato de seleção de validadores.
* Este endereço deve ser diferente do endereço corrente e não deve ser nulo.

4.4. O novo contrato de seleção de validadores deve implementar la função `getValidators()`.

4.5. A função `getValidators()` no novo contrato deve retornar obrigatoriamente uma lista com no mínimo 1 validador quando invocada no momento da atualização. Caso retorne uma lista vazia, a história é encerrada com erro e a transação é revertida.

4.6. Após a validação com sucesso de todas as regras, o endereço do contrato de seleção de validadores corrente é atualizado no estado.

4.7. Um evento é emitido, registrando o endereço do novo contrato de seleção de validadores.

##### 5. Critérios de Aceite

5.1. A execução desta atualização deve ser exclusiva da governança.  
5.2. O sistema deve exigir e validar que o endereço fornecido não seja nulo e que seja diferente do endereço do contrato atualmente ativo.  
5.3. O sistema deve validar que o novo endereço implementa a assinatura da função `getValidators()`. Caso contrário, reverte com erro.  
5.4. O sistema deve executar uma chamada de teste à função `getValidators()` no novo endereço e validar que o tamanho da lista de validadores retornada seja **maior ou igual a 1**. Caso a lista retornada seja vazia, a transação deve ser revertida com erro.  
5.5. Após a validação de todas as regras acima, o ponteiro e o endereço do contrato de seleção corrente devem ser atualizados com sucesso no estado do contrato.  
5.6. A transação deve emitir obrigatoriamente um evento público registrando o endereço do novo contrato de seleção de validadores.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Devemos implementar uma validação para garantir que o novo contrato de seleção de validadores implemente a função `getValidators()`? | Sim, entendemos que o custo de implementação é baixo e pode mitigar erros de operação. Além de validar a assinatura da função, também vamos validar o número de validadores elegíveis retornado pela função e garantir que seja maior ou igual a 1. Entendemos que o custo de implementação dessa validação é baixo e pode impedir travamentos no consenso da rede (< 1 validador), em um eventual caso de reponteiramento errado. |
| **2** | (Rayan) Devemos validar se a lista retornada pela função `getValidators()` é um subconjunto do conjunto de validadores elegíveis? Poderíamos verificar via contratos de Permissionamento. | Não. Pelos mesmos motivos avaliados nas histórias USSV01, USSV06 e USSV08, a validação geraria grande acoplamento com os contratos de Permissionamento e aumentaria a complexidade de implementação, sem compensar proporcionalmente o risco mitigado. |
| **3** | (JALOP) Nessa história temos que decidir que mecanismo vamos querer utilizar para fazer eventuais atualizações de código. | Considerando a documentação, optou-se por separar a lógica da regra de consenso de modo que uma atualização consista em reponteirar o endereço do contrato gestor de consenso, mantendo a simplicidade e evitando hard-forks na rede. |

---

#### US5-2: Consultar se o contrato de seleção de validadores implementa uma interface especificada <a id="us5-2"></a>

##### 1. História do Usuário

**Como** Usuário da RBB  
**Quero** consultar se o contrato de seleção de validadores implementa uma interface especificada  
**Para** verificar a compatibilidade técnica e a conformidade do contrato com padrões estabelecidos de interoperabilidade (como o ERC-165).

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.

##### 3. Descrição

3.1. O objetivo desta história é permitir que qualquer usuário, contrato ou sistema integrador na rede RBB verifique programaticamente se o contrato de seleção de validadores implementa uma determinada interface de funções.

Essa verificação é essencial para garantir a segurança de integrações e atualizações, permitindo constatar se o contrato possui o conjunto de funções esperado antes de interagir com ele. A implementação deve seguir o padrão ERC-165.

##### 4. Regras de Negócio

4.1. A consulta deve ser implementada seguindo o padrão de detecção de interface ERC-165 (`supportsInterface`).

4.2. Qualquer conta na rede (sem necessidade de privilégios especiais ou de permissionamento ativo) possui autorização para consultar o suporte a interfaces.

4.3. O contrato deve receber obrigatoriamente um parâmetro de entrada contendo o identificador de interface (`interfaceId`) de 4 bytes.

4.4. O contrato deve retornar `true` caso a interface consultada seja implementada e `false` caso contrário.

##### 5. Critérios de Aceite

5.1. Qualquer conta conectada à rede RBB deve possuir permissão para invocar a função de consulta de interface.  
5.2. O sistema deve exigir um identificador de 4 bytes (`interfaceId`) como parâmetro de entrada.  
5.3. A chamada da função passando o `interfaceId` correspondente à própria interface ERC-165 (`0x01ffc9a7`) deve retornar `true`.  
5.4. A chamada da função passando o `interfaceId` correspondente à interface de seleção de validadores (que expõe as funções regulamentadas nas histórias anteriores, como `getValidators()`) deve retornar `true`.  
5.5. A chamada da função passando um identificador de interface inválido ou não suportado (ex: `0xffffffff`) deve retornar `false`.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Além do identificador do ERC-165, qual interface deve ser mapeada no retorno desta consulta? | O contrato deve retornar `true` para a interface que agrupa as funções públicas de consulta e consenso do mecanismo (especialmente `getValidators()`). |
| **2** | Há risco de alto consumo de *gas* por ser uma função pública executada na blockchain? | Não, pois por ser uma consulta de leitura de estado, ela é executada localmente como uma chamada do tipo `view`/`pure` (sem custo de *gas* para quem a invoca remotamente via transação de consulta). |

---

#### US5-7: Atualizar o endereço do contrato de Admin na Lógica <a id="us5-7"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o endereço do contrato de Admin na Lógica  
**Para** manter a consistência com a governança da rede e permitir a evolução do controle de acesso administrativo.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.
* O novo contrato de Admin (`AdminProxy`) já deve existir na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança atualize o endereço do contrato `AdminProxy` (ponteiro de governança) registrado diretamente no contrato de Lógica (`ValidatorSelection`), garantindo que o controle de acesso por papéis (`onlyGovernance`) continue funcionando quando a governança da rede for migrada ou reconfigurada.

3.2. Fluxo principal:

1. O endereço do novo contrato de Admin deve ser informado ao sistema.
2. O sistema deve validar:
   - Se o endereço informado não é nulo (`address(0)`).
   - Se o endereço informado é diferente do endereço ativo atualmente.
   - Se o novo contrato implementa de fato o `AdminProxy` realizando uma chamada de teste (`isAuthorized(address(0))`).
3. Se as validações forem atendidas, o sistema atualiza o storage `admins` do contrato de Lógica com o novo endereço.
4. O sistema emite um evento registrando os endereços antigo e novo.
5. Caso qualquer validação falhe, a transação deve ser revertida com o erro correspondente.

##### 4. Regras de Negócio

4.1. Somente a governança ativa (autorizada pelo `AdminProxy` atual) pode executar esta atualização.

4.2. O novo contrato de AdminProxy deve responder com sucesso à chamada `isAuthorized(address(0))`.

4.3. Após a validação com sucesso, o endereço do ponteiro de governança na Lógica é atualizado.

4.4. Um evento deve ser emitido registrando os endereços antigo e novo.

##### 5. Critérios de Aceite

5.1. A execução desta atualização deve ser exclusiva da governança autorizada.  
5.2. O sistema deve exigir e validar que o endereço fornecido não seja nulo e que seja diferente do endereço do contrato atualmente ativo.  
5.3. O sistema deve validar que o novo endereço implementa a interface correta por meio de uma chamada de teste `isAuthorized(address(0))`. Caso falhe ou reverta, a transação deve ser revertida com erro.  
5.4. Após a validação de todas as regras acima, a variável de storage `admins` da Lógica deve ser atualizada com o novo endereço.  
5.5. A transação deve emitir obrigatoriamente o evento `AdminContractUpdated(address indexed oldAdmin, address indexed newAdmin)`.

---

#### US5-8: Atualizar o endereço do contrato de Regras de Contas na Lógica <a id="us5-8"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o endereço do contrato de Regras de Contas na Lógica  
**Para** suportar migrações do contrato de contas e novas definições de papéis de administradores de nós.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.
* O novo contrato de regras de contas (`AccountRulesV2`) já deve existir na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança atualize o endereço do contrato `AccountRulesV2` (ponteiro de contas) registrado no contrato de Lógica (`ValidatorSelection`), viabilizando a compatibilidade com eventuais atualizações de lógica ou migrações do sistema de contas da rede.

3.2. Fluxo principal:

1. O endereço do novo contrato de contas deve ser informado ao sistema.
2. O sistema deve validar:
   - Se o endereço informado não é nulo (`address(0)`).
   - Se o endereço informado é diferente do endereço ativo atualmente.
   - Se o novo contrato implementa de fato o `IAccountRulesV2` realizando uma chamada de teste (`isAccountActive(address(0))`).
3. Se as validações forem atendidas, o sistema atualiza o storage `accountsContract` do contrato de Lógica com o novo endereço.
4. O sistema emite um evento registrando os endereços antigo e novo.
5. Caso qualquer validação falhe, a transação deve ser revertida com o erro correspondente.

##### 4. Regras de Negócio

4.1. Somente a governança ativa pode executar esta atualização.

4.2. O novo contrato de regras de contas deve responder com sucesso à chamada `isAccountActive(address(0))`.

4.3. Após a validação com sucesso, o endereço do contrato de contas na Lógica é atualizado.

4.4. Um evento deve ser emitido registrando os endereços antigo e novo.

##### 5. Critérios de Aceite

5.1. A execução desta atualização deve ser exclusiva da governança autorizada.  
5.2. O sistema deve exigir e validar que o endereço fornecido não seja nulo e que seja diferente do endereço do contrato atualmente ativo.  
5.3. O sistema deve validar que o novo endereço implementa a interface correta por meio de uma chamada de teste `isAccountActive(address(0))`. Caso falhe ou reverta, a transação deve ser revertida com erro.  
5.4. Após a validação de todas as regras acima, a variável de storage `accountsContract` da Lógica deve ser atualizada com o novo endereço.  
5.5. A transação deve emitir obrigatoriamente o evento `AccountsContractUpdated(address indexed oldAccounts, address indexed newAccounts)`.

---

#### US5-9: Atualizar o endereço do contrato de Regras de Nós na Lógica <a id="us5-9"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o endereço do contrato de Regras de Nós na Lógica  
**Para** suportar migrações do contrato de regras de nós e evolução do permissionamento de nós.

##### 2. Pré-requisitos

* US1-1: Implantar código de seleção de validadores.
* O novo contrato de regras de nós (`NodeRulesV2`) já deve existir na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança atualize o endereço do contrato `NodeRulesV2` (ponteiro de nós) registrado no contrato de Lógica (`ValidatorSelection`), mantendo a compatibilidade do controle organizacional dos nós com eventuais atualizações de lógica do permissionamento da rede.

3.2. Fluxo principal:

1. O endereço do novo contrato de regras de nós deve ser informado ao sistema.
2. O sistema deve validar:
   - Se o endereço informado não é nulo (`address(0)`).
   - Se o endereço informado é diferente do endereço ativo atualmente.
   - Se o novo contrato implementa de fato o `INodeRulesV2` realizando uma chamada de teste (`allowedNodes(0)`).
3. Se as validações forem atendidas, o sistema atualiza o storage `nodesContract` do contrato de Lógica com o novo endereço.
4. O sistema emite um evento registrando os endereços antigo e novo.
5. Caso qualquer validação falhe, a transação deve ser revertida com o erro correspondente.

##### 4. Regras de Negócio

4.1. Somente a governança ativa pode executar esta atualização.

4.2. O novo contrato de regras de nós deve responder com sucesso à chamada `allowedNodes(0)`.

4.3. Após a validação com sucesso, o endereço do contrato de nós na Lógica é atualizado.

4.4. Um evento deve ser emitido registrando os endereços antigo e novo.

##### 5. Critérios de Aceite

5.1. A execução desta atualização deve ser exclusiva da governança autorizada.  
5.2. O sistema deve exigir e validar que o endereço fornecido não seja nulo e que seja diferente do endereço do contrato atualmente ativo.  
5.3. O sistema deve validar que o novo endereço implementa a interface correta por meio de uma chamada de teste `allowedNodes(0)`. Caso falhe ou reverta, a transação deve ser revertida com erro.  
5.4. Após a validação de todas as regras acima, a variável de storage `nodesContract` da Lógica deve ser atualizada com o novo endereço.  
5.5. A transação deve emitir obrigatoriamente o evento `NodesContractUpdated(address indexed oldNodes, address indexed newNodes)`.

