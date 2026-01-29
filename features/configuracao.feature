# Arquivo: configuracao_selecao.feature
Funcionalidade: Configuração de Parâmetros de Seleção

Como a entidade Governance,
Eu desejo definir os parâmetros de tempo e limite de inatividade
Para controlar a frequência e as regras de exclusão da seleção de validadores.

Contexto: Configuração Inicial
Dado o contrato 'ValidatorSelection' está inicializado
E 'blocksBetweenSelection' foi inicializado com o valor '100'
E 'blocksWithoutProposeThreshold' foi inicializado com o valor '100'
E 'nextSelectionBlock' foi inicializado com o valor '100'
E 'Governance' é o endereço '0x8911B92560266d909766Ca745C346Ff5E5f9AFb2'
E 'UsuarioComum' é o endereço '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266' sem permissões administrativas

# --- Cenários para setBlocksBetweenSelection ---

Cenário: Sucesso: Governance define o intervalo entre seleções
Dado que 'blocksBetweenSelection' atual é '100'
Quando 'Governance' chama 'setBlocksBetweenSelection' com o valor '200'
Então o valor de 'blocksBetweenSelection' deve ser '200'

Cenário: Falha: Usuário Comum tenta definir o intervalo entre seleções
Dado que 'blocksBetweenSelection' atual é '100'
Quando 'UsuarioComum' tenta chamar 'setBlocksBetweenSelection' com o valor '200'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

# --- Cenários para setBlocksWithoutProposeThreshold ---

Cenário: Sucesso: Governance define o limite de inatividade
Dado que 'blocksWithoutProposeThreshold' atual é '100'
Quando 'Governance' chama 'setBlocksWithoutProposeThreshold' com o valor '50'
Então o valor de 'blocksWithoutProposeThreshold' deve ser '50'

Cenário: Falha: Usuário Comum tenta definir o limite de inatividade
Dado que 'blocksWithoutProposeThreshold' atual é '100'
Quando 'UsuarioComum' tenta chamar 'setBlocksWithoutProposeThreshold' com o valor '50'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

# --- Cenários para setNextSelectionBlock ---

Cenário: Sucesso: Governance define o próximo bloco de seleção
Dado que 'nextSelectionBlock' atual é '100'
Quando 'Governance' chama 'setNextSelectionBlock' com o valor '200'
Então o valor de 'nextSelectionBlock' deve ser '200'

Cenário: Falha: Usuário Comum tenta definir o próximo bloco de seleção
Dado que 'nextSelectionBlock' atual é '100'
Quando 'UsuarioComum' tenta chamar 'setNextSelectionBlock' com o valor '200'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'