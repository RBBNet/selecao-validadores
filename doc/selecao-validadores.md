# Seleção de Validadores *on chain*

## USSCxx - Usuário da RBB implanta e inicializa código da seleção de validadores *on chain* para permitir migração da seleção de validadores da rede de *block header* para *smart contract*

**Observações**:
- Esta história será executada uma única vez.
- É necessário vincular o código *on chain* da seleção de validadores ao permissionamento da RBB.
- Para que o código desta história seja efetivamente usado na rede, será necessários aplicar uma [transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods), de forma a alterar o [mecanismo de seleção de validadores do Besu](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) de *block header* para *smart contract*. Isto **não** está contemplado nesta história.

Critérios de aceitação:
1. São informados os endereços dos *smart contracts* de permissionamento da RBB:
   1. Gestão de Administrador Master - [`AdminProxy`](https://github.com/RBBNet/Permissionamento/blob/main/gen01/contracts/AdminProxy.sol) (gen01)
   2. Gestão de contas - [`AccountRulesV2`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/AccountRulesV2.sol) (gen02)
   3. Gestão de nós - [`NodeRulesV2`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/NodeRulesV2.sol) (gen02)
2. É informada uma lista de endereços de nós validadores, para que sejam considerados no consenso da rede.
   1. Ao menos 4 validadores devem ser informados.
3. São informados os parâmetros:
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores:  `IntervaloBlocosSelecao`
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `LimiteBlocosSemProposicao`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção da lista validadores operacionais.
   3. Próximo bloco para realização da seleção de validadores: `proximoBlocoSelecao`
4. Os validadores informados são adicionados às listas de validadores elegíveis e de validadores operacionais.
5. A qualquer momento, todos os validadores da lista de validadores operacionais devem estar contidos também na lista de validadores elegíveis.

Dúvidas:
- Deveríamos colocar critérios adicionais para a lista de validadores (Ex.: Têm que estar permissionados, têm que estar ativos, apenas 1 por organização, etc.)? Acho que não...
  - A depender dos critérios, talvez tenhamos que receber as chaves públicas e não os endereços.
- O parâmetro `proximoBlocoSelecao` deve existir (e ser informado) ou deveria apenas ser uma variável de estado interna (e ser calculado)?


## USSCxx - Besu consulta validadores operacionais para execução do algoritmo de consenso

Critérios de aceitaçao:
1. Qualquer conta ou o Besu pode consultar a lista de validadores operacionais.
2. A lista de validadores operacionais é retornada.


## USSCxx - Partícipe executa monitoração para manutenção da lista de validadores operacionais

Critérios de aceitação:
1. Qualquer conta pode acionar a monitoração.
2. A monitoração deve emitir um evento indicando sua execução.
3. A monitoração deve contabilizar o bloco atual para o validador que o produziu.
4. Caso seja o momento de selecionar validadores, conforme parâmetro `IntervaloBlocosSelecao`:
   1. A monitoração emite um evento indicando a realização da seleção de validadores.
   2. Verifica-se, para cada validador operacional, se ele está a mais de `LimiteBlocosSemProposicao` blocos sem propor bloco.
      1. Validadores nesta condição devem ser pré-selecionados para remoção do consenso.
   3. Para cada validador pré-selecionado para remoção:
      1. É verificado se ao menos 4 validadores permanecerão na lista de validadores operacionais após a exclusão do validador pré-selecionado.
      2. Caso afirmativo:
         1. A monitoração emite evento indicando o validador operacional a ser removido.
         2. O validador pré-selecionado é removido como validador operacional, sendo mantido como validador elegível.
      3. Caso negativo, o validador pré-selecionado é **mantido** como validador operacional.
5. Caso contrário, a monitoração encerra.

Dúvidas:
1. Vamos deixar a função de monitoração "aberta" para qualquer conta executar? Valeria restringir o acesso para evitar possíveis ataques de DOS?
2. No evento de seleção de validadores, seria interessante acrescentar alguma informação, como a lista de validadores selecionados ou ao menos a quantidade de validadores selecionados?
3. Como podemos proteger a seleção de validadores de falhas mais amplas do envio de transações de monitoração (Ex.: Apenas um ou poucos partícipes enviando transações em frequência muito baixa), de forma a não causar remoção equivocada de validadores em massa?


## USSCxx - Administrador re-adiciona validador elegível como validador operacional para tornar consenso da rede mais resiliente

Critérios de aceitação:
1. Somente Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas, podem executar essa função.
2. O administrador deve informar o endereço do nó a ser re-adicionado.
3. O nó informado **não** deve estar na lista de validadores operacionais.
4. O nó informado deve estar na lista de validadores elegíveis.
5. O administrador somente pode re-adcionar nós vinculados à sua organização.
6. O nó é adicionado à lista de validadores operacionais.
7. Um evento é emitido, registrando:
   1. O endereço do nó
   2. O identificador da organização

Dúvidas:
- E se o nó é adicionado justamente no momento de realizar nova seleção de validadores (e será avaliado como tendo 0 blocos)?


## USSCxx - Administrador remove validador operacional

Critérios de aceitação:
1. Somente Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas, podem executar essa função.
2. O administrador deve informar o endereço do nó a ser removido.
3. O nó informado deve estar na lista de validadores operacionais.
4. O administrador somente pode remover nós vinculados à sua organização.
5. O nó é removido da lista de validadores operacionais.
6. Um evento é emitido, registrando:
   1. O endereço do nó
   2. O identificador da organização


## USSCxx - Governança adiciona validador elegível

Critérios de aceitação:
1. Somente o processo de governança pode realizar a adição.
2. A governança deve informar o endereço do nó a ser adicionado.
3. O nó informado **não** deve estar na lista de validadores elegíveis.
4. O nó é adicionado à lista de validadores elegíveis.
5. O nó é adicionado à lista de validadores operacionais.
6. Um evento é emitido, registrando:
   1. O endereço do nó

Dúvidas:
- Deveríamos colocar critérios adicionais para o novo nó (Ex.: tem que estar permissionado, tem que estar ativo, apenas 1 por organização, etc.)? Acho que não...
  - A depender dos critérios, talvez tenhamos que receber as chaves públicas e não os endereços.


## USSCxx - Governança remove validador elegível

Critérios de aceitação:
1. Somente o processo de governança pode realizar a remoção.
2. A governança deve informar o endereço do nó a ser removido.
3. O nó informado deve estar na lista de validadores elegíveis.
4. O nó é removido da lista de validadores elegíveis.
5. O nó é removido da lista de validadores operacionais, se estiver nessa lista.
6. Um evento é emitido, registrando:
   1. O endereço do nó


## USSCxx - Governança configura parâmetro x

Critérios de aceitação:
1. Somente o processo de governança pode realizar esta configuração.


## USSCxx - Governança atualiza o código *on chain* de seleção de validadores

Critérios de aceitação:
1. Somente o processo de governança pode realizar esta configuração.
