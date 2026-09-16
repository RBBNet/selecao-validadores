# language: pt
Funcionalidade: Atualização do endereço do contrato de regras de nós (NodeRulesV2) no contrato de seleção de validadores
  Como governança da rede,
  Eu desejo atualizar o endereço do contrato de regras de nós (NodeRulesV2) registrado no contrato de seleção de validadores,
  Para suportar migrações do contrato de regras de nós e evolução do permissionamento de nós.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Governança atualiza o endereço do contrato de regras de nós com sucesso
    Dado que a função será executada pela governança
    E o endereço do novo contrato de regras de nós informado é diferente do atual
    E o endereço do novo contrato de regras de nós informado não é zero (0x0)
    E o novo contrato de regras de nós responde com sucesso à verificação de compatibilidade
    Quando a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores
    Então a transação deve ser concluída com sucesso
    E a variável de armazenamento do contrato de regras de nós no contrato de seleção de validadores é atualizada para o novo endereço
    E um evento registrando os endereços do contrato de regras de nós anterior e novo deve ser emitido

  Cenário: Atualização falha se o endereço do novo contrato de regras de nós informado for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato de regras de nós informado é zero (0x0)
    Quando a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores
    Então a transação deve ser revertida com erro de endereço inválido
    E o endereço do contrato de regras de nós no contrato de seleção de validadores permanece inalterado

  Cenário: Atualização falha se o endereço do novo contrato de regras de nós for igual ao atual
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato de regras de nós informado é igual ao endereço ativo atualmente
    Quando a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores
    Então a transação deve ser revertida informando que o endereço é idêntico ao atual
    E o endereço do contrato de regras de nós no contrato de seleção de validadores permanece inalterado

  Cenário: Atualização falha se o novo contrato de regras de nós não responder à verificação de compatibilidade
    Dado que a função será executada pela governança
    E o endereço do novo contrato de regras de nós informado é válido e diferente do atual
    Mas o novo contrato de regras de nós reverte ao receber a verificação de compatibilidade
    Quando a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores
    Então a transação deve ser revertida por incompatibilidade de interface
    E o endereço do contrato de regras de nós no contrato de seleção de validadores permanece inalterado

  Cenário: Atualização falha se não for executada com a devida permissão
    Dado que a chamada será executada por uma conta que não é a governança
    E o endereço do novo contrato de regras de nós informado é válido e diferente do atual
    Quando a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores
    Então a transação deve ser revertida por falta de permissão
    E o endereço do contrato de regras de nós no contrato de seleção de validadores permanece inalterado