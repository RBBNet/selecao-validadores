# language: pt
Funcionalidade: Atualização do contrato de implementação
  Como governança da rede,
  Eu desejo atualizar o contrato de seleção de validadores, via atualização do endereço no contrato de proxy,
  Para que que seja possível adicionar e remover funcionalidades em novas versões do contrato.

  Contexto:
    Dado que o contrato de seleção de validadores está implantado
    E o contrato está na versão inicial

  Cenário: Atualização bem-sucedida das regras do sistema
    Dado que o sistema está operando com a versão inicial
    Quando a Governaça aplica uma nova versão de regras
    Então o sistema deve passar a se comportar conforme as novas definições

  Cenário: Preservação de dados após atualização
    Dado que existem informações registradas na versão atual
    Quando o sistema é atualizado para uma nova versão
    Então todos os dados registrados anteriormente devem permanecer intactos e acessíveis

  Cenário: Impedir que usuários comuns alterem o sistema
    Quando um usuário sem privilégios tenta atualizar as regras do sistema
    Então a tentativa deve ser rejeitada
    E o sistema deve permanecer operando com as regras vigentes
