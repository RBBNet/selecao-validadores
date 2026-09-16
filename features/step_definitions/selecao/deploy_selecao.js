import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    getStandardValidatorsList,
    assertSameAddressSet,
    getLastError,
    extractRevertErrorName,
    deployStandardValidatorSelection
} from '../support/cucumber-helpers.js';

Given('que a implantação será feita por um usuário com permissão de deploy', function () {
    this.deployCaller = this.deployer;
    this.deployAdminAddr = undefined;
    this.deployAccountsAddr = undefined;
    this.deployNodesAddr = undefined;
    this.deployError = undefined;
    this.deployedValidatorSelection = undefined;
});

Given('foram configurados os endereços de contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós corretamente', async function () {
    this.deployAdminAddr = await this.adminMock.getAddress();
    this.deployAccountsAddr = await this.accountRulesMock.getAddress();
    this.deployNodesAddr = await this.nodeRulesMock.getAddress();
});

Given('os contratos de gestão de admin, gestão de permissionamento de contas e gestão de permissionamento de nós não foram configurados corretamente', function () {
    this.deployAdminAddr = this.ethers.ZeroAddress;
    this.deployAccountsAddr = this.ethers.ZeroAddress;
    this.deployNodesAddr = this.ethers.ZeroAddress;
});

Given('a lista inicial possui pelo menos 1 endereço de validador elegível sem duplicidades', function () {
    this.deployInitialValidators = getStandardValidatorsList(this);
});

Given(/^a lista inicial possui 0 validadores \(vazia\)$/, function () {
    this.deployInitialValidators = [];
});

Given('a lista inicial possui endereços de validadores duplicados', function () {
    const list = getStandardValidatorsList(this);
    list[4] = list[0];
    this.deployInitialValidators = list;
});

Given('o intervalo definido entre seleções é maior ou igual a 1', function () {
    this.deployBlocksBetweenSelection = 2;
});

Given('o intervalo informado entre seleções é 0', function () {
    this.deployBlocksBetweenSelection = 0;
});

Given('o limite de inatividade definido é maior ou igual ao tamanho do conjunto de validadores elegíveis', function () {
    this.deployBlocksWithoutProposeThreshold = this.deployInitialValidators.length;
});

Given('o limite de inatividade informado é menor que o tamanho do conjunto de validadores elegíveis', function () {
    this.deployBlocksWithoutProposeThreshold = Math.max(this.deployInitialValidators.length - 1, 0);
});

Given(/^o endereço do contrato "([^"]+)" informado para a implantação é nulo \(0x0\)$/, function (contratoDependente) {
    if (contratoDependente === 'AdminProxy') this.deployAdminAddr = this.ethers.ZeroAddress;
    else if (contratoDependente === 'AccountRulesV2') this.deployAccountsAddr = this.ethers.ZeroAddress;
    else if (contratoDependente === 'NodeRulesV2') this.deployNodesAddr = this.ethers.ZeroAddress;
});

When('o usuário executar o deploy do contrato de seleção de validadores', async function () {
    const ValidatorSelectionFactory = await this.ethers.getContractFactory("ValidatorSelection");
    const blocksBetweenSelection = this.deployBlocksBetweenSelection ?? 2;
    const blocksWithoutProposeThreshold = this.deployBlocksWithoutProposeThreshold ?? (this.deployInitialValidators?.length || 5);

    try {
        this.deployedValidatorSelection = await ValidatorSelectionFactory.connect(this.deployCaller).deploy(
            this.deployAdminAddr,
            this.deployAccountsAddr,
            this.deployNodesAddr,
            this.deployInitialValidators || [],
            blocksBetweenSelection,
            blocksWithoutProposeThreshold,
            10
        );
        await this.deployedValidatorSelection.waitForDeployment();

        this.validatorSelection = this.deployedValidatorSelection;
        this.deployError = null;
        this.lastTxError = null;
    } catch (err) {
        this.deployError = err;
        this.lastTxError = err;
        this.deployedValidatorSelection = undefined;
    }
});

Then('a implantação deve ser concluída com sucesso', function () {
    assert.strictEqual(this.deployError, null, `Deploy reverteu: ${this.deployError?.message}`);
    assert.notStrictEqual(this.deployedValidatorSelection, undefined);
});

Then('o sistema de seleção de validadores fica disponível', async function () {
    const code = await this.ethers.provider.getCode(await this.deployedValidatorSelection.getAddress());
    assert.notStrictEqual(code, '0x');
});

Then('o modo de operação do contrato deve ser inicializado como manual', async function () {
    const mode = await this.deployedValidatorSelection.operationMode();
    assert.strictEqual(Number(mode), 0);
});

Then('o conjunto de validadores elegíveis deve conter os endereços informados', async function () {
    const eligible = await this.deployedValidatorSelection.getEligibleValidators();
    assertSameAddressSet(eligible, this.deployInitialValidators);
});

Then('o conjunto de validadores operacionais deve conter os mesmos endereços informados', async function () {
    const operational = await this.deployedValidatorSelection.getValidators();
    assertSameAddressSet(operational, this.deployInitialValidators);
});

Then('o conjunto de validadores protegidos deve conter os mesmos endereços informados', async function () {
    const protectedSet = await this.deployedValidatorSelection.getProtectedValidators();
    assertSameAddressSet(protectedSet, this.deployInitialValidators);
});

Then('a transação deve ser revertida com erro de nenhum nó validador encontrado', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'FewEligibleValidators');
});

Then('o contrato não é implantado', function () {
    assert.strictEqual(this.deployedValidatorSelection, undefined);
});

Then('a transação deve ser revertida com erro de endereço duplicado', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'AlreadyEligibleNode');
});

Then('a transação deve ser revertida com erro de intervalo inválido', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'InvalidBlocksBetweenSelection');
});

Then('a transação deve ser revertida por limite de inatividade incompatível', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'InvalidBlocksWithoutProposeThreshold');
});

Then('a transação deve ser revertida', function () {
    assert.ok(getLastError(this), "Esperava reversão, mas não houve erro registrado");
});

Then('o contrato de seleção de validadores não é implantado', function () {
    assert.strictEqual(this.deployedValidatorSelection, undefined);
});

// =================================----------------------------------
// 2. CONTEXTOS E ESTADOS REUTILIZÁVEIS DA LÓGICA
// =================================----------------------------------

Given('que o contrato de seleção de validadores está implantado na rede', async function () {
    await deployStandardValidatorSelection(this);
});

Given('que o contrato de seleção de validadores está implantado', async function () {
    await deployStandardValidatorSelection(this);
});

Given('que os contratos de admin e seleção de validadores já implantados para ingresso', async function () {
    await deployStandardValidatorSelection(this);
    this.adminProxy = this.adminMock;
    this.ingressAdminAddr = this.adminProxy.target || this.adminProxy.address;
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('que o contrato de seleção de validadores atual está implantado na rede', async function () {
    await deployStandardValidatorSelection(this);
});

Given('que a chamada de consulta é executada por qualquer conta da rede', async function () {
    this.caller = this.unpermittedAccount;
});

Given('que a função será executada pela governança', function () {
    this.caller = this.governance;
});