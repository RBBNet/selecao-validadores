# language: pt
Funcionalidade: Monitoração e seleção automática de validadores
  Como usuário da rede,
  Eu desejo que o contrato monitore a produção de blocos e remova validadores inoperantes periodicamente,
  Para que a rede mantenha um tempo de bloco estável e o consenso saudável.
  
  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede
    E existem pelo menos 4 validadores operacionais ativos
    E o intervalo entre seleções e o limite de inatividade estão configurados

  Cenário: Monitoração encerra imediatamente se o contrato estiver operando em modo manual
    Dado que o contrato de seleção de validadores está operando no modo manual
    Quando a monitoração automática é executada por qualquer conta
    Então a execução encerra imediatamente sem realizar registros de blocos ou seleções de validadores
    E os conjuntos de validadores permanecem inalterados

  Cenário: É registrada a atividade do validador que propôs o bloco atual antes do momento de seleção
    Dado que o contrato de seleção de validadores está operando no modo automático
    E o bloco atual da rede ainda não atingiu o intervalo para selecionar validadores
    E a monitoração ainda não foi executada para o bloco atual
    Quando a monitoração automática é executada por qualquer conta
    Então um evento indicando a execução da monitoração deve ser emitido
    E a monitoração registra sua execução para o bloco atual
    E a monitoração contabiliza o bloco atual na métrica de desempenho do validador que o propôs
    E a monitoração encerra sem selecionar ou remover validadores

  Cenário: Contrato remove validadores inoperantes no momento do ciclo de seleção
    Dado que o contrato de seleção de validadores está operando no modo automático
    E o bloco atual da rede atingiu o intervalo para selecionar validadores
    E a monitoração ainda não foi executada para o bloco atual
    E existem validadores operacionais há mais blocos sem propor do que o limite tolerado
    E esses validadores pré-selecionados para remoção não estão contidos no conjunto de validadores protegidos
    E ao menos 4 validadores permanecerão no conjunto de validadores operacionais após a exclusão
    Quando a monitoração automática é executada por qualquer conta
    Então um evento indicando a execução da monitoração deve ser emitido
    E a monitoração contabiliza o bloco atual para o validador que o propôs
    E a monitoração emite evento indicando os validadores operacionais a serem removidos
    E os validadores pré-selecionados são removidos do conjunto operacional, sendo mantidos como validadores elegíveis
    E o conjunto de validadores protegidos é completamente esvaziado
    E as informações acumuladas de produção de blocos são inicializadas (zeradas) e um novo ciclo de monitoração é iniciado
    E a monitoração emite um evento final indicando a realização da seleção automática informando o conjunto resultante

  Cenário: Monitoração encerra sem seleções adicionais se já tiver sido executada para o bloco atual
    Dado que o contrato de seleção de validadores está operando no modo automático
    Mas a monitoração já foi executada para o bloco atual
    Quando a monitoração automática é executada novamente no mesmo bloco
    Então um evento indicando a execução da monitoração deve ser emitido
    Mas a monitoração encerra sem realizar registros de blocos ou seleções adicionais

  Cenário: Validadores inoperantes são mantidos no consenso se a exclusão deixar a rede com menos de 4 validadores
    Dado que o contrato de seleção de validadores está operando no modo automático
    E o bloco atual da rede atingiu o intervalo para selecionar validadores
    E a monitoração ainda não foi executada para o bloco atual
    E existem validadores operacionais há mais blocos sem propor do que o limite tolerado
    Mas após a eventual exclusão, não permaneceriam pelo menos 4 validadores no conjunto de operacionais
    Quando a monitoração automática é executada por qualquer conta
    Então a remoção é vetada por segurança e os validadores pré-selecionados são mantidos como operacionais
    E o conjunto de validadores protegidos é completamente esvaziado
    E as informações acumuladas de produção de blocos são inicializadas (zeradas) e um novo ciclo de monitoração é iniciado
    E a monitoração emite um evento final indicando a realização da seleção automática informando o conjunto resultante

  Cenário: Validadores inoperantes são mantidos no consenso se possuírem imunidade no conjunto de protegidos
    Dado que o contrato de seleção de validadores está operando no modo automático
    E o bloco atual da rede atingiu o intervalo parametrizado para selecionar validadores
    E a monitoração ainda não foi executada para o bloco atual
    E existem validadores operacionais há mais blocos sem propor do que o limite tolerado
    Mas esses validadores pré-selecionados estão contidos no conjunto de validadores protegidos
    Quando a monitoração automática é executada por qualquer conta
    Então os validadores pré-selecionados são imunes e mantidos no conjunto de validadores operacionais
    E o conjunto de validadores protegidos é completamente esvaziado
    E as informações acumuladas de produção de blocos são inicializadas (zeradas) e um novo ciclo de monitoração é iniciado
    E a monitoração emite um evento final indicando a realização da seleção automática informando o conjunto resultante