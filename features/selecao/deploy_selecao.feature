# language: pt
Funcionalidade: Implantação do código on-chain da seleção de validadores
  Como usuário com permissão de deploy,
  Eu desejo implantar o contrato de seleção de validadores com uma lista inicial de validadores elegíveis,
  Para que a rede possa iniciar o processo de seleção e monitoramento de validadores.

  Cenário: Implantação bem-sucedida inicializando as listas e o modo manual
    Dado que a implantação será feita por um usuário com permissão de deploy
    E foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E a lista inicial possui pelo menos 1 endereço de validador elegível sem duplicidades
    E o intervalo definido entre seleções é maior ou igual a 1
    E o limite de inatividade definido é maior ou igual ao tamanho do conjunto de validadores elegíveis
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a implantação deve ser concluída com sucesso
    E o sistema de seleção de validadores fica disponível
    E o modo de operação do contrato deve ser inicializado como manual
    E o conjunto de validadores elegíveis deve conter os endereços informados
    E o conjunto de validadores operacionais deve conter os mesmos endereços informados
    E o conjunto de validadores protegidos deve conter os mesmos endereços informados

  Cenário: Implantação falha se a lista inicial possuir menos de um validador
    Dado que a implantação será feita por um usuário com permissão de deploy
    E foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    Mas a lista inicial possui 0 validadores (vazia)
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a transação deve ser revertida com erro de nenhum nó validador encontrado
    E o contrato não é implantado

  Cenário: Implantação falha se a lista inicial contiver endereços duplicados
    Dado que a implantação será feita por um usuário com permissão de deploy
    E foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    Mas a lista inicial possui endereços de validadores duplicados
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a transação deve ser revertida com erro de endereço duplicado
    E o contrato não é implantado

  Cenário: Implantação falha se o intervalo entre seleções for menor que o permitido
    Dado que a implantação será feita por um usuário com permissão de deploy
    E foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E a lista inicial possui pelo menos 1 endereço de validador elegível sem duplicidades
    Mas o intervalo informado entre seleções é 0
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a transação deve ser revertida com erro de intervalo inválido
    E o contrato não é implantado

  Cenário: Implantação falha se o limite de inatividade for menor que a quantidade de validadores
    Dado que a implantação será feita por um usuário com permissão de deploy
    E foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E a lista inicial possui pelo menos 1 endereço de validador elegível sem duplicidades
    Mas o limite de inatividade informado é menor que o tamanho do conjunto de validadores elegíveis
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a transação deve ser revertida por limite de inatividade incompatível
    E o contrato não é implantado

  Esquema do Cenário: Implantação é recusada se os endereços dos contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós forem inválidos
    Dado que a implantação será feita por um usuário com permissão de deploy
    E os contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós não foram configurados corretamente
    E a lista inicial possui pelo menos 1 endereço de validador elegível sem duplicidades
    Mas o endereço do contrato "<contrato_dependente>" informado para a implantação é nulo (0x0)
    Quando o usuário executar o deploy do contrato de seleção de validadores
    Então a transação deve ser revertida
    E o contrato de seleção de validadores não é implantado

    Exemplos:
      | contrato_dependente |
      | AdminProxy          |
      | AccountRulesV2      |
      | NodeRulesV2         |