# *Ingress* da Seleção de Validadores *on chain*

## Princípios do *Ingress* seleção de validadores *on chain*<a id="principios"></a>

Para alterar o mecanismo de seleção de validadores na RBB, é necessário realizar uma [transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods). Essa transição é equivalente a um *hard fork* na rede. Para evitarmos novos *hard forks* em possíveis atualizações da lógica da seleção de validadores *on chain*, separamos a lógica da seleção do ponto de acesso do Besu. Assim, podemos manter um ponto de acesso fixo, enquanto fazemos alterações na lógica do mecanismo de seleção, evitando novos *hard forks*.

O *Ingress* da seleção de validadores é um contrato que atua como uma fachada para o Besu. Ele não deve implementar a lógica de seleção de validadores, mas manter o registro do endereço do contrato que implementa a lógica e fazer o redirecionamento da chamada do Besu para o contrato de lógica.

O objetivo é prover um mecanismo que permite a atualização da lógica de seleção de validadores sem implicar em um *hard fork* na rede.

## USSVI01 - Usuário da RBB implanta e inicializa código do *Ingress* da seleção de validadores<a id="ussvi01"></a>

**Observações**:

- Esta história será executada uma única vez.
- O contrato de *Ingress* é o ponto de acesso fixo do Besu para a seleção de validadores. Seu endereço será configurado no arquivo gênesis da rede e, portanto, não deve ser alterado após a implantação.
- Para que o código desta história seja efetivamente usado na rede, será necessário aplicar uma [transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods), de forma a alterar o [mecanismo de seleção de validadores do Besu](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) de *block header* para *smart contract*, apontando para o endereço do *Ingress*. Isto **não** está contemplado nesta história.

Critérios de aceitação:

1. É informado o endereço do *smart contract* de Admin.
   1. O endereço informado deve ser não nulo.
   2. É verificado se o contrato de Admin implementa a função `isAuthorized()`. Caso contrário, a história é encerrada com erro.
      - Observação: Como o contrato de Admin atual não suporta o ERC-165, não poderíamos fazer a verificação da interface suportada via ERC-165, mas podemos verificar se chamar o `isAuthorized()` retorna algum erro.
2. É informado o endereço do *smart contract* de seleção de validadores (contrato de lógica).
   1. Este endereço deve implementar a função `getValidators()`.
      1. Caso contrário, a história é encerrada com erro.
   2. É validado que este endereço retorna uma lista de tamanho pelo menos 1 quando `getValidators()` é invocada.
      1. Caso contrário, a história é encerrada com erro.
3. O endereço do contrato de seleção de validadores é registrado internamente.
4. O *Ingress* não deve implementar lógica de seleção de validadores; deve apenas redirecionar chamadas para o contrato de lógica registrado.

## USSVI02 - Besu consulta validadores operacionais para execução do algoritmo de consenso<a id="ussvi02"></a>

Critérios de aceitação:

1. Qualquer conta ou o Besu pode invocar a função `getValidators()` no contrato de *Ingress*.
2. O *Ingress* deve redirecionar a chamada para a função `getValidators()` do contrato de seleção de validadores registrado.
3. O conjunto de validadores operacionais retornado pelo contrato de seleção de validadores é retornado ao chamador.

Dúvidas:

1. O que ocorre se for retornado uma lista vazia ao Besu, ou a chamada do Besu retornar um erro?
   - A rede para de produzir blocos. Este cenário pode ocorrer em três situações:

      a. Erro no contrato de lógica: Já temos salvaguardas para impedir a remoção de validadores, caso a remoção resulte em um número menor que 4 validadores operacionais. Apesar disso, pode ser prudente implementar um fallback para, por exemplo, no momento do retorno da lista ao contrato *Ingress*, haja uma verificação e caso a lista esteja vazia, ao invés de retornar a lista dos validadores operacionais, retornasse a lista dos validadores elegíveis.

      b. Erro no repasse da chamada do *Ingress* para o contrato de lógica: Pode ocorrer, por exemplo, se o endereço do contrato de lógica não for válido, ou se o contrato não implementar a função `getValidators()`. Neste caso, também pode ser útil implementar um fallback, que pode ser para a lista de validores elegíveis também. Porém, neste caso, como estamos considerando um erro de repasse, este erro também pode ocorrer na leitura dos validadores elegíveis no contrato de lógica. Assim, podemos considerar uma lista estática de "endereços de emergência", que será utilizada no lugar da lista de validadores elegíveis caso ocorra um erro de repasse da chamada do *Ingress* para o contrato de lógica. Essa lista de emergência poderia ser informada quando o *Ingress* é implantado ou mantida hardcoded no código (evitando lógica no *Ingress*).

      c. Erro na chamada do Besu ao *Ingress*: Aqui pode ser um erro na implementação do *Ingress*, ou na chamada do Besu ao *Ingress*. Acredito que o primeiro caso é mitigado com a ausência de lógica no *Ingress* e testes extensivos. O segundo seria um erro/bug do Besu, o que não está sendo considerado aqui.

## USSVI03 - Governança atualiza o endereço do contrato de seleção de validadores<a id="ussvi03"></a>

Critérios de aceitação:

1. Somente a governança pode realizar esta atualização.
2. A governança deve informar o endereço do novo contrato de seleção de validadores.
   1. Este endereço deve ser diferente do endereço corrente e deve ser não nulo.
   2. É validado que este endereço implementa a função `getValidators()`.
      1. Caso contrário, a história é encerrada com erro.
   3. É validado que este endereço retorna uma lista de tamanho pelo menos 1 quando `getValidators()` é invocada.
      1. Caso contrário, a história é encerrada com erro.
3. O endereço do contrato de seleção de validadores registrado no *Ingress* é atualizado.
4. Um evento é emitido, registrando:
   1. O endereço do contrato de seleção de validadores anterior.
   2. O endereço do novo contrato de seleção de validadores.

## USSVI04 - Governança remove o endereço do contrato de seleção de validadores<a id="ussvi04"></a>

**Observações**:

- A remoção do contrato de seleção de validadores poderá impactar o consenso da rede. Esta operação deve ser utilizada com cautela, em situações excepcionais.

Critérios de aceitação:

1. Somente a governança pode realizar esta remoção.
2. O endereço do contrato de seleção de validadores registrado no *Ingress* é removido (definido como endereço nulo).
3. Um evento é emitido, registrando:
   1. O endereço do contrato de seleção de validadores que foi removido.

Dúvidas:

1. Devemos permitir a remoção do contrato de seleção de validadores, dado que isso pode impactar o consenso da rede?
   - Sim. A governança é soberana e pode precisar remover o contrato em situações excepcionais, como em casos de falha grave no contrato de seleção de validadores.

## USSVI05 - Governança atualiza o endereço do contrato de Admin<a id="ussvi05"></a>

Critérios de aceitação:

1. Somente a governança pode realizar esta atualização.
2. A governança deve informar o endereço do novo contrato de Admin ([`AdminProxy`](https://github.com/RBBNet/Permissionamento/blob/main/gen01/contracts/AdminProxy.sol)).
   1. Este endereço deve ser diferente do endereço corrente e deve ser não nulo.
   2. É verificado se o contrato de Admin implementa a função `isAuthorized()`.
3. O endereço do contrato de Admin registrado no *Ingress* é atualizado.
4. Um evento é emitido, registrando:
   1. O endereço do contrato de Admin anterior.
   2. O endereço do novo contrato de Admin.

## USSVI06 - Governança remove o endereço do contrato de Admin<a id="ussvi06"></a>

**Observações**:

- A remoção do contrato de Admin poderá impactar o consenso da rede. Esta operação deve ser utilizada com cautela, em situações excepcionais.

Critérios de aceitação:

1. Somente a governança pode realizar esta remoção.
2. O endereço do contrato de Admin registrado no *Ingress* é removido (definido como endereço nulo).
3. Um evento é emitido, registrando:
   1. O endereço do contrato de Admin que foi removido.

## USSVI07 - Usuário da RBB consulta endereços registrados<a id="ussvi07"></a>

Critérios de aceitação:

1. Qualquer conta pode consultar os endereços registrados no *Ingress*.
2. O *Ingress* deve expor funções para consultar:
   1. O endereço do contrato de seleção de validadores registrado.
   2. O endereço do contrato de Admin registrado.
3. Os endereços são retornados ao chamador.
   1. Caso um endereço não esteja registrado, o valor retornado deve ser o endereço nulo (`address(0)`).
