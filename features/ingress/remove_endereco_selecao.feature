# language: pt
Funcionalidade: Remoção do endereço do contrato de seleção de validadores no ingress
  Como governança da rede,
  Eu desejo remover o endereço do contrato de seleção de validadores do ingress,
  Para cessar o redirecionamento em situações excepcionais de falha grave.

  Contexto:
    Dado que o contrato de ingress está implantado na rede
    E existe um contrato de seleção de validadores registrado no ingress

  Cenário: Governança remove o endereço do contrato de seleção com sucesso
    Dado que a chamada é executada pela governança
    Quando a função de remoção do contrato de seleção é acionada no ingress
    Então a transação deve ser concluída com sucesso
    E o endereço registrado para o contrato de seleção passa a ser zero (0x0)
    E um evento registrando a remoção do contrato deve ser emitido

  Cenário: Remoção falha se o chamador não possuir permissão
    Dado que a função não será executada pela governança
    Quando a função de remoção do contrato de seleção é acionada no ingress
    Então a transação deve ser revertida por falta de permissão
    E o endereço do contrato de seleção registrado permanece inalterado
