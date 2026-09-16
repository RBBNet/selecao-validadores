import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { getStandardValidatorsList, getLastError } from '../support/cucumber-helpers.js';

Given('a rede possui ao menos 1 validador elegível e operacional ativo', async function () {
    if (!this.validatorSelection) {
        this.initialValidatorsList = getStandardValidatorsList(this);
        const ValidatorSelection = await this.ethers.getContractFactory("ValidatorSelection");
        this.validatorSelection = await ValidatorSelection.deploy(
            await this.adminMock.getAddress(),
            await this.accountRulesMock.getAddress(),
            await this.nodeRulesMock.getAddress(),
            this.initialValidatorsList,
            2, 10, 10
        );
        await this.validatorSelection.waitForDeployment();
    }
    if (!(await this.validatorSelection.isOperational(this.validator1.address))) {
        await this.validatorSelection.connect(this.governance).addOperationalValidatorByAddress(this.validator1.address);
    }
});

Given('o valor informado para o intervalo de seleções é maior ou igual a 1', function () {
    this.configBlocksBetween = 5;
});

Given(/^o valor informado para o intervalo de seleções é 0 \(inválido\)$/, function () {
    this.configBlocksBetween = 0;
});

Given('o limite de inatividade informado é maior ou igual à quantidade de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    this.configThreshold = eligible.length + 2;
});

Given('o limite de inatividade informado é menor do que a quantidade de validadores elegíveis na rede', function () {
    this.configThreshold = 1;
});

Given('um valor válido para o intervalo de seleções é informado', function () {
    this.configBlocksBetween = 5;
});

Given('que a transação será executada por uma conta que não é a governança', function () {
    this.caller = this.unpermittedAccount;
});

Given('que a função será executada por uma conta que não é a governança', function () {
    this.caller = this.unpermittedAccount;
});

When('a transação de configuração de parâmetros é executada', async function () {
    const callerSigner = this.caller || this.governance;
    const blocksBetween = this.configBlocksBetween ?? 5;
    const threshold = this.configThreshold ?? 10;

    try {
        const tx = await this.validatorSelection.connect(callerSigner).setSelectionParameters(blocksBetween, threshold);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('a transação deve ser concluída com sucesso', function () {
    assert.strictEqual(getLastError(this), null, `Esperava sucesso, mas a transação reverteu: ${getLastError(this)?.message}`);
});

Then('o intervalo de seleções passa a ser o novo valor proposto', async function () {
    const val = await this.validatorSelection.blocksBetweenSelection();
    assert.strictEqual(Number(val), this.configBlocksBetween);
});

Then('o limite de inatividade passa a ser o novo valor proposto', async function () {
    const val = await this.validatorSelection.blocksWithoutProposeThreshold();
    assert.strictEqual(Number(val), this.configThreshold);
});

Then('os parâmetros da rede devem permanecer inalterados', async function () {
    const valBlocks = await this.validatorSelection.blocksBetweenSelection();
    assert.strictEqual(Number(valBlocks), 2);
});