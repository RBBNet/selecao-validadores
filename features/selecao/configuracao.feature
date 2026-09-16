# language: pt
Funcionalidade: Configuração dos parâmetros de seleção automática de validadores
  Como governança da rede,
  Eu desejo definir o intervalo entre seleções, o limite de inatividade e o próximo bloco de seleção,
  Para que o comportamento da seleção de validadores seja controlado de forma previsível.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E a rede possui ao menos 1 validador elegível e operacional ativo

  Cenário: A governança configura os parâmetros de seleção com sucesso
    Dado que a função será executada pela governança
    E o valor informado para o intervalo de seleções é maior ou igual a 1
    E o limite de inatividade informado é maior ou igual à quantidade de validadores elegíveis
    Quando a transação de configuração de parâmetros é executada
    Então a transação deve ser concluída com sucesso
    E o intervalo de seleções passa a ser o novo valor proposto
    E o limite de inatividade passa a ser o novo valor proposto
    E o conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos
    E as informações acumuladas de produção de blocos pelos validadores são inicializadas (zeradas)
    E um novo ciclo de monitoramento automático é iniciado
    E um evento deve ser emitido registrando os novos valores configurados

  Cenário: Configuração falha se o intervalo entre seleções for menor que o permitido
    Dado que a função será executada pela governança
    Mas o valor informado para o intervalo de seleções é 0 (inválido)
    Quando a transação de configuração de parâmetros é executada
    Então a transação deve ser revertida com erro de intervalo inválido
    E os parâmetros da rede devem permanecer inalterados

  Cenário: Configuração falha se o limite de inatividade for menor que a quantidade de validadores
    Dado que a função será executada pela governança
    E um valor válido para o intervalo de seleções é informado
    Mas o limite de inatividade informado é menor do que a quantidade de validadores elegíveis na rede
    Quando a transação de configuração de parâmetros é executada
    Então a transação deve ser revertida por limite de inatividade incompatível
    E os parâmetros da rede devem permanecer inalterados

  Cenário: Configuração falha se não for executada pela governança
    Dado que a transação será executada por uma conta que não é a governança
    Quando a transação de configuração de parâmetros é executada
    Então a transação deve ser revertida por falta de permissão
    E os parâmetros da rede devem permanecer inalterados