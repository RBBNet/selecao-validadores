# language: pt

Funcionalidade: Implantação do Contrato de Seleção de Validadores

Contexto:
Dado que os contratos inteligentes de governança (Governance) estão implantados
E os contratos inteligentes de permissionamento (gen02) estão implantados
E o endereço '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' é de uma conta com papel "DEPLOYER_ROLE"
E o endereço '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d' é do nó validador do BNDES
E o endereço '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a' é do nó validador do TCU
E o endereço '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6' é do nó validador da DATAPREV
E o endereço '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a' é do nó validador da PUC-Rio
E o endereço '0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba' é do nó validador do CPQD
E o endereço '0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356' é do nó validador da PRODEMGE
E o endereço '0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97' é do nó validador do SERPRO
E o endereço '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6' é do nó validador do IBICT
E o endereço '0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0' é do nó validador do PLEXOS

Cenário: Implantação de contrato considerando pelo menos 4 validadores elegíveis
Dado a conta '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
E 'listaValidaDeValidadores' é uma lista de tamanho maior ou igual a 4 contendo apenas endereços de nós validadores na rede
Quando implanto o contrato inteligente de seleção de validadores passando a 'listaValidaDeValidadores'
Então a implantação do contrato inteligente de seleção de validadores ocorre com sucesso

Cenário: Implantação de contrato considerando pelo de 4 validadores elegíveis
Dado a conta '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
E 'listaInvalidaDeValidadores' é uma lista de tamanho menor que 4
Quando implanto o contrato inteligente de seleção de validadores passando a 'listaInvalidaDeValidadores'
Então ocorre erro na implantação do contrato inteligente de seleção de validadores