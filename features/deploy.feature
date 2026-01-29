# language: pt
Funcionalidade: Implantação do Contrato de Seleção de Validadores

  Contexto:
    Dado que os contratos inteligentes de governança (Governance) estão implantados
    E os contratos inteligentes de permissionamento (gen02) estão implantados
    E o endereço '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266' é de uma conta com papel "DEPLOYER_ROLE"
    E o endereço '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' é do nó validador do BNDES
    E o endereço '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC' é do nó validador do TCU
    E o endereço '0x90F79bf6EB2c4f870365E785982E1f101E93b906' é do nó validador da DATAPREV
    E o endereço '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65' é do nó validador da PUC-Rio
    E o endereço '0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc' é do nó validador do CPQD
    E o endereço '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955' é do nó validador da PRODEMGE
    E o endereço '0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f' é do nó validador do SERPRO
    E o endereço '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720' é do nó validador do IBICT
    E o endereço '0x2546BcD3c84621e976D8185a91A922aE77ECEc30' é do nó validador do PLEXOS

  Cenário: Implantação de contrato considerando pelo menos 4 validadores elegíveis
    Dado a conta '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
    E 'listaValidaDeValidadores' é uma lista de tamanho maior ou igual a 4 contendo apenas endereços de nós validadores na rede
    Quando implanto o contrato inteligente de seleção de validadores passando a 'listaValidaDeValidadores'
    Então a implantação do contrato inteligente de seleção de validadores ocorre com sucesso

  Cenário: Implantação de contrato considerando pelo de 4 validadores elegíveis
    Dado a conta '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
    E 'listaInvalidaDeValidadores' é uma lista de tamanho menor que 4
    Quando implanto o contrato inteligente de seleção de validadores passando a 'listaInvalidaDeValidadores'
    Então ocorre erro na implantação do contrato inteligente de seleção de validadores
