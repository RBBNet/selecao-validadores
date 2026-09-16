import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { getLastError, extractRevertErrorName, deployStandardValidatorSelection } from '../support/cucumber-helpers.js';

Given('que o contrato de ingress está implantado na rede', async function () {
    if (!this.validatorSelection) {
        await deployStandardValidatorSelection(this);
    }
    if (!this.ingressContract) {
        const IngressFactory = await this.ethers.getContractFactory("ValidatorSelectionIngress");
        this.ingressContract = await IngressFactory.connect(this.governance).deploy(
            this.adminProxy.target || this.adminProxy.address,
            this.validatorSelection.target || this.validatorSelection.address
        );
        await this.ingressContract.waitForDeployment();
    }
});

Given('um contrato de admin está ativo no ingress', function () {
    this.ingressAdminBefore = this.ingressAdminBefore || this.adminProxy.target || this.adminProxy.address;
});

Given('um contrato de admin está ativo e registrado no ingress', function () {
    this.ingressAdminBefore = this.ingressAdminBefore || this.adminProxy.target || this.adminProxy.address;
});

Given('existe um contrato de seleção de validadores registrado no ingress', async function () {
    this.ingressSelectionBefore = await this.ingressContract.validatorSelectionContract();
});

Given('o endereço do novo contrato de admin informado é diferente do atual', async function () {
    const AdminMockFactory = await this.ethers.getContractFactory("AdminMock");
    const newAdmin = await AdminMockFactory.deploy();
    await newAdmin.waitForDeployment();
    this.newAdminContract = newAdmin;
    this.newAdminAddr = await newAdmin.getAddress();
});

Given('o endereço do novo contrato de admin informado é válido e diferente do atual', async function () {
    if (!this.newAdminContract) {
        const AdminMockFactory = await this.ethers.getContractFactory("AdminMock");
        const newAdmin = await AdminMockFactory.deploy();
        await newAdmin.waitForDeployment();
        this.newAdminContract = newAdmin;
    }
    this.newAdminAddr = await this.newAdminContract.getAddress();
});

Given('o endereço do novo contrato de admin não é zero \\(0x0)', async function () {
    if (!this.newAdminAddr) {
        if (!this.newAdminContract) {
            const AdminMockFactory = await this.ethers.getContractFactory("AdminMock");
            const newAdmin = await AdminMockFactory.deploy();
            await newAdmin.waitForDeployment();
            this.newAdminContract = newAdmin;
        }
        this.newAdminAddr = await this.newAdminContract.getAddress();
    }
});

Given('o endereço do novo contrato de admin informado não é zero \\(0x0)', async function () {
    if (!this.newAdminAddr) {
        if (!this.newAdminContract) {
            const AdminMockFactory = await this.ethers.getContractFactory("AdminMock");
            const newAdmin = await AdminMockFactory.deploy();
            await newAdmin.waitForDeployment();
            this.newAdminContract = newAdmin;
        }
        this.newAdminAddr = await this.newAdminContract.getAddress();
    }
});

Given('é verificado com sucesso que o novo contrato de admin é compatível com os contratos atuais', async function () {
    const isAuthorized = await this.newAdminContract.isAuthorized.staticCall(this.ethers.ZeroAddress);
    assert.strictEqual(isAuthorized, false, "O AdminMock do ambiente de teste não é compatível.");
});

Given('o endereço do novo contrato de admin informado é zero \\(0x0)', function () {
    this.newAdminAddr = this.ethers.ZeroAddress;
});

Given('o endereço do novo contrato de admin informado é igual ao endereço ativo atualmente', async function () {
    this.newAdminAddr = await this.validatorSelection.admins();
});

Given('o novo contrato de admin reverte ao verificar a compatibilidade', function () {
    this.newAdminAddr = this.unpermittedAccount.address;
});

Given('que a chamada não será executada pela governança', function () {
    this.caller = this.unpermittedAccount;
});

Given('que a função não será executada pela governança', function () {
    this.caller = this.unpermittedAccount;
});

When('a função de atualização do contrato de admin é acionada no ingress', async function () {
    const callerSigner = this.caller || this.governance;
    this.ingressAdminBefore = await this.ingressContract.admins();
    try {
        const tx = await this.ingressContract.connect(callerSigner).updateAdminContract(this.newAdminAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o endereço do contrato de admin no ingress é atualizado para o novo endereço', async function () {
    const current = await this.ingressContract.admins();
    assert.strictEqual(
        current.toLowerCase(),
        this.newAdminAddr.toLowerCase(),
        "O endereço do contrato de admin não foi atualizado no ingress."
    );
});

Then('um evento registrando os endereços do contrato anterior e do contrato novo deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.ingressContract.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'AdminContractUpdated');
    assert.ok(hasEvent, "O evento AdminContractUpdated não foi emitido no recibo.");
});

Then('a transação deve ser revertida informando que o endereço é idêntico ao atual', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado.");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'SameAddress');
});

Then('o contrato de admin permanece inalterado', async function () {
    assert.ok(this.ingressAdminBefore, "Snapshot 'antes' do endereço de admin não foi capturado.");
    const current = await this.ingressContract.admins();
    assert.strictEqual(
        current.toLowerCase(),
        this.ingressAdminBefore.toLowerCase(),
        "O endereço do contrato de admin mudou mesmo com a transação revertida."
    );
});