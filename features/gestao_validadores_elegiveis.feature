Funcionalidade: Gestão de Validadores Elegíveis

Como a entidade Governance,
Eu desejo adicionar e remover endereços da lista de validadores elegíveis
Para controlar quais nós podem ser promovidos a validadores operacionais.

Contexto: Configuração Inicial
Dado o contrato 'ValidatorSelection' está inicializado
E 'Governance' é o endereço '0x8911B92560266d909766Ca745C346Ff5E5f9AFb2'
E 'UsuarioComum' é o endereço '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'


# --- Cenários para adição de novo validador ---

Cenário: Sucesso: 'Governance' adiciona um novo validador elegível (por endereço)
Dado que 'ValidadorNovo' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
Quando 'Governance' chama 'addElegibleValidator' passando 'ValidadorNovo'
Então 'ValidadorNovo' deve estar na lista de validadores elegíveis
E nenhum erro deve ser retornado

Cenário: Falha: 'UsuarioComum' tenta adicionar um validador elegível (por endereço)
Dado que 'ValidadorNovo' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
Quando 'UsuarioComum' chamar 'addElegibleValidator' com 'ValidadorNovo'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

Cenário: Sucesso: 'Governance' adiciona um novo validador elegível (por enode)
Dado que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
Quando 'Governance' chama 'addElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9' deve estar na lista de validadores elegíveis

Cenário: Falha: 'UsuarioComum' adiciona um novo validador elegível (por enode)
Dado que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
Quando 'UsuarioComum' chama 'addElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'


# --- Cenários para remoção de validador ---

Cenário: Sucesso: 'Governance' remove um validador elegível (por endereço)
Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'ValidadorElegível' está na lista de validadores elegíveis
Quando 'Governance' chama 'removeElegibleValidator' passando 'ValidadorElegível'
Então 'ValidadorElegível' não deve mais estar na lista de validadores elegíveis
E nenhum erro deve ser retornado

Cenário: Falha: 'Governance' tenta remover uma conta de nó não elegível (por endereço)
Dado que 'NóNãoElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'NóNãoElegível' não está na lista de validadores elegíveis
Quando 'Governance' chama 'removeElegibleValidator' passando 'NóNãoElegível'
Então a transação deve reverter
E a mensagem de erro deve ser 'NotElegibleNode'

Cenário: Falha: 'UsuarioComum' tenta remover um validador elegível (por endereço)
Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'ValidadorElegível' está na lista de validadores elegíveis
Quando 'UsuarioComum' chama 'removeElegibleValidator' passando 'ValidadorElegível'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

Cenário: Falha: 'UsuarioComum' tenta remover uma conta de nó não elegível (por endereço)
Dado que 'NóNãoElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'NóNãoElegível' não está na lista de validadores elegíveis
Quando 'UsuarioComum' chama 'removeElegibleValidator' passando 'NóNãoElegível'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

Cenário: Sucesso: 'Governance' remove um validador elegível (por enode)
Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'ValidadorElegível' está na lista de validadores elegíveis
Quando 'Governance' chama 'removeElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9' não deve estar na lista de validadores elegíveis

Cenário: Falha: 'Governance' tenta remover uma conta de nó não elegível (por enode)
Dado que 'NóNãoElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'NóNãoElegível' não está na lista de validadores elegíveis
Quando 'Governance' chama 'removeElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então a transação deve reverter
E a mensagem de erro deve ser 'NotElegibleNode'

Cenário: Falha: 'UsuarioComum' tenta remover um validador elegível (por enode)
Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'ValidadorElegível' está na lista de validadores elegíveis
Quando 'UsuarioComum' chama 'removeElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'

Cenário: Falha: 'UsuarioComum' tenta remover uma conta de nó não elegível (por enode)
Dado que 'NóNãoElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
E 'NóNãoElegível' está na lista de validadores elegíveis
Quando 'UsuarioComum' chama 'removeElegibleValidator' passando 'EnodeHigh' e 'EnodeLow'
Então a transação deve reverter
E a mensagem de erro deve ser 'UnauthorizedAccess'