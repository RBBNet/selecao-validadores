# language: pt
Funcionalidade: Inclusão de validador operacional
  Como governança ou usuário administrador da rede,
  Eu desejo adicionar um nó elegível ao conjunto de validadores operacionais,
  Para que esse nó volte a participar ativamente do consenso da rede.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Governança inclui um validador operacional de qualquer organização via endereço
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores elegíveis
    E esse nó não está no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para inclusão
    Então a transação deve ser concluída com sucesso
    E o nó passa a integrar o conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o nó permanece no conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança inclui um validador operacional de qualquer organização via enode
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores elegíveis
    E esse nó não está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser concluída com sucesso
    E o nó passa a integrar o conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o nó permanece no conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Administrador inclui um validador operacional de sua própria organização via enode
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores elegíveis vinculado à organização deste administrador
    E esse nó não está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser concluída com sucesso
    E o nó passa a integrar o conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o nó permanece no conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Inclusão falha se um administrador tentar adicionar informando o endereço direto em vez do enode
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores elegíveis vinculado à organização deste administrador
    E esse nó não está no conjunto de validadores operacionais
    Quando o administrador tenta enviar o endereço direto da função em vez dos parâmetros de enode
    Então a transação deve ser revertida por incompatibilidade de chamada para o perfil
    E o nó não passa a constar no conjunto de validadores operacionais

  Cenário: Inclusão falha se o administrador estiver inativo ou suspenso
    Dado que a chamada será executada por um administrador (Global ou Local) inativo
    E existe um nó no conjunto de validadores elegíveis vinculado à organização deste administrador
    E esse nó não está no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para inclusão
    Então a transação deve ser revertida informando que o administrador está inativo
    E o nó não passa a constar no conjunto de validadores operacionais

  Cenário: Inclusão falha se o administrador tentar adicionar um nó vinculado a outra organização
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores elegíveis vinculado a uma outra organização
    E esse nó não está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser revertida por violação de vínculo organizacional
    E o nó não passa a constar no conjunto de validadores operacionais

  Cenário: Inclusão via endereço falha se executada pela governança para um nó que já é operacional
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores elegíveis
    Mas esse nó já está no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para inclusão
    Então a transação deve ser revertida informando que o nó já é operacional
    E o conjunto de validadores protegidos permanece inalterado

  Cenário: Inclusão via enode falha se executada por um administrador para um nó que já é operacional
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores elegíveis vinculado à organização deste administrador
    Mas esse nó já está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser revertida informando que o nó já é operacional
    E o conjunto de validadores protegidos permanece inalterado

  Cenário: Inclusão via endereço falha se executada pela governança para um nó que não é elegível
    Dado que a função será executada pela governança
    E existe um nó que não está no conjunto de validadores elegíveis
    Quando o endereço do nó é enviado para inclusão
    Então a transação deve ser revertida informando que o nó não é elegível
    E o nó não passa a constar no conjunto de validadores operacionais

  Cenário: Inclusão via enode falha se executada por um administrador para um nó que não é elegível
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó vinculado à organização deste administrador que não está no conjunto de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser revertida informando que o nó não é elegível
    E o nó não passa a constar no conjunto de validadores operacionais
    
  Cenário: Inclusão falha se não for executada com a devida permissão via endereço
    Dado que a chamada será executada por uma conta sem permissão
    E existe um nó no conjunto de validadores elegíveis que não está nos operacionais
    Quando o endereço do nó é enviado para inclusão
    Então a transação deve ser revertida por falta de permissão
    E o nó não passa a constar no conjunto de validadores operacionais

  Cenário: Inclusão falha se não for executada com a devida permissão via enode
    Dado que a chamada será executada por uma conta sem permissão
    E existe um nó no conjunto de validadores elegíveis que não está nos operacionais
    Quando os parâmetros de enode do nó são enviados para inclusão
    Então a transação deve ser revertida por falta de permissão
    E o nó não passa a constar no conjunto de validadores operacionais