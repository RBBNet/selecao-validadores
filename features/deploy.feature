# language: pt
Funcionalidade: Implantação do sistema de seleção de validadores
  Como operador da rede,
  Eu desejo implantar o contrato de seleção de validadores com uma lista inicial de validadores elegíveis,
  Para que a rede possa iniciar o processo de seleção e monitoramento de validadores.

  Cenário: Implantação com pelo menos quatro validadores elegíveis é concluída com sucesso
    Dado que os contratos de governança e permissionamento estão implantados
    E existe uma conta deployer autorizada
    E existe uma lista de pelo menos quatro endereços de validadores elegíveis
    Quando o contrato de seleção de validadores é implantado com essa lista
    Então o sistema de seleção de validadores fica disponível
    E a lista de validadores elegíveis contém os endereços informados

  Cenário: Implantação com menos de quatro validadores elegíveis é recusada
    Dado que os contratos de governança e permissionamento estão implantados
    E existe uma conta deployer autorizada
    E existe uma lista com menos de quatro endereços de validadores
    Quando alguém tenta implantar o contrato de seleção de validadores com essa lista
    Então a implantação é recusada
    E o sistema de seleção de validadores não fica disponível
