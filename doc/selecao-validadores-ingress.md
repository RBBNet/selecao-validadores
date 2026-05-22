# *Ingress* da Seleção de Validadores *on chain*

## Princípios do *Ingress* seleção de validadores *on chain*<a id="principios"></a>

Para alterar o mecanismo de seleção de validadores na RBB, é necessário realizar uma [transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods). Essa transição é equivalente a um *hard fork* na rede. Para evitarmos novos *hard forks* em possíveis atualizações da lógica da seleção de validadores *on chain*, separamos a lógica da seleção do ponto de acesso do Besu. Assim, podemos manter um ponto de acesso fixo, enquanto fazemos alterações na lógica do mecanismo de seleção, evitando novos *hard forks*.

O *Ingress* da seleção de validadores é um contrato que atua como uma fachada para o Besu. Ele não deve implementar a lógica de seleção de validadores, mas manter o registro do endereço do contrato que implementa a lógica e fazer o redirecionamento da chamada do Besu para o contrato de lógica.

O objetivo é prover um mecanismo que permite a atualização da lógica de seleção de validadores sem implicar em um *hard fork* na rede.

## USSVI01 - Usuário da RBB implanta e inicializa código do Ingress da seleção de validadores<a id="ussvi01"></a>

## USSVI02 - Besu consulta validadores operacionais para execução do algoritmo de consenso<a id="ussv02"></a>

## USSVI03 - Governança atualiza o endereço do contrato de seleção de validadores<a id="ussvi03"></a>

## USSVI04 - Governança remove o endereço do contrato de seleção de validadores<a id="ussvi04"></a>

## USSVI05 - Governança atualiza o endereço do contrato de Admin<a id="ussvi05"></a>

## USSVI06 - Governança remove o endereço do contrato de Admin<a id="ussvi06"></a>

## USSVI07 - Usuário da RBB consulta endereços registrados<a id="ussvi07"></a>
