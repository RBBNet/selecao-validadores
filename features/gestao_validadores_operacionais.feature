# language: pt
Funcionalidade: Gestão de Validadores Operacionais
Como a entidade Governance e administradores ativos,
Eu desejo adicionar e remover endereços da lista de validadores operacionais
Para controlar quais nós estão ativos como validadores na rede.

  Contexto: Configuração Inicial
    Dado o contrato 'ValidatorSelection' está inicializado
    E 'Governance' é o endereço '0x8911B92560266d909766Ca745C346Ff5E5f9AFb2'
    E 'UsuarioComum' é o endereço '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
    E 'AdminAtivo' é o endereço '0xe60406F62E6681ddA682406b665109bD3fBE0625'
# --- Cenários para adição de validador operacional ---

  Cenário: Sucesso: 'Governance' adiciona um validador operacional (por endereço)
    Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorElegível' está na lista de validadores elegíveis
    Quando 'Governance' chama 'addOperationalValidator' passando 'ValidadorElegível'
    Então 'ValidadorElegível' deve ser adicionado na lista de validadores operacionais
    E nenhum erro deve ser retornado

  Cenário: Falha: 'Governance' tenta adicionar um validador operacional não elegível (por endereço)
    Dado que 'NóNãoElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'NóNãoElegível' não está na lista de validadores elegíveis
    Quando 'Governance' chama 'addOperationalValidator' passando 'NóNãoElegível'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'NotElegibleNode'

  Cenário: Falha: 'UsuarioComum' tenta adicionar um validador operacional (por endereço)
    Dado que 'ValidadorElegível' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorElegível' está na lista de validadores elegíveis
    Quando 'UsuarioComum' chamar 'addOperationalValidator' passando 'ValidadorElegível'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'UnauthorizedAccess'

  Cenário: Sucesso: 'AdminAtivo' adiciona um validador operacional (por enode)
    Dado que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorElegível' está na lista de validadores elegíveis
    E 'AdminAtivo' pertence à mesma organização do enode
    Quando 'AdminAtivo' chama 'addOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9' deve ser adicionado na lista de validadores operacionais
    E nenhum erro deve ser retornado

  Cenário: Falha: 'AdminAtivo' tenta adicionar um validador operacional de outra organização (por enode)
    Dado que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorElegível' está na lista de validadores elegíveis
    E 'AdminAtivo' NÃO pertence à mesma organização do enode
    Quando 'AdminAtivo' chama 'addOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'NotLocalNode'

  Cenário: Falha: 'UsuarioComum' tenta adicionar um validador operacional (por enode)
    Dado que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    Quando 'UsuarioComum' chama 'addOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'UnauthorizedAccess'
# --- Cenários para remoção de validador operacional ---

  Cenário: Sucesso: 'Governance' remove um validador operacional (por endereço)
    Dado que 'ValidadorOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorOperacional' está na lista de validadores operacionais
    Quando 'Governance' chama 'removeOperationalValidator' passando 'ValidadorOperacional'
    Então 'ValidadorOperacional' deve ser removido da lista de validadores operacionais
    E nenhum erro deve ser retornado

  Cenário: Falha: 'Governance' tenta remover uma conta que não é validador operacional (por endereço)
    Dado que 'NóNãoOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'NóNãoOperacional' não está na lista de validadores operacionais
    Quando 'Governance' chama 'removeOperationalValidator' passando 'NóNãoOperacional'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'NotOperationalNode'

  Cenário: Falha: 'UsuarioComum' tenta remover um validador operacional (por endereço)
    Dado que 'ValidadorOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorOperacional' está na lista de validadores operacionais
    Quando 'UsuarioComum' chama 'removeOperationalValidator' passando 'ValidadorOperacional'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'UnauthorizedAccess'

  Cenário: Sucesso: 'AdminAtivo' remove um validador operacional (por enode)
    Dado que 'ValidadorOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorOperacional' está na lista de validadores operacionais
    E 'AdminAtivo' pertence à mesma organização do enode
    Quando 'AdminAtivo' chama 'removeOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9' deve ser removido da lista de validadores operacionais
    E nenhum erro deve ser retornado

  Cenário: Falha: 'AdminAtivo' tenta remover uma conta que não é validador operacional (por enode)
    Dado que 'NóNãoOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'NóNãoOperacional' não está na lista de validadores operacionais
    Quando 'AdminAtivo' chama 'removeOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'NotOperationalNode'

  Cenário: Falha: 'AdminAtivo' tenta remover um validador operacional de outra organização (por enode)
    Dado que 'ValidadorOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorOperacional' está na lista de validadores operacionais
    E 'AdminAtivo' NÃO pertence à mesma organização do enode
    Quando 'AdminAtivo' chama 'removeOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então a transação deve reverter
    E a mensagem de erro deve ser 'NotLocalNode'

  Cenário: Falha: 'UsuarioComum' tenta remover um validador operacional (por enode)
    Dado que 'ValidadorOperacional' é o endereço '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E que 'EnodeHigh' é '0x08ee0b92e0962e90036811d5fdc683fccad22303464b74b0e0e9271e88d7db64.'
    E 'EnodeLow' é '0xa476097d921324c21f90b21fc35850188aa97073e74da3fa707a0baeb4969725'
    E o endereço calculado é '0x484b67ecb3ae10fa984f7741ccd71ccc07dbdbb9'
    E 'ValidadorOperacional' está na lista de validadores operacionais
    Quando 'UsuarioComum' chama 'removeOperationalValidator' passando 'EnodeHigh' e 'EnodeLow'
    Então a transação deve reverter
    E a mensagem de erro
