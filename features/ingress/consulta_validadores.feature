# language: pt
Funcionalidade: Consulta aos validadores operacionais no ingress
  Como cliente Besu ou qualquer conta da rede,
  Eu desejo consultar o conjunto de validadores operacionais no contrato de ingress,
  Para obter a lista de nós utilizada pela rede de forma contínua e segura.

  Contexto:
    Dado que o contrato de ingress está implantado na rede

  Cenário: Consulta de validadores operacionais feita com sucesso
    Dado que a chamada de leitura é executada por qualquer conta ou cliente Besu
    E existe um contrato de seleção de validadores registrado e funcional no ingress
    E a chamada ao contrato de seleção retorna uma lista contendo pelo menos 1 validador operacional
    Quando a função de consulta de validadores operacionais é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso
    E a lista de validadores operacionais da rede é retornada

  Cenário: Fallback é acionado se o endereço do contrato de seleção de validadores registrado for zero (0x0)
    Dado que a chamada de leitura é executada por qualquer conta ou cliente Besu
    Mas o endereço registrado no ingress para o contrato de seleção de validadores é zero (0x0)
    Quando a função de consulta de validadores operacionais é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso sem propagar erro
    E o ingress deve acionar o mecanismo de fallback
    E o ingress deve retornar uma lista contendo unicamente o endereço do validador do bloco atual

  Cenário: Fallback é acionado se a chamada ao contrato de seleção de validadores reverter
    Dado que a chamada de leitura é executada por qualquer conta ou cliente Besu
    E existe um contrato de seleção de validadores registrado no ingress
    Mas a execução da consulta reverte no contrato de seleção de validadores
    Quando a função de consulta de validadores operacionais é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso sem propagar erro ou reversão
    E o ingress deve acionar o mecanismo de fallback
    E o ingress deve retornar uma lista contendo unicamente o endereço do validador do bloco atual

  Cenário: Fallback é acionado se o contrato de seleção de validadores retornar uma lista vazia
    Dado que a chamada de leitura é executada por qualquer conta ou cliente Besu
    E existe um contrato de seleção de validadores registrado no ingress
    Mas a chamada ao contrato de seleção de validadores retorna uma lista vazia
    Quando a função de consulta de validadores operacionais é acionada no ingress
    Então a chamada de leitura deve ser concluída com sucesso sem propagar erro
    E o ingress deve acionar o mecanismo de fallback
    E o ingress deve retornar uma lista contendo unicamente o endereço do validador do bloco atual