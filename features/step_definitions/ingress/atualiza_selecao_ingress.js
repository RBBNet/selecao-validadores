import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    getStandardValidatorsList,
    getLastError,
    extractRevertErrorName
} from '../support/cucumber-helpers.js';

Given('um novo contrato de seleção de validadores já foi implantado na rede', async function () {
    const ValidatorSelectionFactory = await this.ethers.getContractFactory("ValidatorSelection");
    const newSelection = await ValidatorSelectionFactory.deploy(
        await this.adminMock.getAddress(),
        await this.accountRulesMock.getAddress(),
        await this.nodeRulesMock.getAddress(),
        getStandardValidatorsList(this),
        2, 10, 10
    );
    await newSelection.waitForDeployment();
    this.newSelectionContract = newSelection;

    if (!this.ingressContract) {
        const IngressFactory = await this.ethers.getContractFactory("ValidatorSelectionIngress");
        this.ingressContract = await IngressFactory.connect(this.governance).deploy(
            this.adminProxy.target || this.adminProxy.address,
            this.validatorSelection.target || this.validatorSelection.address
        );
        await this.ingressContract.waitForDeployment();
    }
});

Given('o endereço do novo contrato informado é diferente do endereço do contrato atual', async function () {
    this.ingressNewSelectionAddr = await this.newSelectionContract.getAddress();
});

Given('o endereço do novo contrato informado é válido e diferente do atual', async function () {
    this.ingressNewSelectionAddr = await this.newSelectionContract.getAddress();
});

Given('o endereço do novo contrato não é zero \\(0x0)', async function () {
    this.ingressNewSelectionAddr = this.ingressNewSelectionAddr || await this.newSelectionContract.getAddress();
});

Given('o endereço do novo contrato não é zero', async function () {
    this.ingressNewSelectionAddr = this.ingressNewSelectionAddr || await this.newSelectionContract.getAddress();
});

Given('o endereço do novo contrato informado é zero \\(0x0)', function () {
    this.ingressNewSelectionAddr = this.ethers.ZeroAddress;
});

Given('o endereço do novo contrato informado é igual ao endereço do contrato atual', async function () {
    this.ingressNewSelectionAddr = await this.ingressContract.validatorSelectionContract();
});

Given('o novo contrato implementa corretamente a função de listagem de validadores ativos', async function () {
    const validators = await this.newSelectionContract.getValidators.staticCall();
    assert.ok(Array.isArray(validators), "O novo contrato de seleção não implementa getValidators() corretamente.");
});

Given('o novo contrato implementa a função de listagem de validadores ativos', async function () {
    const validators = await this.newSelectionContract.getValidators.staticCall();
    assert.ok(Array.isArray(validators), "O novo contrato de seleção não implementa getValidators() corretamente.");
});

Given('a função do novo contrato retorna uma lista contendo pelo menos 1 validador operacional', async function () {
    const validators = await this.newSelectionContract.getValidators.staticCall();
    assert.ok(validators.length >= 1, "O novo contrato de seleção não possui ao menos 1 validador operacional.");
});

Given('o novo contrato não suporta a interface de listagem de validadores ativos', function () {
    this.ingressNewSelectionAddr = this.unpermittedAccount.address;
});

Given('a função do novo contrato retorna uma lista vazia', async function () {
    const EmptyMockFactory = await this.ethers.getContractFactory("ValidatorListEmptyMock");
    const emptyMock = await EmptyMockFactory.deploy();
    await emptyMock.waitForDeployment();
    this.ingressNewSelectionAddr = await emptyMock.getAddress();
});

async function executeIngressSelectionUpdate(world) {
    const callerSigner = world.caller || world.governance;
    world.ingressSelectionBefore = await world.ingressContract.validatorSelectionContract();
    try {
        const tx = await world.ingressContract.connect(callerSigner).updateValidatorSelectionContract(world.ingressNewSelectionAddr);
        world.receipt = await tx.wait();
        world.lastTxError = null;
    } catch (err) {
        world.lastTxError = err;
    }
}

When('a função de atualização do código de seleção de validadores é executada no ingress', async function () {
    await executeIngressSelectionUpdate(this);
});

When('a função de atualização do código de seleção de validadores é executada', async function () {
    await executeIngressSelectionUpdate(this);
});

Then('o endereço do contrato de seleção de validadores corrente é atualizado para o novo endereço', async function () {
    const current = await this.ingressContract.validatorSelectionContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.ingressNewSelectionAddr.toLowerCase(),
        "O endereço do contrato de seleção não foi atualizado no ingress."
    );
});

Then('um evento registrando o contrato anterior e o contrato novo deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.ingressContract.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'ValidatorSelectionContractUpdated');
    assert.ok(hasEvent, "O evento ValidatorSelectionContractUpdated não foi emitido no recibo.");
});

Then('um evento registrando o endereço do novo contrato de seleção de validadores deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.ingressContract.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'ValidatorSelectionContractUpdated');
    assert.ok(hasEvent, "O evento ValidatorSelectionContractUpdated não foi emitido no recibo.");
});

Then('a transação deve ser revertida com erro de endereço nulo', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado.");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'InvalidAddress');
});

Then('a transação deve ser revertida informando que o contrato já está em operação', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado.");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'SameAddress');
});

Then('o contrato atual permanece inalterado', async function () {
    assert.ok(this.ingressSelectionBefore, "Snapshot 'antes' do endereço de seleção não foi capturado.");
    const current = await this.ingressContract.validatorSelectionContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.ingressSelectionBefore.toLowerCase(),
        "O endereço do contrato de seleção mudou mesmo com a transação revertida."
    );
});