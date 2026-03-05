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
   1. Intervalo (quantidade) de blocos que o *smart contract* aguardará para realizar nova avaliação e seleção de validadores:  `blocksBetweenSelection`
   2. Limite de blocos tolerado para que um validador permaneça sem propor blocos: `blocksWithoutProposeThreshold`.
      1. Acima desse limite o validador deverá ser pré-selecionado para remoção da lista validadores operacionais.
   3. Próximo bloco para realização da seleção de validadores: `nextSelectionBlock`
4. Os validadores informados são adicionados às listas de validadores elegíveis e de validadores operacionais.
   - (Rayan) Temos que definir como será o deploy. Como está no contrato atualmente, os validadores informados só são adicionados na lista de validadores elegíveis e são adicionados a lista dos operacionais pela função de monitoramento.
5. A qualquer momento, todos os validadores da lista de validadores operacionais devem estar contidos também na lista de validadores elegíveis.

Dúvidas:

- Deveríamos colocar critérios adicionais para a lista de validadores (Ex.: Têm que estar permissionados, têm que estar ativos, apenas 1 por organização, etc.)? Acho que não...
  - A depender dos critérios, talvez tenhamos que receber as chaves públicas e não os endereços.
  - (Rayan) Acho que sim, estar permissionado (com checagem onchain via `NodeRulesV2`).
- O parâmetro `nextSelectionBlock` deve existir (e ser informado) ou deveria apenas ser uma variável de estado interna (e ser calculado)?
  - (Glads) Apesar do nome, entendi que essa é a variável que (pelo menos, no início) define a partir de que bloco o contrato efetivamente começa a valer. Se for isso, acho que ele deveria ser preenchido pela Governança a qualquer momento, após o deploy. Isso porque sincronizar a transition do genesis.json com o smart contract pode ser bem complicado.
    - (JALOP) De fato, se ajustado no construtor, funciona como você está falando. Mas, [posteriormente, é usado para definir os intervalos de seleção](https://github.com/RBBNet/selecao-validadores/blob/feature/bdd-features/src/ValidatorSelection.sol#L102). Então, seria o caso de manter esse parâmetro, né?
    - (Rayan) É isso mesmo. Definido no deploy, marca o início "oficial" do contrato. Mas que também pode ser alterado via Governança depois (via `setNextSelectionBlock`)
- As variáveis `blocksBetweenSelection` e `blocksWithoutProposeThreshold` são diferentes mesmo? O algoritmo deve ficar mais complexo, creio. Por outro lado, é possível ser mais responsivo a quedas que ultrapassariam as fronteiras do intervalo, se o parâmetro fosse um só.
  - (Rayan) Duas variáveis torna o comportamento da seleção mais customizável e facilita alterações neste comportamento depois (se necessário). Mas também dificulta o operacional de gerir o contrato e aumenta as chances de erro humano. Para contornar isso, podemos definir uma função que alterar o valor das duas variáveis e garantir que elas sejam iguais. Mesmo que tenhamos duas variáveis, se elas tiverem sempre o mesmo valor, o contrato vai se comportar como se só houvesse uma variável.

## USSCxx - Besu consulta validadores operacionais para execução do algoritmo de consenso

Critérios de aceitação:

1. Qualquer conta ou o Besu pode consultar a lista de validadores operacionais.
2. A lista de validadores operacionais é retornada.

Dúvidas:

- (Claude) O requisito não menciona consulta à lista de validadores elegíveis. Pode ser útil ter uma função equivalente para que a governança e os administradores possam verificar quem é elegível antes de tomar decisões.
  - (Rayan) Concordo, mas acho que isso seria uma outra história (que é a que está logo abaixo).

## USSCxx - Usuário da RBB consulta validadores elegíveis para saber quem pode vir a participar do consenso

Critérios de aceitaçao:

1. Qualquer conta ou o Besu pode consultar a lista de validadores elegíveis.
   - (Rayan) Não sei se o Besu consegue fazer isso ou se isso seria útil para ele de alguma forma.
2. A lista de validadores elegíveis é retornada.

## USSCxx - Partícipe executa monitoração para manutenção da lista de validadores operacionais

Critérios de aceitação:

1. Qualquer conta pode acionar a monitoração.
2. A monitoração deve emitir um evento indicando sua execução.
3. A monitoração deve contabilizar o bloco atual para o validador que o produziu.
4. Caso seja o momento de selecionar validadores, conforme parâmetro `blocksBetweenSelection`:
   1. A monitoração emite um evento indicando a realização da seleção de validadores.
   2. Verifica-se, para cada validador operacional, se ele está a mais de `blocksWithoutProposeThreshold` blocos sem propor bloco.
      1. Validadores nesta condição devem ser pré-selecionados para remoção do consenso.
   3. Para cada validador pré-selecionado para remoção:
      1. É verificado se ao menos 4 validadores permanecerão na lista de validadores operacionais após a exclusão do validador pré-selecionado.
         - (Rayan) Como está implementado agora, não é "do validador pré-selecionado" (no singular), mas sim do conjunto de validadores pré-selecionados. Ou são removidos todos os pré-selecionados, ou nenhum é removido.
      2. Caso afirmativo:
         1. A monitoração emite evento indicando o validador operacional a ser removido.
         2. O validador pré-selecionado é removido como validador operacional, sendo mantido como validador elegível.
            - (Rayan) Aqui também tratamos do conjunto pré-selecionado e não caso a caso.
      3. Caso negativo, o validador pré-selecionado é **mantido** como validador operacional.
         - (Rayan) Aqui também tratamos do conjunto pré-selecionado e não caso a caso.
5. Caso contrário, a monitoração encerra.

Dúvidas:

1. Vamos deixar a função de monitoração "aberta" para qualquer conta executar? Valeria restringir o acesso para evitar possíveis ataques de DOS?

- (Glads) O problema do ataque DoS se resolve em outra camada. O sujeito vai gastar o gas dele. Por outro lado, precisar, não precisa...

1. No evento de seleção de validadores, seria interessante acrescentar alguma informação, como a lista de validadores selecionados ou ao menos a quantidade de validadores selecionados?

- (Glads) A princípio, mostrar quem está participando do consenso o tempo todo é bom. Apenas se o consumo de gas for grande que eu acho que não vale, mas isso se vê mais para frente.
- (Rayan) Acho que sim, ainda há pouca emissão de eventos (e com pouca informação) no contrato. Com certeza é um ponto de melhoria.

1. Como podemos proteger a seleção de validadores de falhas mais amplas do envio de transações de monitoração (Ex.: Apenas um ou poucos partícipes enviando transações em frequência muito baixa), de forma a não causar remoção equivocada de validadores em massa?

- (Glads) Poderia guardar o número de blocos para os quais foi realizada uma chamada com sucesso no intervalo de avaliação. Se não tiver o suficiente, não executa a seleção.
- (Glads) Um problema similar, mas menos grave é que, se há validadores fora, o intervalo aumenta de verificação aumenta. No azar de estarem em sequência, pode demorar um bocado, principalmente se o número de validadores aumentar. Por exemplo, se tivéssemos 21 validadores, poderiam cair 6. Isso dá uns bons minutos! Probabilidade de os seis caírem no mesmo intervalo talvez seja pequeno.
- (Rayan) Acho que pode ser tratado offchain, com mecanismos de redundância. Já vamos ter pelo menos 9 casas fazendo o monitoramento (sendo que só precisamos de uma para funcionar), daí, em cada casa, podemos ter várias instâncias do componente responsável pelo envio de transações. Podemos pensar também em um mecanismo de incentivos, talvez relacionado ao gas na rede, algo como "Se você fez mais transações de monitoramento, então pode consumir mais gas na rede".

1. (Claude) O requisito não menciona o comportamento de idempotência: se `monitorsValidators()` for chamada mais de uma vez no mesmo bloco, a segunda chamada não deve alterar o estado (a implementação atual faz essa verificação). Sugiro explicitar isso como critério de aceitação.
   - (Rayan) Concordo. Temos que garantir isso para evitar gasto desnecessário de gas.

## USSCxx - Administrador re-adiciona validador elegível como validador operacional para tornar consenso da rede mais resiliente

Critérios de aceitação:

1. Somente Administradores Globais ou Administradores Locais ativos, vinculados a organizações ativas, podem executar essa função.
2. O administrador deve informar o endereço do nó a ser re-adicionado.
3. O nó informado **não** deve estar na lista de validadores operacionais.
4. O nó informado deve estar na lista de validadores elegíveis.
5. O administrador somente pode re-adicionar nós vinculados à sua organização.
6. O nó é adicionado à lista de validadores operacionais.
7. Um evento é emitido, registrando:
   1. O endereço do nó
   2. O identificador da organização

Dúvidas:

- E se o nó é adicionado justamente no momento de realizar nova seleção de validadores (e será avaliado como tendo 0 blocos)?
  - (Glads) Uma opção seria só realmente incluí-lo no consenso no momento da seleção de validadores. Seriam três status possíveis: operacional, em espera e fora do consenso (outros nomes, talvez).
  - (Claude) Complementando: ao re-adicionar um validador, seu `lastBlockProposedBy` permanecerá com o valor antigo (ou zero se nunca propôs). Na próxima seleção, ele será imediatamente considerado inativo e removido. É preciso inicializar `lastBlockProposedBy` ao re-adicionar (ex.: com `block.number`) ou adotar o estado intermediário que o Glads sugeriu.
  - (Rayan) Vai depender da ordem das transações no bloco. Se a transação de monitoramento vier antes, não haverá problema. Se vier depois, o validador será incluído como operacional e removido logo em seguida. Podemos o marcar como "em espera", como o Glads sugeriu, e o adicionar no próximo bloco (via função de monitoramento).
- (Glads) É um pouco estranho imaginar que o sujeito pode incluir no consenso um nó que nem permissionado está, né? Mas acho que "integrar" demais pode aumentar demais a complexidade...
  - (JALOP) Dúvida semelhante à que coloquei na história abaixo - "Governança adiciona validador elegível". Mas acho que, se quisermos controle, vale fazer isso nessa outra história que mencionei, na gestão de validadores **elegíveis**. Para gestão de validadores operacionais, talvez não precise.
  - (Rayan) Acho que a depender da complexidade, vale a pena. Se não me engano, neste caso impactaria também a usabilidade o usuário (administrador, neste caso) teria que usar o `enodeHigh` e `enodeLow` para interagir com o contrato, ao invés do endereço, já que o `NodeRulesV2` trata apenas dos enodes.

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
Dúvidas:

- (Glads) Só operacional? Não poderia remover um elegível?
  - (Claude) Se o administrador pudesse remover da lista de elegíveis, ele estaria exercendo poder equivalente ao da governança. Parece correto limitar a operação a operacionais. Porém, poderia haver uma função para o administrador "solicitar" remoção de elegível, sujeita a confirmação da governança.
  - (Rayan) Há algum caso onde um administrador quer remover seu validador da lista de elegíveis sem passar pela Governança?
- (Claude) **Falta de verificação de mínimo de validadores**: O requisito não impede que um administrador remova um validador operacional quando já existem apenas 4 (mínimo para QBFT). A monitoração automática tem essa proteção, mas a remoção manual não. Isso poderia comprometer o consenso da rede.
  - (Rayan) O Administrador usaria essa função em casos como de manutenção programada, onde o nó já vai ficar não operacional e, ao invés de esperar remoção via monitoramento, o administrador removeria diretamente. Mas temos que pensar nessa função com mais cuidado mesmo e avaliar adição de verificações.

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
  - Acho que podemos adicionar a verificação de permissionamento via `NodeRulesV2`.

## USSCxx - Governança remove validador elegível

Critérios de aceitação:

1. Somente o processo de governança pode realizar a remoção.
2. A governança deve informar o endereço do nó a ser removido.
3. O nó informado deve estar na lista de validadores elegíveis.
4. O nó é removido da lista de validadores operacionais, se estiver nessa lista.
5. O nó é removido da lista de validadores elegíveis.
6. Um evento é emitido, registrando:
   1. O endereço do nó

Dúvidas:

- (Claude) Falta considerar: e se há exatamente 4 validadores operacionais e a governança remove um elegível que é operacional? Deveria haver verificação de mínimo? Ou a governança, por ser soberana, pode ultrapassar essa restrição?

## USSCxx - Governança configura parâmetro x

Critérios de aceitação:

1. Somente o processo de governança pode realizar esta configuração.

(JALOP) Nessa(s) história(s) temos que ter cuidado ao alterar um parâmetro para não quebrar premissas de funcionamento da seleção de validadores e, por consequência, quebrar a lógica desejada na execução da seleção.

## USSCxx - Governança atualiza o código *on chain* de seleção de validadores

Critérios de aceitação:

1. Somente o processo de governança pode realizar esta configuração.

Dúvidas:

- (Claude) Este requisito está muito enxuto. A implementação usa padrão UUPS (`UUPSUpgradeable`), o que seria bom mencionar. Além disso, poderia explicitar: (a) que a atualização requer deploy de nova implementação + chamada a `upgradeToAndCall`, (b) que a autorização é via `_authorizeUpgrade` restrita à governança, (c) se deve haver emissão de evento registrando a versão antiga e nova.
- (JALOP) Nessa história temos que decidir que mecanismo vamos querer utilizar para fazer eventuais [atualizações de código](https://ethereum.org/pt-br/developers/docs/smart-contracts/upgrading/#data-separation).
  - (Rayan) Inicialmente, adotamos o método 3 (seguindo esta documentação), mas com certeza vale a pena retomar essa conversa.
