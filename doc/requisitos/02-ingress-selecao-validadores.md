# Histórias de Usuário — Ingress da Seleção de Validadores *on-chain*

## Sumário

1. [Introdução](#introducao)
2. [Visão Geral do Escopo](#visao-geral)
3. [Detalhamento](#detalhamento)
   - [Épico 1: Implantação e migração para seleção on-chain](#epico-1)
     - [US1-2: Implantar código do Ingress](#us1-2)
   - [Épico 2: Consulta dos conjuntos de validadores](#epico-2)
     - [US2-3: Redirecionar consulta de validadores operacionais pelo Besu](#us2-3)
     - [US2-4: Consultar endereços registrados no Ingress](#us2-4)
   - [Épico 5: Governança e evolução do contrato](#epico-5)
     - [US5-3: Atualizar o endereço do contrato de seleção de validadores](#us5-3)
     - [US5-4: Remover o endereço do contrato de seleção de validadores](#us5-4)
     - [US5-5: Atualizar o endereço do contrato de Admin](#us5-5)
     - [US5-6: Remover o endereço do contrato de Admin](#us5-6)

---

## 1. Introdução <a id="introducao"></a>

**Data da liberação do documento:** 02/07/2026

**Objetivo:**

Este documento detalha as histórias de usuário e critérios de aceitação para o componente Ingress do Sistema de Seleção de Validadores *on-chain* da RBB. O Ingress atua como ponto de entrada fixo e seguro para o cliente Besu, delegando as consultas ao contrato de Lógica de Seleção e permitindo atualizações na governança e lógica sem a necessidade de hard forks.

---

## 2. Visão Geral do Escopo <a id="visao-geral"></a>

| Épico | Objetivo | Histórias |
| :--- | :--- | :--- |
| **1. Implantação e migração para seleção on-chain** | Realizar a transição do consenso baseado em *block header* para a seleção via *smart contracts*, implantando e inicializando os componentes. | - US1-2: Implantar código do Ingress |
| **2. Consulta dos conjuntos de validadores** | Disponibilizar transparência, auditoria de configurações e informações sobre os conjuntos de validadores na rede. | - US2-3: Redirecionar consulta de validadores operacionais pelo Besu<br>- US2-4: Consultar endereços registrados no Ingress |
| **3. Operação automática da seleção de validadores** | Controlar a execução automática da monitorização de desempenho e reajustes automáticos de consenso. | *N/A (Lógica sob responsabilidade do contrato de seleção)* |
| **4. Administração manual de validadores** | Permitir a intervenção manual de administradores e da governança na composição dos conjuntos de validadores. | *N/A (Lógica sob responsabilidade do contrato de seleção)* |
| **5. Governança e evolução do contrato** | Administrar a atualização dos contratos inteligentes, garantindo compatibilidade técnica e conformidade. | - US5-3: Atualizar o endereço do contrato de seleção de validadores<br>- US5-4: Remover o endereço do contrato de seleção de validadores<br>- US5-5: Atualizar o endereço do contrato de Admin<br>- US5-6: Remover o endereço do contrato de Admin |

---

## 3. Detalhamento <a id="detalhamento"></a>

### Épico 1: Implantação e migração para seleção on-chain <a id="epico-1"></a>

**Objetivo:** Realizar a transição completa da seleção de validadores via *block header* para *smart contracts*, configurando a infraestrutura inicial do Ingress e do contrato de Lógica de seleção de validadores na rede Besu.

#### US1-2: Implantar código do Ingress <a id="us1-2"></a>

##### 1. História do Usuário

**Como** Usuário da RBB  
**Quero** implantar e inicializar o código do Ingress  
**Para** estabelecer um ponto de acesso fixo para o Besu e permitir a atualização da lógica de seleção de validadores sem implicar em *hard fork* na rede

##### 2. Pré-requisitos

* O contrato de Admin (`AdminProxy`) e o contrato de seleção de validadores (contrato de lógica) já devem existir na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir a implantação e a inicialização do *smart contract* de *Ingress*, que atua como uma fachada para o Besu. Ele deve manter o registro do endereço do contrato que implementa a lógica e do contrato de Admin. O *Ingress* não deve conter lógica interna de seleção de validadores, mas apenas redirecionar chamadas do Besu para o contrato correspondente.

3.2. Fluxo principal:

1. Devem ser informados ao sistema **obrigatoriamente**:
   - O endereço do contrato de Admin (`AdminProxy`).
   - O endereço do contrato de seleção de validadores (contrato de lógica).
2. O sistema deve validar:
   - Se o endereço informado do contrato de Admin é válido e diferente de nulo.
   - Se o contrato de Admin implementa a função `isAuthorized()`.
   - Se o endereço do contrato de seleção de validadores é válido e diferente de nulo.
   - Se o contrato de seleção de validadores implementa a função `getValidators()`.
   - Se a chamada da função `getValidators()` no contrato de seleção retorna uma lista com no mínimo 1 validador.
3. Se todas as validações forem atendidas, o *Ingress* deve ser implantado e os endereços registrados internamente.
4. Caso qualquer uma das validações não seja atendida, a transação deve ser revertida com o erro correspondente.

##### 4. Regras de Negócio

4.1. Esta história será executada uma única vez.

4.2. O contrato de Ingress é o ponto de acesso fixo do Besu para a seleção de validadores. Seu endereço será configurado no arquivo gênesis da rede e, portanto, não deve ser alterado após a implantação.

4.3. Para que o código desta história seja efetivamente usado na rede, será necessário aplicar uma transição no arquivo gênesis da rede, de forma a alterar o mecanismo de seleção de validadores do Besu de *block header* para *smart contract*, apontando para o endereço do *Ingress*. Isto não está contemplado nesta história.

4.4. O Ingress não deve implementar a lógica de seleção de validadores; deve apenas redirecionar chamadas para o contrato de lógica registrado.

4.5. Como o contrato de Admin atual não suporta o ERC-165, não é possível fazer a verificação da interface suportada via ERC-165. Contudo, deve ser verificado se chamar a função `isAuthorized()` retorna algum erro.

##### 5. Critérios de Aceite

5.1. A execução desta história deve ocorrer apenas uma única vez na rede.  
5.2. O sistema deve exigir a informação do endereço do contrato `AdminProxy`, validando que ele não é nulo.  
5.3. O sistema deve verificar se o contrato de Admin informado implementa a função `isAuthorized()`, revertendo com erro em caso negativo.  
5.4. O sistema deve exigir a informação do endereço do contrato de seleção de validadores, validando que ele não é nulo.  
5.5. O sistema deve validar que o contrato de seleção de validadores informado implementa a assinatura da função `getValidators()`.  
5.6. O sistema deve validar que a chamada à função `getValidators()` no endereço informado retorna uma lista com pelo menos 1 validador.  
5.7. Após a conclusão bem-sucedida, os endereços informados devem estar corretamente registrados internamente no contrato Ingress.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `constructor` do `ValidatorSelectionIngress`](../especificacao-tecnica/02-especificacao-funcoes.md#311-constructor) — Especificação detalhada da implantação do Ingress.
  * [Modelo de Dados do `ValidatorSelectionIngress`](../especificacao-tecnica/01-modelo-contratos.md#21-contrato-validatorselectioningress) — Storage e estrutura do Ingress.
* **Arquitetura:**
  * [DA-01: Padrão Ingress/Facade sem Proxy de Storage](../arquitetura/01-visao-geral.md#da-01) — Fachada fixa configurada no gênesis do Besu.
  * [DA-02: Validação try/catch para Interfaces Legadas](../arquitetura/01-visao-geral.md#da-02) — Validação de `isAuthorized()` e `getValidators()` via try/catch.
  * [DA-07: Simplificação da Lógica de Fallback no Ingress](../arquitetura/01-visao-geral.md#da-07) — Ausência de lógica interna complexa.

---

### Épico 2: Consulta dos conjuntos de validadores <a id="epico-2"></a>

**Objetivo:** Disponibilizar transparência, auditabilidade e permitir a integração direta do cliente Besu para obter o conjunto de validadores operacionais e elegíveis e os endereços de governança configurados.

#### US2-3: Redirecionar consulta de validadores operacionais pelo Besu <a id="us2-3"></a>

##### 1. História do Usuário

**Como** Cliente Besu ou Qualquer Conta da rede  
**Quero** consultar os validadores operacionais no contrato de Ingress  
**Para** obter o conjunto de validadores utilizados pelo algoritmo de consenso QBFT da RBB

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.

##### 3. Descrição

3.1. O objetivo desta história é permitir que o Besu (ou qualquer conta na rede) obtenha a lista de validadores operacionais diretamente do Ingress. O Ingress serve como a fachada única e fixa para o Besu. Ele recebe a chamada da função `getValidators()` e a redireciona para a mesma função no contrato de lógica registrado, retornando o resultado.

##### 4. Regras de Negócio

4.1. Qualquer conta ou o Besu tem permissão para invocar a função `getValidators()` no contrato de Ingress.

4.2. O Ingress deve redirecionar a chamada para a função `getValidators()` do contrato de seleção de validadores atualmente registrado.

4.3. Em caso de sucesso no redirecionamento ao contrato de seleção de validadores e retorno de uma lista não vazia, o conjunto de validadores operacionais obtido deve ser repassado de volta ao chamador.

4.4. Caso o contrato de seleção de validadores não esteja definido (`address(0)`), ocorra um erro (reversão) no redirecionamento da chamada, ou a chamada retorne uma lista vazia, o Ingress deve interceptar esse cenário (fallback) e retornar uma lista contendo unicamente o endereço do validador do bloco atual (`block.coinbase`).

##### 5. Critérios de Aceite

5.1. Qualquer conta ou o cliente Besu deve possuir permissão para invocar a função `getValidators()` no contrato de Ingress.  
5.2. O Ingress deve redirecionar a chamada para a função `getValidators()` do contrato de seleção de validadores registrado.  
5.3. Se a chamada ao contrato de seleção for bem-sucedida e retornar uma lista não vazia, esses validadores operacionais devem ser retornados ao chamador.  
5.4. Se o contrato de seleção não estiver definido (`address(0)`), se a chamada ao contrato falhar (reverter), ou se o retorno for uma lista vazia, o Ingress deve capturar a falha/vazio e retornar uma lista contendo somente o endereço do validador do bloco atual (`block.coinbase`), sem propagar o erro/reversão.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `getValidators` do `Ingress`](../especificacao-tecnica/02-especificacao-funcoes.md#312-getvalidators) — Algoritmo detalhado com fallback para `block.coinbase`.
* **Arquitetura:**
  * [DA-01: Padrão Ingress/Facade sem Proxy de Storage](../arquitetura/01-visao-geral.md#da-01) — Ingress como ponto de entrada fixo.
  * [DA-02: Validação try/catch para Interfaces Legadas](../arquitetura/01-visao-geral.md#da-02) — Chamada externa protegida.
  * [DA-07: Simplificação da Lógica de Fallback no Ingress](../arquitetura/01-visao-geral.md#da-07) — Fallback simples para `block.coinbase`.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | O que ocorre se for retornado uma lista vazia ao Besu, ou a chamada do Besu retornar um erro? | Para mitigar o risco de parada da rede por falha no contrato de lógica, falta de contrato associado ou lista vazia retornada, foi definido um mecanismo de fallback no Ingress. Em qualquer um desses cenários de erro ou lista vazia, o Ingress intercepta a falha/vazio e retorna uma lista de tamanho 1 contendo o endereço do validador do bloco atual (`block.coinbase`), permitindo que a rede continue operando com o proponente do bloco corrente. |

---

#### US2-4: Consultar endereços registrados no Ingress <a id="us2-4"></a>

##### 1. História do Usuário

**Como** Qualquer conta da rede  
**Quero** consultar os endereços registrados no Ingress  
**Para** verificar quais são os endereços atuais dos contratos de seleção de validadores e de Admin

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.

##### 3. Descrição

3.1. O objetivo desta história é expor funções de consulta pública no contrato Ingress, garantindo total transparência e auditabilidade em relação aos contratos que operam nos bastidores da fachada (a lógica de seleção e o AdminProxy).

##### 4. Regras de Negócio

4.1. Qualquer conta da rede possui permissão para consultar os endereços atualmente registrados no Ingress.

4.2. Caso um endereço não esteja registrado (ou tenha sido removido), o valor retornado deve ser o endereço nulo (`address(0)`).

##### 5. Critérios de Aceite

5.1. Qualquer conta conectada à rede deve possuir permissão para consultar os endereços registrados no Ingress.  
5.2. O Ingress deve expor funções específicas para consultar:  
   - O endereço do contrato de seleção de validadores registrado.  
   - O endereço do contrato de Admin registrado.  
5.3. Os endereços consultados devem ser retornados com sucesso ao chamador. Caso um endereço não esteja registrado, o valor retornado deve ser `address(0)`.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Consultas Diretas `validatorSelectionContract` e `admins`](../especificacao-tecnica/02-especificacao-funcoes.md#318-validatorselectioncontract-e-admins-consultas-diretas) — Funções de consulta pública do Ingress.

---

### Épico 5: Governança e evolução do contrato <a id="epico-5"></a>

**Objetivo:** Administrar o ciclo de vida técnico e o reponteiramento dos contratos de seleção e de governança na rede sem interrupção de serviço ou necessidade de hard-fork.

#### US5-3: Atualizar o endereço do contrato de seleção de validadores <a id="us5-3"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o endereço do contrato de seleção de validadores no Ingress  
**Para** realizar a evolução do mecanismo ou correção de problemas da lógica de seleção de validadores sem a necessidade de um *hard fork*

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.
* O novo contrato de seleção de validadores já deve estar implantado na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança atualize o endereço do contrato de seleção de validadores configurado no Ingress, ativando uma nova versão do mecanismo de consenso sem a necessidade de alterar a gênesis da rede Besu.

3.2. Fluxo principal:

1. A governança envia uma transação para o Ingress informando o novo endereço do contrato de seleção de validadores.
2. O sistema valida:
   - Se o remetente é a governança autorizada (via contrato de Admin).
   - Se o novo endereço é não nulo e diferente do endereço atualmente configurado.
   - Se o novo contrato implementa a assinatura da função `getValidators()`.
   - Se a execução de `getValidators()` no novo endereço retorna uma lista contendo no mínimo 1 validador operacional.
3. Caso todas as validações sejam bem-sucedidas, o endereço no Ingress é atualizado.
4. Um evento é disparado contendo o endereço anterior e o novo endereço.
5. Se alguma validação falhar, a transação é revertida com a indicação do erro.

##### 4. Regras de Negócio

4.1. Somente a governança pode realizar esta atualização.

4.2. O endereço do novo contrato de seleção de validadores deve ser diferente do endereço corrente e não deve ser nulo.

4.3. É validado se o novo endereço implementa a função `getValidators()`. Caso contrário, a história é encerrada com erro.

4.4. É validado se o novo endereço retorna uma lista de tamanho pelo menos 1 quando `getValidators()` é invocada. Caso contrário, a história é encerrada com erro.

4.5. Um evento deve ser emitido registrando o endereço do contrato de seleção de validadores anterior e o novo endereço configurado.

##### 5. Critérios de Aceite

5.1. A transação deve ser rejeitada e revertida se for executada por uma conta diferente da governança.  
5.2. O sistema deve validar e exigir que o novo endereço de seleção de validadores seja não nulo e diferente do atualmente cadastrado.  
5.3. O sistema deve validar que o novo endereço implementa a função `getValidators()`.  
5.4. O sistema deve validar que a chamada de teste `getValidators()` no novo endereço retorna uma lista com tamanho maior ou igual a 1.  
5.5. Após a validação com sucesso de todas as regras, o endereço do contrato de seleção de validadores registrado no Ingress deve ser atualizado no estado.  
5.6. A transação deve emitir obrigatoriamente um evento registrando o endereço do contrato de seleção de validadores anterior e o novo endereço.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `updateValidatorSelectionContract`](../especificacao-tecnica/02-especificacao-funcoes.md#313-updatevalidatorselectioncontract) — Especificação detalhada da atualização.
* **Arquitetura:**
  * [DA-01: Padrão Ingress/Facade sem Proxy de Storage](../arquitetura/01-visao-geral.md#da-01) — Reponteiramento no Ingress.
  * [DA-02: Validação try/catch](../arquitetura/01-visao-geral.md#da-02) — Validação dinâmica de `getValidators()`.

---

#### US5-4: Remover o endereço do contrato de seleção de validadores <a id="us5-4"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** remover o endereço do contrato de seleção de validadores cadastrado no Ingress  
**Para** suspender a lógica de seleção de validadores no Ingress em situações excepcionais

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança remova a referência ao contrato de seleção de validadores no Ingress (definindo-a como endereço nulo). Esta operação impactará diretamente o consenso da rede, devendo ser utilizada de forma excepcional e com extrema cautela.

##### 4. Regras de Negócio

4.1. Somente a governança pode realizar esta remoção.

4.2. O endereço do contrato de seleção de validadores registrado no Ingress é definido como endereço nulo (`address(0)`).

4.3. Um evento é emitido, registrando o endereço do contrato de seleção de validadores que foi removido.

##### 5. Critérios de Aceite

5.1. A remoção deve ser exclusiva do papel de governança da RBB.  
5.2. Ao finalizar a transação, o endereço registrado para o contrato de lógica no Ingress deve ser nulo (`address(0)`).  
5.3. Um evento deve ser disparado com sucesso registrando o endereço do contrato de seleção de validadores que foi removido.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `removeValidatorSelectionContract`](../especificacao-tecnica/02-especificacao-funcoes.md#315-removevalidatorselectioncontract) — Especificação detalhada da remoção.
* **Arquitetura:**
  * [DA-01: Padrão Ingress/Facade sem Proxy de Storage](../arquitetura/01-visao-geral.md#da-01) — Operação de emergência no Ingress.

##### Dúvidas

| ID | Pergunta | Resposta |
| :--- | :--- | :--- |
| **1** | Devemos permitir a remoção do contrato de seleção de validadores, dado que isso pode impactar o consenso da rede? | Sim. A governança é soberana e pode precisar remover o contrato em situações excepcionais, como em casos de falha grave no contrato de seleção de validadores. |

---

#### US5-5: Atualizar o endereço do contrato de Admin <a id="us5-5"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** atualizar o endereço do contrato de Admin no Ingress  
**Para** refletir mudanças ou evolução na governança e permissionamento da RBB

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.
* O novo contrato de Admin (`AdminProxy`) já deve estar implantado na rede.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança migre o controle de autorização do Ingress para um novo contrato de Admin (`AdminProxy`), garantindo o alinhamento com a evolução e estrutura de permissionamento global da rede RBB.

##### 4. Regras de Negócio

4.1. Somente a governança pode realizar esta atualização.

4.2. A governança deve informar o endereço do novo contrato de Admin (`AdminProxy`).

4.3. O novo endereço deve ser diferente do endereço corrente e não deve ser nulo.

4.4. É verificado se o contrato de Admin informado implementa a função `isAuthorized()`. Caso contrário, a transação reverte com erro.

4.5. Um evento deve ser emitido, registrando o endereço do Admin anterior e o novo endereço cadastrado.

##### 5. Critérios de Aceite

5.1. A transação deve ser restrita e revertida caso o executor não seja a governança autorizada.  
5.2. O sistema deve validar e rejeitar endereços nulos ou idênticos ao endereço de Admin em vigor.  
5.3. O sistema deve validar que o novo contrato de Admin implementa a função `isAuthorized()`.  
5.4. Após a validação, o endereço do contrato de Admin registrado no Ingress deve ser atualizado no estado.  
5.5. A transação deve emitir obrigatoriamente um evento registrando o endereço do contrato de Admin anterior e o novo endereço.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `updateAdminContract` do `Ingress`](../especificacao-tecnica/02-especificacao-funcoes.md#314-updateadmincontract) — Especificação detalhada.
* **Arquitetura:**
  * [DA-02: Validação try/catch](../arquitetura/01-visao-geral.md#da-02) — Validação dinâmica de `isAuthorized()`.

---

#### US5-6: Remover o endereço do contrato de Admin <a id="us5-6"></a>

##### 1. História do Usuário

**Como** Governança da RBB  
**Quero** remover o endereço do contrato de Admin cadastrado no Ingress  
**Para** desassociar o controle de governança do Ingress em casos excepcionais

##### 2. Pré-requisitos

* US1-2: Implantar código do Ingress.

##### 3. Descrição

3.1. O objetivo desta história é permitir que a governança remova a referência ao contrato de Admin no Ingress, limpando-a para `address(0)`. Esta é uma operação de alta sensibilidade e excepcional, pois remove a governança ativa do contrato de Ingress.

##### 4. Regras de Negócio

4.1. Somente a governança pode realizar esta remoção.

4.2. O endereço do contrato de Admin registrado no Ingress é removido e definido como nulo (`address(0)`).

4.3. Um evento é emitido, registrando o endereço do contrato de Admin que foi removido.

##### 5. Critérios de Aceite

5.1. A execução deve ser restrita ao papel de governança da rede.  
5.2. Ao finalizar a transação, o endereço de Admin armazenado no Ingress deve ser nulo (`address(0)`).  
5.3. Um evento deve ser emitido registrando o endereço do contrato de Admin que foi removido.

##### Referências Técnicas

* **Especificação Técnica:**
  * [Função `removeAdminContract`](../especificacao-tecnica/02-especificacao-funcoes.md#316-removeadmincontract) — Especificação detalhada da operação de emergência.
