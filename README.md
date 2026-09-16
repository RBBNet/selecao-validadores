# Seleção de Validadores — Rede Blockchain Brasil (RBB)

Mecanismo de seleção de validadores da Rede Blockchain Brasil (RBB), responsável pelo gerenciamento dinâmico do conjunto de validadores do consenso, pela monitoração de disponibilidade (*liveness*) e pela rotação automática de nós inoperantes para manutenção do SLA da rede.

O sistema é composto por dois contratos inteligentes:
* `ValidatorSelection`: contrato de lógica que gerencia os conjuntos de validadores (elegíveis e operacionais), regras de permissão e o algoritmo de monitoramento de produção de blocos.
* `ValidatorSelectionIngress`: fachada de endereço fixo que expõe a interface de consulta ao Besu e delega as chamadas ao contrato de lógica atualmente registrado.

Adicionalmente, cada partícipe da rede executa um agente externo de monitoramento (fora do escopo deste repositório) que aciona periodicamente `executeMonitoring()` no contrato de lógica para identificação e remoção automática de nós inoperantes.

Para os detalhes da arquitetura dos contratos, modelo de dados, modos de operação, algoritmo de monitoramento e referência de funções/erros, consulte [`src/README.md`](src/README.md).

## 1. Pré-requisitos

* [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`).
* Contratos de permissionamento (`AdminProxy`, `AccountRulesV2`, `NodeRulesV2`) implantados na rede de destino.

## 2. Instalação

```bash
git clone <url-do-repositorio>
cd selecao-validadores-rbb
git submodule update --init --recursive
forge build
```

Variáveis de ambiente necessárias para a execução dos scripts de deploy estão descritas em [`.env.example`](.env.example) (`PRIVATE_KEY`).

## 3. Compilação e Testes

O repositório possui três suítes de teste complementares:

```bash
# Compilação
forge build

# Suíte de testes unitários (Foundry)
forge test
forge test --summary
```

* **Testes Unitários (Foundry)**: Validação da lógica interna dos contratos e transições de estado isoladas.
* **Especificações BDD (Cucumber)**: Validação comportamental baseada em cenários Gherkin sobre rede Hardhat. Consulte [`features/README.md`](features/README.md) para instruções de execução.
* **Testes Ponta a Ponta (E2E)**: Validação integrada contra um cluster de 6 nós Besu QBFT em Docker. Consulte [`test/e2e/README.md`](test/e2e/README.md) para detalhes da suíte E2E.

## 4. Visão Geral da Implantação e Transição de Gênesis

A implantação do mecanismo ocorre em **duas etapas sequenciais**, seguidas da transição de gênesis nos nós Besu da rede:

1. **Deploy do Contrato de Lógica (`ValidatorSelection`)**: Implanta a regra de negócio com a lista inicial de validadores elegíveis/operacionais e parâmetros de monitoramento.
2. **Deploy do Ingress (`ValidatorSelectionIngress`)**: Implanta o ponto de entrada fixo da rede apontando para o contrato de lógica implantado na Etapa 1.
3. **Transição de Gênesis**: Atualização da chave `config.transitions.qbft` no arquivo `genesis.json` de todos os nós da rede para o modo `contract`, informando o endereço do Ingress.

```
 1. Implantar ValidatorSelection (Lógica) ..... forge script script/Deploy.s.sol
        │
 2. Implantar ValidatorSelectionIngress ....... forge script script/DeployIngress.s.sol
        │
 ═══════╪═══ EXIGE COORDENAÇÃO DE TODA A REDE ═════════════════════════════════
        │
 3. Definir o bloco N da transição e atualizar genesis.json nos nós Besu
        │
 4. BLOCO N — O Besu passa a consultar getValidators() no Ingress
```

Para o detalhamento do arquivo [`script/data/config.json`](script/data/config.json), variáveis de ambiente, modelo de `genesis.json` e comandos de execução dos scripts de deploy, consulte a [**Documentação de Scripts de Implantação**](script/README.md).

## 5. Licença

[GPL-3.0-only](LICENSE).

