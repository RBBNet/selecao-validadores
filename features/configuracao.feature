# language: pt
Funcionalidade: Configuração dos parâmetros de seleção de validadores
  Como governança da rede,
  Eu desejo definir o intervalo entre seleções, o limite de inatividade e o próximo bloco de seleção,
  Para que o comportamento da seleção de validadores seja controlado de forma previsível.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E o intervalo entre seleções está em 100 blocos
    E o limite de inatividade está em 100 blocos
    E o próximo bloco de seleção está em 100
    E existe um endereço com papel de governança
    E existe um endereço sem permissões administrativas

  Cenário: Governança altera o intervalo entre seleções com sucesso
    Dado que o intervalo entre seleções atual é 100 blocos
    Quando a governança define o intervalo entre seleções para 200 blocos
    Então o intervalo entre seleções passa a ser 200 blocos

  Cenário: Alteração do intervalo entre seleções por usuário sem permissão é recusada
    Dado que o intervalo entre seleções atual é 100 blocos
    Quando um usuário sem permissão tenta definir o intervalo entre seleções para 200 blocos
    Então a alteração é recusada
    E o intervalo entre seleções permanece em 100 blocos

  Cenário: Governança altera o limite de inatividade com sucesso
    Dado que o limite de inatividade atual é 100 blocos
    Quando a governança define o limite de inatividade para 50 blocos
    Então o limite de inatividade passa a ser 50 blocos

  Cenário: Alteração do limite de inatividade por usuário sem permissão é recusada
    Dado que o limite de inatividade atual é 100 blocos
    Quando um usuário sem permissão tenta definir o limite de inatividade para 50 blocos
    Então a alteração é recusada
    E o limite de inatividade permanece em 100 blocos

  Cenário: Governança altera o próximo bloco de seleção com sucesso
    Dado que o próximo bloco de seleção atual é 100
    Quando a governança define o próximo bloco de seleção para 200
    Então o próximo bloco de seleção passa a ser 200

  Cenário: Alteração do próximo bloco de seleção por usuário sem permissão é recusada
    Dado que o próximo bloco de seleção atual é 100
    Quando um usuário sem permissão tenta definir o próximo bloco de seleção para 200
    Então a alteração é recusada
    E o próximo bloco de seleção permanece em 100
