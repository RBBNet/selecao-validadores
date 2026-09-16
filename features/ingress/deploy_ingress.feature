# language: pt
Funcionalidade: Implantação do contrato de ingress da seleção de validadores
  Como usuário com permissão de deploy,
  Eu desejo implantar e inicializar o contrato de ingress,
  Para estabelecer um ponto de acesso fixo para o Besu e permitir a atualização da lógica sem causar um hard fork na rede.

  Contexto:
    Dado que os contratos de admin e seleção de validadores já estão implantados na rede

  Cenário: Implantação bem-sucedida do ingress
    Dado que a chamada é executada por uma conta com permissão de deploy
    E o endereço do contrato de admin informado é válido e implementa a verificação de compatibilidade
    E o endereço do contrato de seleção de validadores informado é válido e implementa a listagem de validadores
    E a função de listagem no contrato de seleção retorna uma lista contendo pelo menos 1 validador
    Quando a função de implantação do ingress é acionada passando os endereços obrigatórios
    Então a transação deve ser concluída com sucesso
    E os endereços informados são registrados internamente no contrato de ingress

  Cenário: Implantação falha se o endereço do contrato de admin for zero (0x0)
    Dado que a chamada é executada por uma conta com permissão de deploy
    Mas o endereço informado para o contrato de admin é zero (0x0)
    Quando a função de implantação do ingress é acionada
    Então a transação deve ser revertida com erro de endereço inválido
    E o contrato de ingress não é implantado

  Cenário: Implantação falha se o endereço do contrato de seleção for zero (0x0)
    Dado que a chamada é executada por uma conta com permissão de deploy
    E o endereço do contrato de admin informado é válido e implementa a verificação de compatibilidade
    Mas o endereço informado para o contrato de seleção de validadores é zero (0x0)
    Quando a função de implantação do ingress é acionada
    Então a transação deve ser revertida com erro de endereço inválido
    E o contrato de ingress não é implantado

  Cenário: Implantação falha se o contrato de admin não implementar a verificação de compatibilidade
    Dado que a chamada é executada por uma conta com permissão de deploy
    E os endereços informados são diferentes de zero (0x0)
    Mas o contrato de admin reverte ao receber a chamada de verificação de compatibilidade
    Quando a função de implantação do ingress é acionada
    Então a transação deve ser revertida por incompatibilidade de interface
    E o contrato de ingress não é implantado

  Cenário: Implantação falha se o contrato de seleção não implementar a função de leitura obrigatória
    Dado que a chamada é executada por uma conta com permissão de deploy
    E o endereço do contrato de admin informado é válido e implementa a verificação de compatibilidade
    Mas o contrato de seleção não implementa a assinatura da função de listagem de validadores
    Quando a função de implantação do ingress é acionada
    Então a transação deve ser revertida por incompatibilidade de interface
    E o contrato de ingress não é implantado

  Cenário: Implantação falha se o contrato de seleção retornar uma lista vazia de validadores
    Dado que a chamada é executada por uma conta com permissão de deploy
    E o endereço do contrato de admin informado é válido e implementa a verificação de compatibilidade
    E o contrato de seleção implementa a função de listagem de validadores
    Mas a chamada de teste da função de listagem retorna uma lista vazia
    Quando a função de implantação do ingress é acionada
    Então a transação deve ser revertida para evitar o travamento do consenso da rede
    E o contrato de ingress não é implantado