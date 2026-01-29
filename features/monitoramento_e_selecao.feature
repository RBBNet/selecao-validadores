# language: pt
Funcionalidade: Monitoramento e Seleção de Validadores
    Como o sistema de seleção de validadores,
    Eu devo monitorar a atividade de proposta de blocos dos validadores operacionais
    E executar a seleção e remoção de validadores inativos periodicamente,
    Garantindo que a rede mantenha um quorum saudável e ativo.

  Contexto: Configuração de Limites
    Dado o contrato 'ValidatorSelection' está inicializado
    E 'blocksBetweenSelection' está configurado para '100'
    E 'blocksWithoutProposeThreshold' está configurado para '100'
    E 'nextSelectionBlock' está configurado para o bloco '1000'
    E a lista operacional inicialmente contém 8 validadores ativos

  Cenário: Sucesso: Validador Propõe bloco e é monitorado
    Dado que o número do bloco atual é simulado como '200'
    E o nó '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' validou o bloco '200'
    Quando 'monitorsValidators' é chamado (por qualquer conta)
    Então o valor de 'lastBlockProposedBy[0x70997970C51812dc3A010C7d01b50e0d17dc79C8]' deve ser '200'
    E o evento 'MonitorExecuted' deve ser emitido

  Cenário: Falha: Mesma chamada no mesmo bloco é ignorada
    Dado que o número do bloco atual é simulado como '200'
    E o nó '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' validou o bloco '200'
    E uma transação de 'monitorsValidators' já foi processada no bloco '200'
    Quando outra transação 'monitorsValidators' é processada no bloco '200' (originada de qualquer conta)
    Então o valor de 'lastBlockProposedBy[0x70997970C51812dc3A010C7d01b50e0d17dc79C8]' deve ser '200' (inalterado)
    E o evento 'MonitorExecuted' não deve ser emitido novamente

  Cenário: Seleção não deve ser acionada antes do bloco de seleção
    Dado que o número do bloco atual é simulado como '999'
    E 'nextSelectionBlock' é '1000'
    Quando um validador chama 'monitorsValidators'
    Então a função de remoção ('_selectValidators') não deve ser chamada
    E a função de atualização da seleção ('_updateNextSelectionBlock') não deve ser chamada
    E 'nextSelectionBlock' deve permanecer '1000'

  Cenário: Seleção é acionada no bloco de seleção
    Dado que o número do bloco atual é simulado como '1000'
    E 'nextSelectionBlock' é '1000'
    E 'blocksBetweenSelection' é '100'
    Quando um validador chama 'monitorsValidators'
    Então a função de seleção ('_selectValidators') deve ser chamada
    E 'nextSelectionBlock' deve ser atualizado para '1100'

  Cenário: Ocorre a seleção, mas todos os validadores operacionais estão ativos
    Dado que o número do bloco atual é simulado como '1000'
    E 'blocksWithoutProposeThreshold' é '10'
    E 'nextSelectionBlock' é '1000'
    E a atividade de proposta para os validadores é:
      | Validador                                  | lastBlockProposedBy |
      | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 |                1000 |
      | 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC |                 999 |
      | 0x90F79bf6EB2c4f870365E785982E1f101E93b906 |                 998 |
      | 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc |                 997 |
      | 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 |                 996 |
      | 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f |                 995 |
      | 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 |                 994 |
      | 0x2546BcD3c84621e976D8185a91A922aE77ECEc30 |                 993 |
    Quando 'monitorsValidators' é chamado
    Então '_isAtSelectionBlock' deve ser executada
    E a lista de validadores operacionais não deve ser alterada
    E '_updateNextSelectionBlock' deve ser executada
    E 'nextSelectionBlock' deve ser atualizado para '1100'

  Cenário: Remoção de validadores operacionais inativos
    Dado que o número do bloco atual é simulado como '1000'
    E 'blocksWithoutProposeThreshold' é '10'
    E 'nextSelectionBlock' é '1000'
    E a atividade de proposta para os validadores é:
      | Validador                                  | lastBlockProposedBy |
      | 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 |                1000 |
      | 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC |                 999 |
      | 0x90F79bf6EB2c4f870365E785982E1f101E93b906 |                 998 |
      | 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc |                 997 |
      | 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 |                 996 |
      | 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f |                 995 |
      | 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 |                 980 |
      | 0x2546BcD3c84621e976D8185a91A922aE77ECEc30 |                 970 |
    Quando 'monitorsValidators' é chamado
    Então '_isAtSelectionBlock' deve ser executada
    E os validadores '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720' e '0x2546BcD3c84621e976D8185a91A922aE77ECEc30' devem ser selecionados para serem removidos
    E a lista de validadores operacionais deve ser alterada, removendo os validadores selecionados
    E '_updateNextSelectionBlock' deve ser executada
    E 'nextSelectionBlock' deve ser atualizado para '1100'

  Cenário: Validador operacional inativo não deve ser removido se o quorum for violado
    Dado que o número do bloco atual é simulado como '1000'
    E a lista operacional contém apenas 5 validadores: ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8', '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', '0x90F79bf6EB2c4f870365E785982E1f101E93b906', '0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc', '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955']
    E dois validadores ('0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc', '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955') estão inativos (diferença > limite de inatividade)
    Quando um validador chama 'monitorsValidators'
    Então a lógica '_selectValidators' deve listar ['0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc', '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955']
    E a lógica '_doesItNeedRemoval' deve retornar 'false' (para manter o quorum mínimo de 4)
    E a lista operacional deve permanecer inalterada
