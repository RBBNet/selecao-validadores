# language: pt
Funcionalidade: Alteração do modo de operação da seleção de validadores
  Como governança da rede,
  Eu desejo alterar o modo de operação do contrato entre manual e automático,
  Para controlar se a exclusão de validadores inativos será feita por intervenção humana ou pelo contrato.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede
    E foi inicializado com pelo menos 1 validador operacional ativo

  Cenário: Governança altera o modo de operação para manual
    Dado que a função será executada pela governança
    E o contrato de seleção de validadores está operando no modo automático
    Quando a função para alterar o modo de operação para manual é executada
    Então a transação deve ser concluída com sucesso
    E o modo de operação do contrato é ajustado para manual
    E as modificações nos conjuntos de validadores passam a ser regidas estritamente pela governança
    E um evento registrando o novo modo selecionado deve ser emitido

  Cenário: Governança altera o modo de operação para automático
    Dado que a função será executada pela governança
    E o contrato de seleção de validadores está operando no modo manual
    Quando a função para alterar o modo de operação para automático é executada
    Então a transação deve ser concluída com sucesso
    E o modo de operação do contrato é ajustado para automático
    E o conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos
    E as informações acumuladas de produção de blocos pelos validadores são inicializadas (zeradas)
    E um novo ciclo de monitoramento automático é iniciado
    E um evento registrando o novo modo selecionado deve ser emitido

  Cenário: Alteração de modo falha se a conta não possuir permissão
    Dado que a função será executada por uma conta que não é a governança
    Quando a função para alterar o modo de operação é executada
    Então a transação deve ser revertida por falta de permissão
    E o modo de operação do contrato permanece inalterado

  Cenário: Alteração falha se o modo de operação informado for inválido
    Dado que a função será executada pela governança
    Quando a função para alterar o modo de operação é executada informando um modo fora das opções permitidas
    Então a transação deve ser revertida com erro de modo de operação inválido
    E o modo de operação do contrato permanece inalterado

  Esquema do Cenário: Alteração falha se o contrato já estiver operando no modo solicitado
    Dado que a função será executada pela governança
    E o contrato de seleção de validadores já está operando no modo "<modo_solicitado>"
    Quando a função para alterar o modo de operação para "<modo_solicitado>" é executada
    Então a transação deve ser revertida por redundância de estado
    E o modo de operação do contrato permanece inalterado

    Exemplos:
      | modo_solicitado |
      | manual          |
      | automático      |