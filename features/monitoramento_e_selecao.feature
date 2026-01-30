# language: pt
Funcionalidade: Monitoramento e seleção automática de validadores
  Como sistema de seleção de validadores,
  Eu devo monitorar a atividade de proposta de blocos dos validadores operacionais
  E remover periodicamente validadores inativos que ultrapassem o limite,
  Para que a rede mantenha um conjunto de validadores ativos e um quorum saudável.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E o intervalo entre seleções está configurado em 100 blocos
    E o limite de inatividade está configurado em 100 blocos
    E o próximo bloco de seleção está em 1000
    E a lista de validadores operacionais contém oito validadores

  Cenário: Atividade de validador que propõe bloco é registrada
    Dado que o bloco atual é 200
    E o validador que propõe o bloco é conhecido
    Quando o monitoramento é executado nesse bloco
    Então o sistema registra que esse validador propôs bloco no bloco 200
    E o evento de monitoramento é emitido

  Cenário: Segunda execução de monitoramento no mesmo bloco não altera o registro
    Dado que o bloco atual é 200
    E o validador que propõe o bloco é conhecido
    E o monitoramento já foi executado uma vez nesse bloco
    Quando o monitoramento é executado novamente no mesmo bloco
    Então o registro de atividade do validador permanece inalterado
    E o evento de monitoramento não é emitido novamente

  Cenário: Nenhuma seleção ocorre antes do bloco de seleção configurado
    Dado que o bloco atual é 999
    E o próximo bloco de seleção está em 1000
    Quando o monitoramento é executado
    Então a lista de validadores operacionais não é alterada
    E o próximo bloco de seleção permanece em 1000

  Cenário: No bloco de seleção a próxima seleção é agendada
    Dado que o bloco atual é 1000
    E o próximo bloco de seleção está em 1000
    E o intervalo entre seleções é 100 blocos
    Quando o monitoramento é executado nesse bloco
    Então o próximo bloco de seleção passa a ser 1100

  Cenário: No bloco de seleção validadores ativos não são removidos
    Dado que o bloco atual é 1000
    E o próximo bloco de seleção está em 1000
    E o limite de inatividade é 10 blocos
    E todos os validadores operacionais propuseram bloco recentemente dentro do limite
    Quando o monitoramento é executado
    Então nenhum validador é removido da lista de operacionais
    E o próximo bloco de seleção é atualizado para a próxima rodada

  Cenário: Validadores inativos além do limite são removidos no bloco de seleção
    Dado que o bloco atual é 1000
    E o próximo bloco de seleção está em 1000
    E o limite de inatividade é 10 blocos
    E existem oito validadores operacionais
    E dois deles não propuseram bloco há mais de 10 blocos
    Quando o monitoramento é executado
    Então esses dois validadores são removidos da lista de operacionais
    E os seis restantes permanecem na lista
    E o próximo bloco de seleção é atualizado para a próxima rodada

  Cenário: Validadores inativos não são removidos se o quorum mínimo seria violado
    Dado que o bloco atual é 1000
    E a lista de operacionais contém apenas cinco validadores
    E dois deles estão inativos além do limite de inatividade
    Quando o monitoramento é executado
    Então nenhum validador é removido da lista de operacionais
    E a lista permanece com cinco validadores
    E o quorum mínimo de quatro validadores é preservado
