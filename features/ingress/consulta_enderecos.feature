# language: pt
Funcionalidade: Consulta de endereços registrados no ingress
  Como usuário da rede,
  Eu desejo consultar os endereços dos contratos de seleção e de admin registrados no ingress,
  Para garantir a transparência e a auditoria do ponto de acesso da rede.

  Contexto:
    Dado que o contrato de ingress está implantado na rede

  Cenário: Consulta ao endereço do contrato de admin registrado retorna o endereço ativo
    Dado que a chamada de consulta é executada por qualquer conta da rede
    Quando a função de consulta do endereço de admin é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso
    E o endereço atual do contrato de admin é retornado

  Cenário: Consulta ao endereço do contrato de seleção registrado retorna o endereço ativo
    Dado que a chamada de consulta é executada por qualquer conta da rede
    Quando a função de consulta do endereço de seleção é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso
    E o endereço atual do contrato de seleção de validadores é retornado