# language: pt
Funcionalidade: Inclusão de novo validador na rede
  Como governança da rede,
  Eu desejo adicionar um novo nó ao conjunto de validadores elegíveis via endereço ou enode,
  Para expandir o conjunto de validadores elegíveis e operacionais do consenso.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Governança adiciona um nó apenas como validador elegível via endereço
    Dado que a função será executada pela governança
    E o endereço do nó a ser adicionado foi informado
    E é definido que o nó não deve ser automaticamente adicionado como validador operacional
    E o nó informado não está no conjunto de validadores elegíveis
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança adiciona um nó apenas como validador elegível via enode
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser adicionado foram informados
    E é definido que o nó não deve ser automaticamente adicionado como validador operacional
    E o nó informado não está no conjunto de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança adiciona como elegível e operacional via endereço sem alterar limite de inatividade
    Dado que a função será executada pela governança
    E o endereço do nó a ser adicionado foi informado
    E o nó informado não está no conjunto de validadores elegíveis
    E é definido que o nó deve ser automaticamente adicionado como validador operacional
    E o limite de inatividade já é maior ou igual à nova quantidade de validadores elegíveis
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E o nó é adicionado ao conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o parâmetro limite de inatividade permanece inalterado
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança adiciona como elegível e operacional via enode sem alterar limite de inatividade
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser adicionado foram informados
    E o nó informado não está no conjunto de validadores elegíveis
    E é definido que o nó deve ser automaticamente adicionado como validador operacional
    E o limite de inatividade já é maior ou igual à nova quantidade de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E o nó é adicionado ao conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o parâmetro limite de inatividade permanece inalterado
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança adiciona como elegível e operacional via endereço reajustando o limite de inatividade
    Dado que a função será executada pela governança
    E o endereço do nó a ser adicionado foi informado
    E o nó informado não está no conjunto de validadores elegíveis
    E é definido que o nó deve ser automaticamente adicionado como validador operacional
    Mas o limite de inatividade atual é menor que a nova quantidade de validadores elegíveis
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E o nó é adicionado ao conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o parâmetro limite de inatividade é atualizado para ser igual à nova quantidade de validadores elegíveis
    E um evento registrando o intervalo de seleção e o novo limite de inatividade deve ser emitido
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Governança adiciona como elegível e operacional via enode reajustando o limite de inatividade
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser adicionado foram informados
    E o nó informado não está no conjunto de validadores elegíveis
    E é definido que o nó deve ser automaticamente adicionado como validador operacional
    Mas o limite de inatividade atual é menor que a nova quantidade de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para adição
    Então a transação deve ser concluída com sucesso
    E o nó é adicionado ao conjunto de validadores elegíveis
    E o nó é adicionado ao conjunto de validadores operacionais
    E o nó é injetado ao conjunto de validadores protegidos
    E o parâmetro limite de inatividade é atualizado para ser igual à nova quantidade de validadores elegíveis
    E um evento registrando o intervalo de seleção e o novo limite de inatividade deve ser emitido
    E um evento registrando o endereço do nó deve ser emitido

  Cenário: Inclusão via endereço falha se o nó já estiver no conjunto de validadores elegíveis
    Dado que a função será executada pela governança
    E o endereço do nó a ser adicionado foi informado
    Mas o nó definido já está no conjunto de validadores elegíveis
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser revertida
    E o nó não é adicionado novamente

  Cenário: Inclusão via enode falha se o nó já estiver no conjunto de validadores elegíveis
    Dado que a função será executada pela governança
    E os parâmetros de enode do nó a ser adicionado foram informados
    Mas o nó definido já está no conjunto de validadores elegíveis
    Quando os parâmetros de enode do nó são enviados para adição
    Então a transação deve ser revertida
    E o nó não é adicionado novamente

  Cenário: Inclusão falha se o endereço informado for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço informado para o nó a ser adicionado é zero (0x0)
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser revertida com erro de endereço inválido
    E o conjunto de validadores elegíveis permanece inalterado

  Cenário: Inclusão falha se não for executada com a devida permissão via endereço
    Dado que a chamada será executada por uma conta que não é a governança
    E o endereço do nó a ser adicionado foi informado
    Quando o endereço do nó é enviado para adição
    Então a transação deve ser revertida por falta de permissão
    E o conjunto de validadores permanece inalterado

  Cenário: Inclusão falha se não for executada com a devida permissão via enode
    Dado que a chamada será executada por uma conta que não é a governança
    E os parâmetros de enode do nó a ser adicionado foram informados
    Quando os parâmetros de enode do nó são enviados para adição
    Então a transação deve ser revertida por falta de permissão
    E o conjunto de validadores permanece inalterado