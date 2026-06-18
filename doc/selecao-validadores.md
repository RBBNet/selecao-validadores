# Seleção de Validadores *on chain*

## Princípios da seleção de validadores *on chain*<a id="principios"></a>

A RBB realiza a produção de blocos através de consenso entre um conjunto pré-estabelecido de validadores, conforme protocolo [QBFT](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft). Conforme definido em seu arquivo [`genesis.json`](https://github.com/RBBNet/rbb/blob/master/artefatos/observer/genesis.json), a RBB foi inicializada com um conjunto de um único validador, utilizando a [forma de seleção de validadores](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) através de *block header*, tendo outros validadores sido adicionados e removidos posteriormente, através de [mecanismo proprietário](https://besu.hyperledger.org/private-networks/reference/api#qbft_proposevalidatorvote) do protocolo QBFT. Isto significa que, atualmente, a gestão do conjunto de validadores é feita através de API específica do Besu, *off chain*, de forma manual e sem transparência para um observador externo.

O objetivo de um mecanismo de seleção de validadores *on chain* é de tornar o processo de seleção automatizável, transparente e auditável. Automatizável pois o próprio código *on chain* poderá decidir quais validadores devem participar do consenso ou não. Transparente, pois os critérios definidos para a seleção serão, obrigatoriamente, os definidos pelo código *on chain*. Auditável, pois as ações realizadas pelo código estarão devidamente registradas *on chain*.

Os princípios para a seleção *on chain* são:

- Utilização da [seleção de validadores](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) através de *smart contract*.
- Implementação de *smart contract* para esse fim.
- O *smart contract* gerenciará 3 conjuntos de validadores:
  - **Validadores elegíveis** ao consenso. Somente poderão fazer parte desse conjunto validadores definidos pela [governança da RBB](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/Governance.sol).
  - **Validadores operacionais**, que efetivamente fazem parte do consenso. Somente poderão fazer parte desse conjunto validadores contidos no conjunto de validadores elegíveis.
  - **Validadores adicionados**, contendo validadores recém adicionados ao consenso. Somente poderão fazer parte desse conjunto validadores contidos no conjunto de validadores operacionais.
  - A qualquer momento, o conjunto de validadores operacionais deverá conter ao menos 1 validador.
- O *smart contract* terá dois modos de funcionamento:
  - **Manual**, onde a adição e remoção de validadores será feita de forma exclusivamente manual, através de ações da [governança](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/Governance.sol).
  - **Automático**, de acordo com critérios bem estabelecidos, o *smart contract* poderá decidir remover automaticamente validadores (operacionais) do consenso.
  - A qualquer momento, [administradores](https://github.com/RBBNet/Permissionamento/blob/main/gen02/doc/premissas.md#premissas) poderão efetuar adição e remoção de validadores operacionais de suas próprias organizações, desde que respeitadas as premissas estabelecidas (acima) para os conjuntos de validadores gerenciados.
- O *smart contract* possuirá parâmetros para seleção automática de validadores:
  - Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores. Define o tamanho de um **ciclo de monitoração automática**.
  - Limite de blocos tolerado para que um validador permaneça sem propor blocos.

## USSV01 - Usuário da RBB implanta e inicializa código da seleção de validadores *on chain* para permitir migração da seleção de validadores da rede de *block header* para *smart contract*<a id="ussv01"></a>

**Observações**:

- Esta história será executada uma única vez.
- É necessário vincular o código *on chain* da seleção de validadores ao permissionamento da RBB.
- Para que o código desta história seja efetivamente usado na rede, será necessários aplicar uma [transição no arquivo gênesis da rede](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#swap-validator-management-methods), de forma a alterar o [mecanismo de seleção de validadores do Besu](https://besu.hyperledger.org/private-networks/how-to/configure/consensus/qbft#add-and-remove-validators) de *block header* para *smart contract*. Isto **não** está contemplado nesta história.

Critérios de aceitação:

1. São informados os endereços dos *smart contracts* de permissionamento da RBB:
   1. Gestão de Administrador Master - [`AdminProxy`](https://github.com/RBBNet/Permissionamento/blob/main/gen01/contracts/AdminProxy.sol) (gen01)
   2. Gestão de contas - [`AccountRulesV2`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/AccountRulesV2.sol) (gen02)
   3. Gestão de nós - [`NodeRulesV2`](https://github.com/RBBNet/Permissionamento/blob/main/gen02/contracts/NodeRulesV2.sol) (gen02)
2. É informado um conjunto de endereços de nós validadores, para que sejam considerados no consenso da rede.
   1. Ao menos 1 validador deve ser informado.
3. São informados os parâmetros:
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores: `blocksBetweenSelection`.
      1. Esse valor deve ser maior ou igual a 1.
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `blocksWithoutProposeThreshold`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção do conjunto validadores operacionais.
      2. Esse limite deve ser maior ou igual ao número de validadores elegíveis.
4. Os validadores informados são adicionados aos conjuntos de validadores elegíveis e de validadores operacionais.
   1. O conjunto de validadores adicionados é inicializado vazio.
5. A qualquer momento, todos os validadores do conjunto de validadores operacionais devem estar contidos também no conjunto de validadores elegíveis.
6. A qualquer momento, todos os validadores do conjunto de validadores adicionados devem estar contidos também no conjunto de validadores operacionais.
7. A seleção de validadores terá dois modos de operação: `Manual` e `Automatic`.
   1. No momento da implantação do código, o modo de operação será ajustado para `Manual`.
   2. No modo `Manual` somente ocorrerão modificações nos conjuntos de validadores (operacionais, elegíveis e adicionados) através de ação humana.
   3. No modo `Automatic` o código poderá por selecionar e decidir remover automaticamente validadores do conjunto de validadores operacionais.

Dúvidas:

1. Deveríamos colocar critérios adicionais para validar o conjunto de validadores, como, por exemplo, verificar que estão devidamente permissionados, que estão ativos, que há apenas 1 por organização, etc?

- Seriam implementações possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos.

1. Ao invés de utilizar 2 parâmetros - `blocksBetweenSelection` e `blocksWithoutProposeThreshold` - seria o caso de utilizar apenas um para controlar o ciclo de monitoração? Com 2 parâmetros o algoritmo, apesar de mais flexível e responsivo (quedas que ultrapassem o ciclo), não fica mais complexo?

- Avaliou-se que a implementação com 2 parâmetros não fica muito mais complexa, podendo-se manter as vantagens desejadas. Caso quaisquer problemas de implementação sejam detectados na operação da monitoração durante a implementação e testes do *smart contract*, essa decisão poderá ser revista.

## USSV02 - Qualquer conta ou o Besu consulta validadores operacionais para execução do algoritmo de consenso<a id="ussv02"></a>

Critérios de aceitação:

1. Qualquer conta ou o Besu pode consultar o conjunto de validadores operacionais.
2. O conjunto de validadores operacionais é retornado.

## USSV03 - Usuário da RBB consulta validadores elegíveis para saber quem pode vir a participar do consenso<a id="ussv03"></a>

Critérios de aceitação:

1. Qualquer conta pode consultar o conjunto de validadores elegíveis.
2. O conjunto de validadores elegíveis é retornado.

## USSV04 - Governança altera modo de operação da seleção de validadores<a id="ussv04"></a>

Critérios de aceitação:

1. Somente a governança pode realizar a alteração.
2. A governança deve informar o novo modo de operação.
3. Caso o modo de operação selecionado seja `Manual`:
   1. O modo de operação é ajustado para `Manual`.
4. Caso o modo de operação selecionado seja `Automatic`:
   1. O modo de operação é ajustado para `Automatic`.
   2. O conjunto de validadores adicionados é esvaziado.
   3. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
5. Um evento é emitido, registrando:
   1. O modo selecionado.

Dúvidas:

1. Devemos manter a semântica de dois modos ou devemos apenas indicar quando a seleção automática estiver ligada ou desligada? Afinal, mesmo no modo automático as ações manuais podem ser realizadas.
   - Avaliou-se que, do ponto de vista de implementação, há pouca diferença entre usar "uma variável de estado" ou "uma *flag* de funcionalidade". Por outro lado, a semântica de "estado de operação" pareceu ser apropriada para representar o funcionamento do *smart contract* e, portanto, foi mantida.

## USSV05 - Partícipe executa monitoração para manutenção do conjunto de validadores operacionais<a id="ussv05"></a>

Critérios de aceitação:

1. Qualquer conta pode acionar a monitoração.
2. A monitoração deve emitir um evento indicando sua execução.
3. Caso o modo de operação seja `Automatic` e a monitoração ainda não tenha sido executada para o bloco atual:
   1. A monitoração registra sua execução para o bloco atual.
   2. A monitoração contabiliza o bloco atual para o validador que o produziu.
   3. Caso seja o momento de selecionar validadores, conforme parâmetro `blocksBetweenSelection`:
      1. Verifica-se, para cada validador operacional, se ele está a mais de `blocksWithoutProposeThreshold` blocos sem propor bloco.
         1. Validadores nesta condição devem ser pré-selecionados para remoção do consenso.
      2. Para cada validador pré-selecionado para remoção, verifica-se se o mesmo está contido no conjunto de validadores adicionados:
         1. Caso afirmativo, o validador pré-selecionado é **mantido** como validador operacional.
         2. Caso negativo, verifica-se se ao menos 4 validadores permanecerão no conjunto de validadores operacionais após a exclusão do validador pré-selecionado:
            1. Caso afirmativo:
               1. A monitoração emite evento indicando o validador operacional a ser removido.
               2. O validador pré-selecionado é removido como validador operacional, sendo mantido como validador elegível.
            2. Caso negativo, o validador pré-selecionado é **mantido** como validador operacional.
      3. O conjunto de validadores adicionados é esvaziado.
      4. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
      5. A monitoração emite um evento indicando a realização da seleção automática de validadores informando o conjunto de validadores operacionais resultante.
   4. Caso contrário, a monitoração encerra.
4. Caso contrário, a monitoração encerra.

Dúvidas:

1. Vamos deixar a função de monitoração "aberta" para qualquer conta executar? Valeria restringir o acesso para evitar possíveis ataques de DOS?
   - A princípio esse ataque (gasto excessivo de *gas*) estará presente também através da chamada a outros contratos. Logo, não parece valer a pena implementar controle específico para esse caso.
2. No evento de seleção de validadores, seria interessante acrescentar alguma informação, como o conjunto de validadores selecionados ou ao menos a quantidade de validadores selecionados?
   - A princípio, para fins de transparência e auditabilidade, sim. Caso se verifique que isso acarreta em alto consumo de *gas* isso poderá ser revisto.
3. Deve-se remover somente 1 validador a cada seleção? Isso dá mais chance de validadores eventualmente se recuperarem. Por outro lado, torna mais lenta a convergência da rede para seu valor nominal de 4s para produção de blocos.
   - Decidiu-se priorizar a convergência do consenso para o valor nominal de produção de blocos, removendo-se todos os validadores inoperantes possíveis de uma vez.
4. Como podemos proteger a seleção de validadores de falhas mais amplas do envio de transações de monitoração? Por exemplo, se todos os partícipes utilizarem uma mesma implementação para envio de transações de monitoração que se torne vulnerável a um ataque que a torne inoperante (*zero-day attack*) e algum partícipe, isoladamente, consiga corrigir a vulnerabilidade reabilitando a monitoração de forma pontual, distorcendo os dados de monitoração e levando a seleção à remoção equivocada de validadores em massa.
   - Apesar de possível, o cenário de falha "catastrófica" da monitoração foi avaliado como pouco provável.
   - Chegou-se a avaliar a implementação de mecanismo que quantificasse a quantidade de blocos monitorados, de forma que a seleção automática só ocorresse caso uma quantidade mínima de blocos tenha sido monitorado. Porém, verificou-se que tal implementação levaria a dilema adicional: o mecanismo teria que optar entre proteger a rede de excluir equivocadamente validadores funcionais ou de impedir a exclusão de validadores inoperantes.
   - Dada a avaliação de baixa probabilidade de ocorrência de falha generalizada, do aumento de complexidade de implementação e da salva-guarda de que, mesmo em caso de falha generalizada, no pior caso, a rede se manter funcionando com 4 validadores, optou-se por não implementar mecanismos de proteção contra falhas de monitoração.
5. O evento de monitoração deve ser emitido para todas as transações ou somente no caso de ser a primeira transação de monitoração do bloco? Afinal, o registro de um evento facilitaria a auditoria (para fins de OLA), porém causaria um gasto de *gas* adicional e a auditoria poderia ser feita de outras formas.
   - De forma conceitual, a emissão do evento para toda transação parece mais adequado. Portanto, essa será a definição inicial de requisito, sendo cabíveis eventuais reavaliações no caso de testes (em tempo de desenvolvimento) comprovarem que o gasto de *gas* atinja níveis indesejados.

## USSV06 - Administrador ou Governança re-adiciona validador elegível como validador operacional para tornar consenso da rede mais resiliente<a id="ussv06"></a>

Critérios de aceitação:

1. Somente podem executar essa função:
   1. Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas.
   2. A Governança.
2. O endereço do nó a ser re-adicionado deve ser informado.
3. O nó informado **não** deve estar no conjunto de validadores operacionais.
4. O nó informado deve estar no conjunto de validadores elegíveis.
5. Administradores somente podem re-adicionar nós vinculados às suas organizações.
6. A governança pode re-adicionar nós de quaisquer organizações.
7. O nó é adicionado ao conjunto de validadores operacionais.
8. O nó é adicionado ao conjunto de validadores adicionados.
9. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

1. Na emissão do evento, seria o caso de identificar a organização que efetuou a ação?

- Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada.

1. Como garantir que um validador adicionado ao fim de um ciclo de monitoração automática não seja automaticamente removido por não ter tido tempo de produzir blocos?
   - Foi adotada a solução do conjunto de validadores adicionados.
2. Deveríamos colocar critérios adicionais para validar o endereço adicionado, como, por exemplo, verificar que está devidamente permissionado ou que está ativo?

- Várias implementações seriam possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos.

## USSV07 - Administrador ou Governança remove validador operacional<a id="ussv07"></a>

Critérios de aceitação:

1. Somente podem executar essa função:
   1. Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas.
   2. A Governança.
2. O endereço do nó a ser removido deve ser informado.
3. O nó informado deve estar no conjunto de validadores operacionais.
4. Administradores somente podem remover nós vinculados às suas organizações.
5. A governança pode remover nós de quaisquer organizações.
6. O nó somente será removido se ao menos 1 validador. permanecerem no conjunto de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.
7. O nó é removido do conjunto de validadores operacionais.
8. O nó é removido do conjunto de validadores adicionados, caso faça parte desse conjunto.
9. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

1. Faz sentido implementar função para remoção de validador operacional?
   - Sim. A função pode ser usada em casos como de manutenção programada, onde o nó já vai ficar indisponível e, ao invés de esperar remoção via monitoramento, é possível remover o nó imediatamente.
2. Na emissão do evento, seria o caso de identificar a organização que efetuou a ação?

- Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada.

## USSV08 - Governança adiciona validador elegível<a id="ussv08"></a>

Critérios de aceitação:

1. Somente a governança pode realizar a adição.
2. A governança deve informar o endereço do nó a ser adicionado e se o nó deve automaticamente também ser adicionado como validador operacional.
3. O nó informado **não** deve estar no conjunto de validadores elegíveis.
4. O nó é adicionado ao conjunto de validadores elegíveis.
5. Caso seja indicado que o nó deve ser automaticamente adicionado como validador operacional:
   1. O nó é adicionado ao conjunto de validadores operacionais.
   2. O nó é adicionado ao conjunto de validadores adicionados.
6. Caso o valor do parâmetro `blocksWithoutProposeThreshold` seja menor que a quantidade de validadores elegíveis, o parâmetro é atualizado para que seu valor seja igualado à quantidade de validadores elegíveis.
   1. Um evento é emitido, registrando:
      1. O valor do parâmetro `blocksBetweenSelection`, mesmo não tendo sido alterado.
      2. O valor do parâmetro `blocksWithoutProposeThreshold`.
7. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

1. Como garantir que um validador adicionado ao fim de um ciclo de monitoração automática não seja automaticamente removido por não ter tido tempo de produzir blocos?
   - Foi adotada a solução do conjunto de validadores adicionados.
2. Deveríamos colocar critérios adicionais para validar o endereço adicionado, como, por exemplo, verificar que está devidamente permissionado ou que está ativo?

- Várias implementações seriam possíveis, porém gerariam grande acoplamento com outros *smart contracts* e aumentariam a complexidade de implementação. Avaliou-se que tais desvantagens não compensariam a vantagem de minimizar eventuais erros operacionais de se cadastrar endereços inválidos.

1. É o caso de se flexibilizar a inclusão de validadores elegíveis sem obrigatoriamente torná-los operacionais ao mesmo tempo? Atualmente o processo de governança, sempre que decide pela inclusão de um novo validador ao consenso da rede, o faz de maneira imediata e efetiva.

- Avaliou-se que, apesar de pouco provável que a flexibilidade seja necessária, sua implementação é simples e permite que possíveis alterações futuras de processo de governança sejam implementadas sem que sejam necessário atualizar o *smart contract*.

## USSV09 - Governança remove validador elegível<a id="ussv09"></a>

Critérios de aceitação:

1. Somente a governança pode realizar a remoção.
2. A governança deve informar o endereço do nó a ser removido.
3. O nó informado deve estar no conjunto de validadores elegíveis.
4. O nó é removido do conjunto de validadores operacionais, se estiver nesse conjunto.
   1. O nó somente será removido se ao menos 1 validador permanecer no conjunto de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.
5. O nó é removido do conjunto de validadores adicionados, caso faça parte desse conjunto.
6. O nó é removido do conjunto de validadores elegíveis.
7. Informações de controle referente ao validador removido, utilizadas no ciclo de monitoração, são apagadas.
8. Um evento é emitido, registrando:
   1. O endereço do nó.

## USSV10 - Governança configura parâmetros de seleção automática de validadores<a id="ussv10"></a>

Critérios de aceitação:

1. Somente a governança pode realizar esta configuração.
2. São informados os parâmetros:
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores: `blocksBetweenSelection`.
      1. Esse valor deve ser maior ou igual a 1.
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `blocksWithoutProposeThreshold`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção do conjunto validadores operacionais.
      2. Esse limite deve ser maior ou igual o número de validadores elegíveis.
3. O conjunto de validadores adicionados é esvaziado.
4. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
5. Um evento é emitido, registrando:
   1. O valor do parâmetro `blocksBetweenSelection`.
   2. O valor do parâmetro `blocksWithoutProposeThreshold`.

## USSV11 - Governança atualiza o código *on chain* de seleção de validadores<a id="ussv11"></a>

**Observações**:

- O novo contrato de seleção de validadores já deve ter sido implantado.
- O novo contrato de seleção de validadores deve implementar a função `getValidators()`.

Critérios de aceitação:

1. Somente a governança pode realizar esta configuração.
2. Governança informa o endereço do novo contrato de seleção de validadores.
   1. Este endereço deve ser diferente do endereço corrente e deve ser não nulo.
   2. É validado que este endereço implementa a função `getValidators()`.
      1. Caso contrário, a história é encerrada com erro.
   3. É validado que este endereço retorna uma lista de tamanho pelo menos 1 quando `getValidators()` é invocada.
      1. Caso contrário, a história é encerrada com erro.
3. O endereço do contrato de seleção validadores corrente é atualizado.
4. Um evento é emitido, registrando:
   1. O endereço do novo contrato de seleção de validadores.

Dúvidas:

- Considerando esta [documentação](https://ethereum.org/pt-br/developers/docs/smart-contracts/upgrading/), fizemos as seguintes considerações para a escolha do método de atualização ideal para o projeto:
  - O método de atualização não deve gerar uma *transition* (*hard-fork*) na rede.
  - Atualizações de contrato devem ser eventos que ocorrem com baixa frequência, assim, o custo de gas associado ao método de atualização tem baixa relevância para a escolha do método.
  - Há a preferencia por métodos de atualização mais simples, buscando facilitar revisão e implementação do contrato e sua operação.
  - Dados estes pontos, optou-se pela abordagem ilustrada [aqui](img/validator-selection.svg). Entendemos que está abordagem escolhida não se encaixa de forma plena em nenhum dos métodos da documentação citada.
- Devemos implementar uma validação para garantir que o novo contrato de seleção de validadores implemente a função `getValidators()`?
  - Sim, entendemos que o custo de implementação é baixo e pode mitigar erros de operação.
  - Além de validar a assinatura da função, também vamos validar o número de validadores elegíveis retornado pela função e garantir que seja maior ou igual a 1. Entendemos que o custo de implementação dessa validação é baixo e pode impedir travamentos no consenso da rede (< 1 validador), em um eventual caso de reponteiramento errado.
- (Rayan) Devemos validar se a lista retornada pela função `getValidators()` é um subconjunto do conjunto de validadores elegíveis? Poderíamos verificar via contratos de Permissionamento.

## USSV12 - Usuário da RBB consulta se o contrato de seleção de validadores implementa uma interface especificada<a id="ussv12"></a>

**Observações**:

- É recomendado que seja implementado seguindo o [ERC-165](https://eips.ethereum.org/EIPS/eip-165)

Critérios de aceitação:

1. Qualquer conta pode realizar essa história.
2. Usuário da RBB informa um [`interfaceId`](https://docs.soliditylang.org/en/latest/units-and-global-variables.html#type-information).
3. É verificado se o contrato implementa a interface que possui o `interfaceId` correspondente.
   1. Se implementa, então é retornado `true`.
   2. Caso contrário, então é retornado `false`.
