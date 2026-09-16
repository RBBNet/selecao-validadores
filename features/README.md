# Suíte de Testes BDD / Especificações de Comportamento (Cucumber)

Especificações de comportamento (*Behavior-Driven Development* — BDD) em Gherkin e Cucumber.js para validação das regras de negócio, interfaces e controle de acesso dos contratos `ValidatorSelection` e `ValidatorSelectionIngress`.

As especificações em `.feature` funcionam como documentação viva do sistema, descrevendo a lógica dos contratos a partir das regras de governança, restrições operacionais e fluxos de exceção. Os testes são executados em ambiente Hardhat (EVM/EDR), oferecendo execução determinística e isolada por cenário.

Para a visão geral do repositório, consulte [`README.md`](../README.md). Para a especificação dos contratos, consulte [`src/README.md`](../src/README.md). Para os testes E2E com nós Besu reais, consulte [`test/e2e/README.md`](../test/e2e/README.md).

## 1. Estrutura do Diretório

```
features/
├── ingress/                               # Especificações do Ingress (ValidatorSelectionIngress)
│   ├── deploy_ingress.feature             # Deploy e validação de interfaces
│   ├── consulta_validadores.feature        # Consulta da lista operacional (getValidators) e salvaguarda
│   ├── consulta_enderecos.feature          # Consulta dos contratos registrados
│   ├── atualiza_endereco_selecao.feature   # Atualização do contrato de lógica
│   ├── remove_endereco_selecao.feature     # Desvinculação do contrato de lógica
│   ├── atualiza_endereco_admin.feature     # Atualização do contrato AdminProxy
│   └── remove_endereco_admin.feature       # Desvinculação do contrato AdminProxy
│
├── selecao/                               # Especificações de Lógica (ValidatorSelection)
│   ├── deploy_selecao.feature              # Deploy, inicialização dos conjuntos e pisos mínimos
│   ├── configuracao.feature                # Parâmetros de ciclo (blocksBetweenSelection, blocksWithoutProposeThreshold)
│   ├── inclusao_validador_elegivel.feature # Adição ao conjunto de elegíveis
│   ├── remocao_validador_elegivel.feature  # Remoção de elegíveis
│   ├── inclusao_validador_operacional.feature # Ativação manual de operacionais
│   ├── remocao_validador_operacional.feature  # Desativação manual de operacionais
│   ├── mudanca_modo_operacao.feature       # Alternância entre modo Manual (0) e Automático (1)
│   ├── monitoramento_e_selecao.feature     # Algoritmo de monitoramento automático (executeMonitoring)
│   ├── atualiza_contrato_admin.feature     # Atualização do endereço AdminProxy
│   ├── atualiza_contrato_contas.feature    # Atualização do contrato AccountRulesV2
│   ├── atualiza_contrato_nos.feature       # Atualização do contrato NodeRulesV2
│   ├── atualiza_contrato_selecao.feature   # Auto-governança
│   └── consulta_interface.feature          # Inspeção de estado público, getters e enodes
│
└── step_definitions/                      # Implementação dos passos (Cucumber.js + Ethers.js)
    ├── cucumber-world.js                   # Classe TestWorld (contexto isolado, signers e mocks)
    ├── ingress/                            # Passos associados a features/ingress/
    ├── selecao/                            # Passos associados a features/selecao/
    └── support/                            # Utilidades auxiliares (cucumber-helpers.js)
```

## 2. Escopo dos Módulos

### 2.1 `features/ingress/` (ValidatorSelectionIngress)

Especificações do ponto de entrada fixo da rede:

* Validações de deploy: rejeita implantações com endereços nulos (`0x0`), contratos incompatíveis ou quando a lógica inicial retorna lista vazia (`getValidators().length == 0`).
* Mecanismo de salvaguarda (*fallback*): valida se `getValidators()` delega a chamada ao contrato de lógica ou retorna o proponente atual (`block.coinbase`) em caso de falha.
* Gerenciamento de referências: garante restrição de acesso nas funções de atualização (`updateValidatorSelectionContract`, `updateAdminContract`).

### 2.2 `features/selecao/` (ValidatorSelection)

Especificações da regra de negócio central:

* Conjuntos de validadores: valida as operações sobre `eligibleValidators`, `operationalValidators` e `protectedValidators`, assegurando a invariante `protectedValidators ⊆ operationalValidators ⊆ eligibleValidators`.
* Pisos de segurança: rejeita remoções que reduzam os validadores operacionais abaixo do limite mínimo (4 para administradores/monitoramento e 1 para governança).
* Modos de operação: testa a alternância entre `Manual` (0) e `Automatic` (1).
* Monitoramento automático (`executeMonitoring`): valida a contagem de blocos por validador (`blocksBetweenSelection`), estouro do limite de inatividade (`blocksWithoutProposeThreshold`) e o ciclo de proteção temporária.
* Permissionamento: verifica o controle de acesso com os contratos `AdminProxy`, `AccountRulesV2` e `NodeRulesV2`.

### 2.3 `features/step_definitions/` (Infraestrutura de Testes)

A classe `TestWorld` (`cucumber-world.js`) instancia o ambiente EVM Hardhat a cada cenário (hook `Before`), injetando contas signatárias pré-configuradas (`deployer`, `governance`, `adminLocal`, `unpermittedAccount`, `validator1..5`, `newValidator`) e contratos mock (`AdminMock`, `AccountRulesV2ConfigurableMock`, `NodeRulesV2ConfigurableMock`).

## 3. Execução dos Testes

Instalação das dependências na raiz do projeto:
```bash
npm install
```

### Executar a suíte completa
```bash
npm test
```
*(Executa `hardhat compile && cucumber-js`)*

### Validação de sintaxe (*dry-run*)
```bash
npm run test:dry
```

### Execuções seletivas
```bash
# Executar um arquivo de feature específico
npx cucumber-js features/ingress/deploy_ingress.feature
npx cucumber-js features/selecao/monitoramento_e_selecao.feature

# Executar um diretório de especificações
npx cucumber-js features/ingress/
npx cucumber-js features/selecao/

# Filtrar cenários pelo nome
npx cucumber-js --name "Implantação bem-sucedida"
```
