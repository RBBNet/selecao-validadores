# language: pt
Funcionalidade: Gestão de validadores elegíveis
  Como governança da rede,
  Eu desejo incluir e remover validadores da lista de elegíveis,
  Para controlar quais nós podem ser promovidos a validadores operacionais.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E existe um endereço com papel de governança
    E existe um endereço sem permissões administrativas

  Cenário: Governança inclui um novo validador na lista de elegíveis por endereço
    Dado que existe um endereço de validador que ainda não está na lista de elegíveis
    Quando a governança inclui esse validador na lista de elegíveis
    Então o validador passa a constar na lista de validadores elegíveis

  Cenário: Inclusão de validador elegível por usuário sem permissão é recusada
    Dado que existe um endereço de validador que ainda não está na lista de elegíveis
    Quando um usuário sem permissão tenta incluir esse validador na lista de elegíveis
    Então a operação é recusada
    E o validador não passa a constar na lista de elegíveis

  Cenário: Governança inclui um novo validador na lista de elegíveis por enode
    Dado que existe um par enode cujo endereço calculado não está na lista de elegíveis
    Quando a governança inclui esse enode na lista de elegíveis
    Então o endereço correspondente ao enode passa a constar na lista de elegíveis

  Cenário: Inclusão de validador elegível por enode por usuário sem permissão é recusada
    Dado que existe um par enode cujo endereço calculado não está na lista de elegíveis
    Quando um usuário sem permissão tenta incluir esse enode na lista de elegíveis
    Então a operação é recusada
    E o endereço correspondente não passa a constar na lista de elegíveis

  Cenário: Governança remove um validador da lista de elegíveis por endereço
    Dado que existe um validador que já consta na lista de elegíveis
    Quando a governança remove esse validador da lista de elegíveis
    Então o validador deixa de constar na lista de elegíveis

  Cenário: Remoção de nó não elegível por governança é recusada
    Dado que existe um endereço que não consta na lista de elegíveis
    Quando a governança tenta remover esse endereço da lista de elegíveis
    Então a operação é recusada
    E o sistema informa que o nó não é elegível

  Cenário: Remoção de validador elegível por usuário sem permissão é recusada
    Dado que existe um validador que já consta na lista de elegíveis
    Quando um usuário sem permissão tenta remover esse validador da lista de elegíveis
    Então a operação é recusada
    E o validador continua na lista de elegíveis

  Cenário: Governança remove um validador da lista de elegíveis por enode
    Dado que existe um validador elegível identificado por um par enode
    Quando a governança remove esse enode da lista de elegíveis
    Então o endereço correspondente deixa de constar na lista de elegíveis

  Cenário: Remoção de nó não elegível por enode por governança é recusada
    Dado que existe um par enode cujo endereço não consta na lista de elegíveis
    Quando a governança tenta remover esse enode da lista de elegíveis
    Então a operação é recusada
    E o sistema informa que o nó não é elegível

  Cenário: Remoção de validador elegível por enode por usuário sem permissão é recusada
    Dado que existe um validador elegível identificado por um par enode
    Quando um usuário sem permissão tenta remover esse enode da lista de elegíveis
    Então a operação é recusada
    E o validador continua na lista de elegíveis
