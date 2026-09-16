# language: pt
Funcionalidade: Atualização do endereço do contrato de admin no ingress
  Como governança da rede,
  Eu desejo atualizar o endereço do contrato de admin no ingress,
  Para migrar ou evoluir a lógica de permissões sem impactar a estrutura de roteamento da rede.

  Contexto:
    Dado que o contrato de ingress está implantado na rede
    E um contrato de admin está ativo no ingress

  Cenário: Governança atualiza o endereço do contrato de admin com sucesso
    Dado que a função será executada pela governança
    E o endereço do novo contrato de admin informado é diferente do atual
    E o endereço do novo contrato de admin não é zero (0x0)
    E é verificado com sucesso que o novo contrato de admin é compatível com os contratos atuais
    Quando a função de atualização do contrato de admin é acionada no ingress
    Então a transação deve ser concluída com sucesso
    E o endereço do contrato de admin no ingress é atualizado para o novo endereço
    E um evento registrando os endereços do contrato anterior e do contrato novo deve ser emitido

  Cenário: Atualização falha se o endereço do novo contrato de admin for zero (0x0)
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato de admin informado é zero (0x0)
    Quando a função de atualização do contrato de admin é acionada no ingress
    Então a transação deve ser revertida com erro de endereço inválido
    E o contrato de admin permanece inalterado

  Cenário: Atualização falha se o endereço do novo contrato for igual ao atual
    Dado que a função será executada pela governança
    Mas o endereço do novo contrato de admin informado é igual ao endereço ativo atualmente
    Quando a função de atualização do contrato de admin é acionada no ingress
    Então a transação deve ser revertida informando que o endereço é idêntico ao atual
    E o contrato de admin permanece inalterado

  Cenário: Atualização falha se o novo contrato não responder à verificação de compatibilidade
    Dado que a função será executada pela governança
    E o endereço do novo contrato de admin informado é válido e diferente do atual
    Mas o novo contrato de admin reverte ao verificar a compatibilidade
    Quando a função de atualização do contrato de admin é acionada no ingress
    Então a transação deve ser revertida por incompatibilidade de interface
    E o contrato de admin permanece inalterado

  Cenário: Atualização falha se não for executada com a devida permissão
    Dado que a chamada não será executada pela governança
    E o endereço do novo contrato de admin informado é válido e diferente do atual
    Quando a função de atualização do contrato de admin é acionada no ingress
    Então a transação deve ser revertida por falta de permissão
    E o contrato de admin permanece inalterado