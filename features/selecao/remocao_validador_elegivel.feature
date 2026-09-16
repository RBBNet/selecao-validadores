# language: pt
Funcionalidade: Remoção de validador elegível
  Como governança da rede,
  Eu desejo remover um nó do conjunto de validadores elegíveis via endereço ou enode,
  Para que o nó perca a permissão de participar do consenso da rede.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Governança remove com sucesso um nó que é apenas elegível via endereço
    Dado que a função será executada pela governança
    E o endereço do nó a ser removido foi informado
    E o nó informado está no conjunto de validadores elegíveis
    Mas o nó informado não está no conjunto de validadores operacionais
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança remove com sucesso um nó que é apenas elegível via enode
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser removido foram informados
    E o nó informado está no conjunto de validadores elegíveis
    Mas o nó informado não está no conjunto de validadores operacionais
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança remove com sucesso um nó que também é operacional via endereço
    Dado que a função será executada pela governança
    E o endereço do nó a ser removido foi informado
    E o nó informado está no conjunto de validadores elegíveis
    E o nó informado também está no conjunto de validadores operacionais
    E ao menos 1 validador permanecerá no conjunto de validadores operacionais após a exclusão
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores elegíveis
    E o nó é removido do conjunto de validadores operacionais
    E o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto
    E um evento registrando a revogação da elegibilidade do nó deve ser emitido
    E um evento adicional registrando a remoção operacional manual do nó deve ser emitido

  Cenário: Governança remove com sucesso um nó que também é operacional via enode
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser removido foram informados
    E o nó informado está no conjunto de validadores elegíveis
    E o nó informado também está no conjunto de validadores operacionais
    E ao menos 1 validador permanecerá no conjunto de validadores operacionais após a exclusão
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser concluída com sucesso
    E o nó é removido do conjunto de validadores elegíveis
    E o nó é removido do conjunto de validadores operacionais
    E o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto
    E um evento registrando a revogação da elegibilidade do nó deve ser emitido
    E um evento adicional registrando a remoção operacional manual do nó deve ser emitido

  Cenário: Remoção via endereço falha se a exclusão deixar a rede com zero validadores operacionais
    Dado que a função será executada pela governança
    E o endereço do nó a ser removido foi informado
    E o nó informado está nos conjuntos de validadores elegíveis e operacionais
    Mas a exclusão resultaria em zero validadores operacionais
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida por violação do limite mínimo de validadores
    E o nó não é removido de nenhum dos conjuntos

  Cenário: Remoção via enode falha se a exclusão deixar a rede com zero validadores operacionais
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser removido foram informados
    E o nó informado está nos conjuntos de validadores elegíveis e operacionais
    Mas a exclusão resultaria em zero validadores operacionais
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida por violação do limite mínimo de validadores
    E o nó não é removido de nenhum dos conjuntos

  Cenário: Remoção via endereço falha se o nó não estiver no conjunto de validadores elegíveis
    Dado que a função será executada pela governança
    E o endereço do nó a ser removido foi informado
    Mas o nó informado não está no conjunto de validadores elegíveis
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida informando que o nó não é elegível
    E o conjunto de validadores permanece inalterado

  Cenário: Remoção via enode falha se o nó não estiver no conjunto de validadores elegíveis
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser removido foram informados
    Mas o nó informado não está no conjunto de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida informando que o nó não é elegível
    E o conjunto de validadores permanece inalterado

  Cenário: Remoção via endereço falha se o endereço informado for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço informado para o nó a ser removido é zero (0x0)
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida com erro de endereço inválido
    E o conjunto de validadores permanece inalterado

  Cenário: Remoção falha se não for executada com a devida permissão via endereço
    Dado que a chamada será executada por uma conta que não é a governança
    E o endereço do nó a ser removido foi informado
    Quando o endereço do nó é enviado para remoção
    Então a transação deve ser revertida por falta de permissão
    E o conjunto de validadores permanece inalterado

  Cenário: Remoção falha se não for executada com a devida permissão via enode
    Dado que a chamada será executada por uma conta que não é a governança
    E os parâmetros de enode do nó a ser removido foram informados
    Quando os parâmetros de enode do nó são enviados para remoção
    Então a transação deve ser revertida por falta de permissão
    E o conjunto de validadores permanece inalterado