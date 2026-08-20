# language: pt
Funcionalidade: Gestão de validadores operacionais
  Como governança e administradores ativos,
  Eu desejo incluir e remover validadores da lista de operacionais,
  Para controlar quais nós estão ativos na rede como validadores.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E existe um endereço com papel de governança
    E existe um endereço sem permissões administrativas
    E existe um administrador ativo da rede

  Cenário: Governança inclui um validador operacional por endereço
    Dado que existe um validador que consta na lista de elegíveis e não está operacional
    Quando a governança inclui esse validador na lista de operacionais
    Então o validador passa a constar na lista de validadores operacionais

  Cenário: Inclusão de validador não elegível como operacional é recusada
    Dado que existe um endereço que não consta na lista de elegíveis
    Quando a governança tenta incluir esse endereço na lista de operacionais
    Então a operação é recusada
    E o sistema informa que o nó não é elegível

  Cenário: Inclusão de validador operacional por usuário sem permissão é recusada
    Dado que existe um validador que consta na lista de elegíveis
    Quando um usuário sem permissão tenta incluir esse validador na lista de operacionais
    Então a operação é recusada
    E o validador não passa a constar na lista de operacionais

  Cenário: Administrador ativo inclui validador operacional por enode da própria organização
    Dado que existe um validador elegível identificado por enode
    E o administrador ativo pertence à mesma organização desse enode
    Quando o administrador ativo inclui esse enode na lista de operacionais
    Então o endereço correspondente passa a constar na lista de operacionais

  Cenário: Inclusão de validador de outra organização por administrador é recusada
    Dado que existe um validador elegível identificado por enode
    E o administrador ativo não pertence à organização desse enode
    Quando o administrador ativo tenta incluir esse enode na lista de operacionais
    Então a operação é recusada
    E o sistema informa que o nó não é local da organização

  Cenário: Inclusão de validador operacional por enode por usuário sem permissão é recusada
    Dado que existe um validador elegível identificado por enode
    Quando um usuário sem permissão tenta incluir esse enode na lista de operacionais
    Então a operação é recusada
    E o endereço não passa a constar na lista de operacionais

  Cenário: Governança remove um validador operacional por endereço
    Dado que existe um validador que consta na lista de operacionais
    Quando a governança remove esse validador da lista de operacionais
    Então o validador deixa de constar na lista de operacionais

  Cenário: Remoção de nó não operacional por governança é recusada
    Dado que existe um endereço que não consta na lista de operacionais
    Quando a governança tenta remover esse endereço da lista de operacionais
    Então a operação é recusada
    E o sistema informa que o nó não é operacional

  Cenário: Remoção de validador operacional por usuário sem permissão é recusada
    Dado que existe um validador que consta na lista de operacionais
    Quando um usuário sem permissão tenta remover esse validador da lista de operacionais
    Então a operação é recusada
    E o validador continua na lista de operacionais

  Cenário: Administrador ativo remove validador operacional por enode da própria organização
    Dado que existe um validador operacional identificado por enode
    E o administrador ativo pertence à mesma organização desse enode
    Quando o administrador ativo remove esse enode da lista de operacionais
    Então o endereço correspondente deixa de constar na lista de operacionais

  Cenário: Remoção de nó não operacional por enode por administrador é recusada
    Dado que existe um par enode cujo endereço não consta na lista de operacionais
    Quando o administrador ativo tenta remover esse enode da lista de operacionais
    Então a operação é recusada
    E o sistema informa que o nó não é operacional

  Cenário: Remoção de validador operacional de outra organização por administrador é recusada
    Dado que existe um validador operacional identificado por enode
    E o administrador ativo não pertence à organização desse enode
    Quando o administrador ativo tenta remover esse enode da lista de operacionais
    Então a operação é recusada
    E o sistema informa que o nó não é local da organização

  Cenário: Remoção de validador operacional por enode por usuário sem permissão é recusada
    Dado que existe um validador operacional identificado por enode
    Quando um usuário sem permissão tenta remover esse enode da lista de operacionais
    Então a operação é recusada
    E o validador continua na lista de operacionais
