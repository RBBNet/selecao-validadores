# language: pt
Funcionalidade: Remoção manual de validador operacional
  Como governança ou usuário administrador da rede,
  Eu desejo remover um nó do conjunto de validadores operacionais,
  Para que esse nó deixe de participar ativamente do consenso da rede.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Governança remove um validador operacional de qualquer organização via endereço
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores operacionais
    E ao menos 1 validador permanecerá no conjunto de operacionais após a exclusão
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores operacionais
    E o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança remove um validador operacional de qualquer organização via enode
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores operacionais
    E ao menos 1 validador permanecerá no conjunto de operacionais após a exclusão
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores operacionais
    E o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Administrador remove um validador operacional de sua própria organização via enode
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores operacionais vinculado à organização deste administrador
    E ao menos 4 validadores permanecerão no conjunto de operacionais após a exclusão
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores operacionais
    E o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Remoção falha se um administrador tentar remover informando o endereço direto em vez do enode
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores operacionais vinculado à organização deste administrador
    Quando o administrador tenta enviar o endereço direto da função em vez dos parâmetros de enode
    Então a transação deve ser revertida informando que o endereço deve ser enviado via parâmetros de enode
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção falha se o administrador estiver inativo ou suspenso
    Dado que a chamada será executada por um administrador (Global ou Local) inativo
    E existe um nó no conjunto de validadores operacionais vinculado à organização deste administrador
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida informando que o administrador está inativo
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção falha se o administrador tentar remover um nó vinculado a outra organização
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores operacionais vinculado a uma outra organização
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida por violação de vínculo organizacional
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção via endereço falha se a exclusão deixar a rede com menos de 1 validador para a governança
    Dado que a função será executada pela governança
    E existe um nó no conjunto de validadores operacionais
    Mas a exclusão resultaria em zero validadores operacionais
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida por violação do limite mínimo de validadores
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção via enode falha se a exclusão deixar a rede com menos de 4 validadores para um administrador
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó no conjunto de validadores operacionais vinculado à organização deste administrador
    Mas a exclusão resultaria em menos de 4 validadores operacionais na rede
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida por violação do limite mínimo de validadores
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção via endereço falha se executada pela governança para um nó que não é operacional
    Dado que a função será executada pela governança
    E existe um nó que não está no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida informando que o nó não é operacional
    E o conjunto de validadores operacionais permanece inalterado

  Cenário: Remoção via enode falha se executada por um administrador para um nó que não é operacional
    Dado que a chamada será executada por um administrador (Global ou Local) ativo de uma organização ativa
    E existe um nó vinculado à organização deste administrador que não está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida informando que o nó não é operacional
    E o conjunto de validadores operacionais permanece inalterado

  Cenário: Remoção via endereço falha se o endereço informado for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço informado para o nó a ser removido é zero (0x0)
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida com erro de endereço inválido
    E o conjunto de validadores operacionais permanece inalterado

  Cenário: Remoção falha se não for executada com a devida permissão via enode
    Dado que a chamada será executada por uma conta sem permissão
    E existe um nó válido no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida por falta de permissão
    E o nó permanece no conjunto de validadores operacionais

  Cenário: Remoção falha se não for executada com a devida permissão via endereço
    Dado que a chamada será executada por uma conta sem permissão
    E existe um nó válido no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida por falta de permissão
    E o nó permanece no conjunto de validadores operacionais