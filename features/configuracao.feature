# language: pt
Funcionalidade: Configuração dos parâmetros de seleção de validadores
  Como governança da rede,
  Eu desejo definir o intervalo entre seleções, o limite de inatividade e o próximo bloco de seleção,
  Para que o comportamento da seleção de validadores seja controlado de forma previsível.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E existe uma conta com permissão de administrador
    E a rede possui ao menos 1 validador elegível

Cenário: Governança configura os parâmetros de seleção com sucesso
    Dado que o usuário utiliza uma conta com permissão de administrador
    E informa um valor para o intervalo de seleções que seja maior ou igual a 1
    E informa um limite de inatividade que seja maior ou igual à quantidade de validadores elegíveis
    Quando a governança envia a transação de configuração de parâmetros
    Então a transação deve ser concluída com sucesso
    E o intervalo de seleções passa a ser o novo valor proposto
    E o limite de inatividade passa a ser o novo valor proposto
    E o conjunto de validadores "adicionados" deve ser esvaziado
    E o ciclo de monitoração de blocos deve ser zerado e reiniciado
    E um evento deve ser emitido registrando os novos valores 

Cenário: Configuração falha se o intervalo entre seleções for menor que o permitido
    Dado que o usuário utiliza uma conta com permissão de Governança
    Mas informa um valor para o intervalo de seleções que é menor que 1 (inválido)
    Quando o usuário tenta enviar a transação de configuração de parâmetros
    Então a transação deve ser revertida com erro de intervalo inválido
    E os parâmetros da rede devem permanecer inalterados

Cenário: Configuração falha se o limite de inatividade for menor que a quantidade de validadores
    Dado que o usuário utiliza uma conta com permissão de Governança
    E informa um valor válido para o intervalo de seleções
    Mas informa um limite de inatividade que é menor do que a quantidade de validadores elegíveis na rede
    Quando o usuário tenta enviar a transação de configuração de parâmetros
    Então a transação deve ser revertida por limite de inatividade incompatível
    E os parâmetros da rede devem permanecer inalterados
