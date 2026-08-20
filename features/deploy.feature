# language: pt
Funcionalidade: Implantação do código on chain da seleção de validadores
  Como usuário da rede,
  Eu desejo implantar o contrato de seleção de validadores com uma lista inicial de validadores elegíveis,
  Para que a rede possa iniciar o processo de seleção e monitoramento de validadores.

  Cenário: Implantação bem-sucedida inicializando as listas e o modo manual
    Dado que o usuário utiliza uma conta com permissão de deploy
    E possui uma lista com pelo menos 1 endereços de validadores elegíveis
    E define o intervalo entre seleções maior ou igual a 1
    E define o limite de inatividade tolerado como maior ou igual ao tamanho da lista de validadores elegíveis
    Quando o usuário implanta o contrato de seleção de validadores passando os endereços dos contratos de gestão de Admin, gestão de permissionamento de contas e gestão de permissionamento de nós
    Então a implantação deve ser concluída com sucesso
    E o sistema de seleção de validadores fica disponível
    E o modo de operação do contrato deve ser inicializado como Manual
    E a lista de validadores Elegíveis deve conter os endereços informados
    E a lista de validadores Operacionais deve conter os mesmos endereços informados
    E a lista de validadores Adicionados deve estar vazia

  Cenário: Implantação com menos de um validador elegível é recusada
    Dado que foi configurado os endereços dos contratos de gestão de Admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E o usuário utiliza uma conta com permissão de deploy
    E possui uma lista com menos de 1 endereço de validador elegível
    Quando alguém tenta implantar o contrato de seleção de validadores com essa lista com menos de um validador
    Então a transação deve ser revertida com erro de nenhum nó validador encontrado
    E o contrato não é implantado # nos cenários abaixo, você fala que a transação é revertida. Aqui também é, mas você não fala. Verifique se precisamos falar sobre isso este arquivo e siga isso como padrão para todos os cenários.

  Cenário: Implantação falha se o intervalo entre seleções for menor que o permitido
    Dado que foi configurado os endereços dos contratos de gestão de Admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E o usuário utiliza uma conta com permissão de deploy
    E possui uma lista com pelo menos 1 endereço de validador elegível
    Mas informa que o intervalo entre seleções está menor do que 1
    Quando o usuário tenta implantar o contrato de seleção de validadores
    Então a transação deve ser revertida com erro de intervalo inválido
    E o contrato não é implantado

  Cenário: Implantação falha se o limite de inatividade for menor que a quantidade de validadores
    Dado que o usuário utiliza uma conta com permissão de deploy
    E possui uma lista com pelo menos 1 endereço de validador elegível
    Mas informa o limite de inatividade tolerado como menor que o tamanho da lista de validadores elegíveis
    Quando o usuário tenta implantar o contrato de seleção de validadores
    Então a transação deve ser revertida por limite de inatividade incompatível
    E o contrato não é implantado

  Esquema do Cenário: Implantação é recusada se os endereços dos contratos base forem inválidos
    Dado que foi configurado os endereços dos contratos de gestão de Admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente
    E o usuário utiliza uma conta com permissão de deploy
    E possui uma lista com pelo menos 1 endereço de validador elegível
    Mas o endereço do contrato "<contrato_dependente>" informado para a implantação é nulo (0x0)
    Quando eu tento implantar o contrato de Seleção de Validadores
    Então a transação deve ser revertida
    E o contrato de seleção de validadores não é implantado

    Exemplos:
      | contrato_dependente |
      | AdminProxy          |
      | AccountRulesV2      |
      | NodeRulesV2         |