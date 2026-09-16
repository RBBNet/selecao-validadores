import { World, setWorldConstructor, Before } from '@cucumber/cucumber';
import hardhat from 'hardhat';

/**
 * Classe World do Cucumber
 * Cada cenário recebe uma instância nova, garantindo isolamento de estado
 */
export class TestWorld extends World {
    constructor(options) {
        super(options);

        // ========== Conexão e Signers ==========
        this.ethers = null;
        this.deployer = null;
        this.governance = null;
        this.adminLocal = null;
        this.unpermittedAccount = null;
        this.validator1 = null;
        this.validator2 = null;
        this.validator3 = null;
        this.validator4 = null;
        this.validator5 = null;
        this.newValidator = null;

        // ========== Contratos Principais ==========
        this.validatorSelection = undefined;
        this.ingress = undefined;

        // ========== Contratos Mock ==========
        this.adminMock = null;
        this.accountRulesMock = null;
        this.nodeRulesMock = null;
        this.adminProxy = null;

        // ========== Estado de Testes ==========
        this.caller = null;
        this.lastTxError = null;
        this.queryResult = undefined;
        this.receipt = null;

        // ========== Deploy (deploy_selecao.feature) ==========
        this.deployCaller = null;
        this.deployAdminAddr = undefined;
        this.deployAccountsAddr = undefined;
        this.deployNodesAddr = undefined;
        this.deployError = undefined;
        this.deployedValidatorSelection = undefined;

        // ========== Ingress (deploy_ingress.feature) ==========
        this.ingressContract = undefined;
        this.ingressAdminAddr = undefined;
        this.ingressSelectionAddr = undefined;
        this.ingressAdminBefore = undefined;
        this.ingressSelectionBefore = undefined;
        this.ingressNewSelectionAddr = undefined;

        // ========== Seleção (atualiza_selecao_ingress.feature) ==========
        this.newSelectionContract = undefined;

        // ========== Admin (atualiza_admin_ingress.feature) ==========
        this.newAdminContract = undefined;
        this.newAdminAddr = undefined;

        // ========== Accounts/Nodes (atualiza_contratos_selecao.feature) ==========
        this.newAccountsContract = undefined;
        this.newAccountsAddr = undefined;
        this.validatorsAccountsBefore = undefined;
        this.newNodesContract = undefined;
        this.newNodesAddr = undefined;
        this.validatorsNodesBefore = undefined;

        // ========== Admin (atualiza_admin_ingress.feature) ==========
        this.validatorsAdminBefore = undefined;

        // ========== Validadores (inclusao/remocao) ==========
        this.targetNodeAddr = undefined;
        this.enodeHigh = undefined;
        this.enodeLow = undefined;
        this.targetNodeKey = undefined;
        this.isEligibleRemoval = false;
        this.isRemoval = false;
        this.isOperational = false;

        // ========== Snapshots de Estado ==========
        this.eligibleBefore = undefined;
        this.operationalBefore = undefined;
        this.protectedBefore = undefined;
        this.eligibleBeforeExec = undefined;
        this.operationalBeforeExec = undefined;

        // ========== Monitoramento (monitoramento_e_selecao.feature) ==========
        this.txExec1 = undefined;
        this.txExec2 = undefined;

        // ========== Configuração ==========
        this.configBlocksBetween = undefined;
        this.configThreshold = undefined;
        this.idleLimitBefore = undefined;

        // ========== Modo de Operação ==========
        this.modeBefore = undefined;

        // ========== Admin Operacional ==========
        this.adminOrgId = undefined;

        // ========== Contador interno ==========
        this._enodeCounter = 1;

        // ========== Lista Inicial de Validadores ==========
        this.initialValidatorsList = [];
    }
}

// ========== Before Hook: Inicialização ==========
Before(async function () {
    this.ethers = hardhat.ethers;

    if (!this.ethers) {
        throw new Error("Erro: 'ethers' não foi inicializado pela conexão de rede do Hardhat.");
    }

    const signers = await this.ethers.getSigners();
    this.deployer = signers[0];
    this.governance = signers[1];
    this.adminLocal = signers[2];
    this.unpermittedAccount = signers[3];
    this.validator1 = signers[4];
    this.validator2 = signers[5];
    this.validator3 = signers[6];
    this.validator4 = signers[7];
    this.validator5 = signers[8];
    this.newValidator = signers[9];

    // Reset de variáveis de contexto do cenário
    this.caller = this.deployer;
    this.lastTxError = null;
    this.queryResult = undefined;

    // IMPORTANTE: validatorSelection/ingress são variáveis compartilhadas e cada Before()
    // cria uma rede EDR nova e isolada — sem resetar aqui, um Cenário poderia
    // reaproveitar por engano um contrato "fantasma" implantado na rede de um
    // Cenário anterior (que já não existe mais).
    this.validatorSelection = undefined;
    this.ingress = undefined;

    // Reset de contadores e estado específico de cenários
    this._enodeCounter = 1;
    this.initialValidatorsList = [];

    // Implantação dos Mocks básicos
    const AdminMockFactory = await this.ethers.getContractFactory("AdminMock");
    this.adminMock = await AdminMockFactory.deploy();
    await this.adminMock.waitForDeployment();
    await this.adminMock.addAdmin(this.governance.address);
    this.adminProxy = this.adminMock;

    const AccountRulesFactory = await this.ethers.getContractFactory("AccountRulesV2ConfigurableMock");
    this.accountRulesMock = await AccountRulesFactory.deploy();
    await this.accountRulesMock.waitForDeployment();

    const NodeRulesFactory = await this.ethers.getContractFactory("NodeRulesV2ConfigurableMock");
    this.nodeRulesMock = await NodeRulesFactory.deploy();
    await this.nodeRulesMock.waitForDeployment();
});

// Registrar a classe World com o Cucumber
setWorldConstructor(TestWorld);