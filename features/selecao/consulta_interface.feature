# language: pt
Funcionalidade: Consulta de suporte a interfaces no contrato de seleção de validadores
  Como usuário da rede,
  Eu desejo consultar se o contrato de seleção de validadores implementa uma interface especificada,
  Para verificar a compatibilidade técnica e a conformidade com o padrão erc-165.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado na rede

  Cenário: Consulta ao identificador da própria interface erc-165 retorna verdadeiro
    Dado que a chamada de consulta é executada por qualquer conta da rede
    Quando a função de verificação de suporte a interface é acionada informando o identificador da interface erc-165
    Então a chamada de leitura deve ser concluída com sucesso
    E o contrato deve retornar o valor booleano verdadeiro

  Cenário: Consulta ao identificador da interface de seleção de validadores retorna verdadeiro
    Dado que a chamada de consulta é executada por qualquer conta da rede
    Quando a função de verificação de suporte a interface é acionada informando o identificador da interface de seleção de validadores
    Então a chamada de leitura deve ser concluída com sucesso
    E o contrato deve retornar o valor booleano verdadeiro

  Cenário: Consulta a um identificador de interface não suportado retorna falso
    Dado que a chamada de consulta é executada por qualquer conta da rede
    Quando a função de verificação de suporte a interface é acionada informando um identificador não suportado ou inválido
    Então o contrato deve retornar o valor booleano falso