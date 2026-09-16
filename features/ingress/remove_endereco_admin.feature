# language: pt
Funcionalidade: Remoção do endereço do contrato de admin no ingress
  Como governança da rede,
  Eu desejo remover o endereço do contrato de admin no ingress,
  Para desativar o vínculo de permissões administrativas em situações de migração ou emergência.

  Contexto:
    Dado que o contrato de ingress está implantado na rede
    E um contrato de admin está ativo e registrado no ingress

  Cenário: Governança remove o endereço do contrato de admin com sucesso
    Dado que a chamada é executada pela governança
    Quando a função de remoção do contrato de admin é acionada no ingress
    Então a transação deve ser concluída com sucesso
    E o endereço registrado para o contrato de admin passa a ser zero (0x0)
    E um evento registrando o endereço do contrato de admin removido deve ser emitido

  Cenário: Remoção falha se não for executada pela governança
    Dado que a chamada não será executada pela governança
    Quando a função de remoção do contrato de admin é acionada no ingress
    Então a transação deve ser revertida por falta de permissão
    E o endereço do contrato de admin registrado permanece inalterado