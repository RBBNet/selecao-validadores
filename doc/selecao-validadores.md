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
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores: `blocksBetweenSelection`.
      1. Esse valor deve ser maior ou igual a 1.
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `blocksWithoutProposeThreshold`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção da lista validadores operacionais.
      2. Esse limite deve ser maior ou igual ao número de validadores elegíveis.
4. Os validadores informados são adicionados às listas de validadores elegíveis e de validadores operacionais.
5. A qualquer momento, todos os validadores da lista de validadores operacionais devem estar contidos também na lista de validadores elegíveis.
6. A seleção de validadores terá dois modos de operação: `Manual` e `Automatic`.
   1. No momento da implantação do código, o modo de operação será ajustado para `Manual`.
   2. No modo `Manual` somente ocorrerão modificações nas listas de validadores (operacionais e elegíveis) através de ação humana.
   3. No modo `Automatic` o código poderá por selecionar e decidir remover automaticamente validadores da lista de validadores operacionais.

Dúvidas:

- Deveríamos colocar critérios adicionais para a lista de validadores (Ex.: Têm que estar permissionados, têm que estar ativos, apenas 1 por organização, etc.)? Acho que não...
  - A depender dos critérios, talvez tenhamos que receber as chaves públicas e não os endereços.
  - (Rayan) Acho que sim, estar permissionado (com checagem onchain via `NodeRulesV2`).
- As variáveis `blocksBetweenSelection` e `blocksWithoutProposeThreshold` são diferentes mesmo? O algoritmo deve ficar mais complexo, creio. Por outro lado, é possível ser mais responsivo a quedas que ultrapassariam as fronteiras do intervalo, se o parâmetro fosse um só.
  - (Rayan) Duas variáveis torna o comportamento da seleção mais customizável e facilita alterações neste comportamento depois (se necessário). Mas também dificulta o operacional de gerir o contrato e aumenta as chances de erro humano. Para contornar isso, podemos definir uma função que alterar o valor das duas variáveis e garantir que elas sejam iguais. Mesmo que tenhamos duas variáveis, se elas tiverem sempre o mesmo valor, o contrato vai se comportar como se só houvesse uma variável.

## USSCxx - Besu consulta validadores operacionais para execução do algoritmo de consenso

Critérios de aceitação:

1. Qualquer conta ou o Besu pode consultar a lista de validadores operacionais.
2. A lista de validadores operacionais é retornada.

## USSCxx - Usuário da RBB consulta validadores elegíveis para saber quem pode vir a participar do consenso

Critérios de aceitaçao:

1. Qualquer conta pode consultar a lista de validadores elegíveis.
2. A lista de validadores elegíveis é retornada.

## USSCxx - Governança altera modo de operação da seleção de validadores

Critérios de aceitação:

1. Somente o processo de governança pode realizar a alteração.
2. A governança deve informar o novo modo de operação.
3. Caso o modo de operação selecionado seja `Manual`:
   1. O modo de operação é ajustado para `Manual`.
4. Caso o modo de operação selecionado seja `Automatic`:
   1. O modo de operação é ajustado para `Automatic`.
   2. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
5. Um evento é emitido, registrando:
   1. O modo selecionado.

Dúvidas:
- Devemos sinalizar a existência de dois modos? Ou devemos apenas indicar que a seleção automática deve feita? Afinal, mesmo no modo automático as ações manuais podem ser realizadas.


## USSCxx - Partícipe executa monitoração para manutenção da lista de validadores operacionais

Critérios de aceitação:

1. Qualquer conta pode acionar a monitoração.
2. A monitoração deve emitir um evento indicando sua execução.
3. Caso o modo de operação seja `Automatic` e a monitoração ainda não tenha sido executada para o bloco atual:
   1. A monitoração registra sua execução para o bloco atual.
   2. A monitoração contabiliza o bloco atual para o validador que o produziu.
   3. Caso seja o momento de selecionar validadores, conforme parâmetro `blocksBetweenSelection`:
      1. Verifica-se, para cada validador operacional, se ele está a mais de `blocksWithoutProposeThreshold` blocos sem propor bloco.
         1. Validadores nesta condição devem ser pré-selecionados para remoção do consenso.
      2. Para cada validador pré-selecionado para remoção:
         1. É verificado se ao menos 4 validadores permanecerão na lista de validadores operacionais após a exclusão do validador pré-selecionado.
         2. Caso afirmativo:
            1. A monitoração emite evento indicando o validador operacional a ser removido.
            2. O validador pré-selecionado é removido como validador operacional, sendo mantido como validador elegível.
         3. Caso negativo, o validador pré-selecionado é **mantido** como validador operacional.
      3. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
      4. A monitoração emite um evento indicando a realização da seleção automática de validadores informando a lista de validadores operacionais resultante.
   4. Caso contrário, a monitoração encerra.
5. Caso contrário, a monitoração encerra.

Dúvidas:

1. Vamos deixar a função de monitoração "aberta" para qualquer conta executar? Valeria restringir o acesso para evitar possíveis ataques de DOS?
   - A princípio esse ataque (gasto excessivo de *gas*) estará presente também através da chamada a outros contratos. Logo, não parece valer a pena implementar controle específico para esse caso.
2. No evento de seleção de validadores, seria interessante acrescentar alguma informação, como a lista de validadores selecionados ou ao menos a quantidade de validadores selecionados?
   - A princípio, para fins de transparência e auditabilidade, sim. Caso se verifique que isso acarreta em alto consumo de *gas* isso poderá ser revisto.
3. Deve-se remover somente 1 validador a cada seleção? Isso dá mais chance de validadores eventualmente se recuperarem. Por outro lado, torna mais lenta a convergência da rede para seu valor nominal de 4s para produção de blocos.
   - Decidiu-se priorizar a convergência do consenso para o valor nominal de produção de blocos, removendo-se todos os validadores inoperantes possíveis de uma vez.
- Como podemos proteger a seleção de validadores de falhas mais amplas do envio de transações de monitoração (Ex.: Apenas um ou poucos partícipes enviando transações em frequência muito baixa), de forma a não causar remoção equivocada de validadores em massa?
   - (Glads) Poderia guardar o número de blocos para os quais foi realizada uma chamada com sucesso no intervalo de avaliação. Se não tiver o suficiente, não executa a seleção.
   - (Glads) Um problema similar, mas menos grave é que, se há validadores fora, o intervalo aumenta de verificação aumenta. No azar de estarem em sequência, pode demorar um bocado, principalmente se o número de validadores aumentar. Por exemplo, se tivéssemos 21 validadores, poderiam cair 6. Isso dá uns bons minutos! Probabilidade de os seis caírem no mesmo intervalo talvez seja pequeno.
   - (Rayan) Acho que pode ser tratado offchain, com mecanismos de redundância. Já vamos ter pelo menos 9 casas fazendo o monitoramento (sendo que só precisamos de uma para funcionar), daí, em cada casa, podemos ter várias instâncias do componente responsável pelo envio de transações. Podemos pensar também em um mecanismo de incentivos, talvez relacionado ao gas na rede, algo como "Se você fez mais transações de monitoramento, então pode consumir mais gas na rede".
- O evento de monitoração deve ocorrer a toda transação? Seu registro facilita a auditoria para fins de OLA. Porém essa auditoria poderia ser feita de outras formas.


## USSCxx - Administrador ou Governança re-adiciona validador elegível como validador operacional para tornar consenso da rede mais resiliente

Critérios de aceitação:

1. Somente podem executar essa função:
   1. Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas.
   2. A Governança.
2. O endereço do nó a ser re-adicionado deve ser informado.
3. O nó informado **não** deve estar na lista de validadores operacionais.
4. O nó informado deve estar na lista de validadores elegíveis.
5. Administradores somente podem re-adicionar nós vinculados às suas organizações.
6. A governança pode re-adicionar nós de quaisquer organizações.
7. O nó é adicionado à lista de validadores operacionais.
8. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

1. Na emissão do evento, seria o caso de identificar a organização que efetuou a ação?
  - Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada.
- E se o nó é adicionado justamente no momento de realizar nova seleção de validadores (e será avaliado como tendo 0 blocos)?
  - (Glads) Uma opção seria só realmente incluí-lo no consenso no momento da seleção de validadores. Seriam três status possíveis: operacional, em espera e fora do consenso (outros nomes, talvez).
  - (Claude) Complementando: ao re-adicionar um validador, seu `lastBlockProposedBy` permanecerá com o valor antigo (ou zero se nunca propôs). Na próxima seleção, ele será imediatamente considerado inativo e removido. É preciso inicializar `lastBlockProposedBy` ao re-adicionar (ex.: com `block.number`) ou adotar o estado intermediário que o Glads sugeriu.
  - (Rayan) Vai depender da ordem das transações no bloco. Se a transação de monitoramento vier antes, não haverá problema. Se vier depois, o validador será incluído como operacional e removido logo em seguida. Podemos o marcar como "em espera", como o Glads sugeriu, e o adicionar no próximo bloco (via função de monitoramento).
  - (JALOP) Criar lista de "validadores candidatos", que seriam adicionados ao consenso no momento da seleção?
    - Essa lista também teria que ser usada na história de adição de nós elegíveis (abaixo).
    - Ou então criar uma lista de "validadores café-com-leite", que já seriam operacionais, porém não poderiam ser pré-selecionados para remoção numa primeira seleção automática.
- (Glads) É um pouco estranho imaginar que o sujeito pode incluir no consenso um nó que nem permissionado está, né? Mas acho que "integrar" demais pode aumentar demais a complexidade...
  - (JALOP) Dúvida semelhante à que coloquei na história abaixo - "Governança adiciona validador elegível". Mas acho que, se quisermos controle, vale fazer isso nessa outra história que mencionei, na gestão de validadores **elegíveis**. Para gestão de validadores operacionais, talvez não precise.
  - (Rayan) Acho que a depender da complexidade, vale a pena. Se não me engano, neste caso impactaria também a usabilidade o usuário (administrador, neste caso) teria que usar o `enodeHigh` e `enodeLow` para interagir com o contrato, ao invés do endereço, já que o `NodeRulesV2` trata apenas dos enodes.

## USSCxx - Administrador ou Governança remove validador operacional

Critérios de aceitação:

1. Somente podem executar essa função:
   1. Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas.
   2. A Governança.
2. O endereço do nó a ser removido deve ser informado.
3. O nó informado deve estar na lista de validadores operacionais.
4. Administradores somente podem remover nós vinculados às suas organizações.
5. A governança pode remover nós de quaisquer organizações.
6. O nó somente será removido se ao menos 4 validadores permanecerem na lista de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.
7. O nó é removido da lista de validadores operacionais.
8. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

1. Faz sentido implementar função para remoção de validador operacional?
   - Sim. A função pode ser usada em casos como de manutenção programada, onde o nó já vai ficar indisponível e, ao invés de esperar remoção via monitoramento, é possível remover o nó imediatamente.
2. Na emissão do evento, seria o caso de identificar a organização que efetuou a ação?
  - Até faz sentido no caso de um administrador efetuar a ação. Porém não faz sentido no caso da governança realizar a ação. Portanto, por simplificação, a informação da organização envolvida, não será registrada.

## USSCxx - Governança adiciona validador elegível

Critérios de aceitação:

1. Somente o processo de governança pode realizar a adição.
2. A governança deve informar o endereço do nó a ser adicionado.
3. O nó informado **não** deve estar na lista de validadores elegíveis.
4. O nó é adicionado à lista de validadores elegíveis.
5. O nó é adicionado à lista de validadores operacionais.
6. Caso o valor do parâmetro `blocksWithoutProposeThreshold` seja menor que a quantidade de validadores elegíveis, o parâmetro é atualizado para que seu valor seja igualado à quantidade de validadores elegíveis.
   1. Um evento é emitido, registrando:
      1. O valor do parâmetro `blocksBetweenSelection`, mesmo não tedo sido alterado.
      2. O valor do parâmetro `blocksWithoutProposeThreshold`.
7. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:

- Deveríamos colocar critérios adicionais para o novo nó (Ex.: tem que estar permissionado, tem que estar ativo, apenas 1 por organização, etc.)? Acho que não...
  - A depender dos critérios, talvez tenhamos que receber as chaves públicas e não os endereços.
  - Acho que podemos adicionar a verificação de permissionamento via `NodeRulesV2`.
- Atenção caso venhamos a optar pela lista de "validadores candidatos" ou "validadores café-com-leite".

## USSCxx - Governança remove validador elegível

Critérios de aceitação:

1. Somente o processo de governança pode realizar a remoção.
2. A governança deve informar o endereço do nó a ser removido.
3. O nó informado deve estar na lista de validadores elegíveis.
4. O nó é removido da lista de validadores operacionais, se estiver nessa lista.
   1. O nó somente será removido se ao menos 4 validadores permanecerem na lista de validadores operacionais após sua exclusão. Caso contrário a história é encerrada com erro.
5. O nó é removido da lista de validadores elegíveis.
6. Um evento é emitido, registrando:
   1. O endereço do nó.

Dúvidas:
- Seria o caso de flexibilizar a inclusão de validadores elegíveis sem obrigatoriamente torná-los operacionais ao mesmo tempo?

## USSCxx - Governança configura parâmetros de seleção automática de validadores

Critérios de aceitação:

1. Somente o processo de governança pode realizar esta configuração.
2. São informados os parâmetros:
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores: `blocksBetweenSelection`.
      1. Esse valor deve ser maior ou igual a 1.
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `blocksWithoutProposeThreshold`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção da lista validadores operacionais.
      2. Esse limite deve ser maior ou igual o número de validadores elegíveis.
3. Informações de produção de blocos pelos validadores são inicializadas e um novo ciclo de monitoração automática é iniciado.
4. Um evento é emitido, registrando:
   1. O valor do parâmetro `blocksBetweenSelection`.
   2. O valor do parâmetro `blocksWithoutProposeThreshold`.


## USSCxx - Governança atualiza o código *on chain* de seleção de validadores

Critérios de aceitação:

1. Somente o processo de governança pode realizar esta configuração.

Dúvidas:

- (Claude) Este requisito está muito enxuto. A implementação usa padrão UUPS (`UUPSUpgradeable`), o que seria bom mencionar. Além disso, poderia explicitar: (a) que a atualização requer deploy de nova implementação + chamada a `upgradeToAndCall`, (b) que a autorização é via `_authorizeUpgrade` restrita à governança, (c) se deve haver emissão de evento registrando a versão antiga e nova.
- (JALOP) Nessa história temos que decidir que mecanismo vamos querer utilizar para fazer eventuais [atualizações de código](https://ethereum.org/pt-br/developers/docs/smart-contracts/upgrading/#data-separation).
  - (Rayan) Inicialmente, adotamos o método 3 (seguindo esta documentação), mas com certeza vale a pena retomar essa conversa.
