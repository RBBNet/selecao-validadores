# language: pt
Funcionalidade: Atualização do código de seleção de validadores no Ingress
  Como governança da rede,
  Eu desejo atualizar o endereço do contrato de seleção de validadores no Ingress,
  Para implantar novas lógicas ou correções sem causar um hard fork na rede.

  Contexto:
    Dado que o contrato de seleção de validadores atual está implantado na rede
    E um novo contrato de seleção de validadores já foi implantado na rede

  Cenário: Governança atualiza o contrato de seleção com sucesso
    Dado que a função será executada pela governança
    E o endereço do novo contrato informado é diferente do endereço do contrato atual
    E o endereço do novo contrato não é zero
    E o novo contrato implementa corretamente a função de listagem de validadores ativos
    E a função do novo contrato retorna uma lista contendo pelo menos 1 validador operacional
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser concluída com sucesso
    E o endereço do contrato de seleção de validadores corrente é atualizado para o novo endereço
    E um evento registrando o endereço do novo contrato de seleção de validadores deve ser emitido

  Cenário: Atualização falha se o endereço do novo contrato informado for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato informado é zero (0x0)
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser revertida com erro de endereço nulo
    E o contrato atual permanece inalterado

  Cenário: Atualização falha se o endereço do novo contrato for igual ao contrato atual
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato informado é igual ao endereço do contrato atual
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser revertida informando que o contrato já está em operação
    E o contrato atual permanece inalterado

  Cenário: Atualização falha se o novo contrato não implementar a função de leitura obrigatória
    Dado que a função será executada pela governança
    E o endereço do novo contrato informado é válido e diferente do atual
    Mas o novo contrato não suporta a interface de listagem de validadores ativos
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser revertida por incompatibilidade de interface
    E o contrato atual permanece inalterado

  Cenário: Atualização falha se o novo contrato retornar uma lista vazia de validadores
    Dado que a função será executada pela governança
    E o endereço do novo contrato informado é válido e diferente do atual
    E o novo contrato implementa a função de listagem de validadores ativos
    Mas a função do novo contrato retorna uma lista vazia
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser revertida para evitar o travamento do consenso da rede
    E o contrato atual permanece inalterado

  Cenário: Atualização falha se não for executada pela governança
    Dado que a função será executada por uma conta que não é a governança
    E o endereço do novo contrato informado é válido e diferente do atual
    Quando a função de atualização do código de seleção de validadores é executada
    Então a transação deve ser revertida por falta de permissão
    E o contrato atual permanece inalterado