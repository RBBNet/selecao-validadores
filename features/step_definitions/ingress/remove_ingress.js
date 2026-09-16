import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';

Given('que a chamada é executada pela governança', function () {
    this.caller = this.governance;
});

When('a função de remoção do contrato de admin é acionada no ingress', async function () {
    const callerSigner = this.caller || this.governance;
    this.ingressAdminBefore = await this.ingressContract.admins();
    try {
        const tx = await this.ingressContract.connect(callerSigner).removeAdminContract();
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('a função de remoção do contrato de seleção é acionada no ingress', async function () {
    const callerSigner = this.caller || this.governance;
    this.ingressSelectionBefore = await this.ingressContract.validatorSelectionContract();
    try {
        const tx = await this.ingressContract.connect(callerSigner).removeValidatorSelectionContract();
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o endereço registrado para o contrato de admin passa a ser zero \\(0x0)', async function () {
    const current = await this.ingressContract.admins();
    assert.strictEqual(current, this.ethers.ZeroAddress, "O endereço do contrato de admin não foi zerado.");
});

Then('o endereço registrado para o contrato de seleção passa a ser zero \\(0x0)', async function () {
    const current = await this.ingressContract.validatorSelectionContract();
    assert.strictEqual(current, this.ethers.ZeroAddress, "O endereço do contrato de seleção não foi zerado.");
});

Then('um evento registrando o endereço do contrato de admin removido deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.ingressContract.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    assert.ok(logs.some(l => l.name === 'AdminContractRemoved'), "O evento AdminContractRemoved não foi emitido.");
});

Then('um evento registrando a remoção do contrato deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.ingressContract.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    assert.ok(logs.some(l => l.name === 'ValidatorSelectionContractRemoved'), "O evento ValidatorSelectionContractRemoved não foi emitido.");
});

Then('o endereço do contrato de admin registrado permanece inalterado', async function () {
    assert.ok(this.ingressAdminBefore, "Snapshot 'antes' do endereço de admin não foi capturado.");
    const current = await this.ingressContract.admins();
    assert.strictEqual(
        current.toLowerCase(),
        this.ingressAdminBefore.toLowerCase(),
        "O endereço do contrato de admin mudou mesmo com a transação revertida."
    );
});

Then('o endereço do contrato de seleção registrado permanece inalterado', async function () {
    assert.ok(this.ingressSelectionBefore, "Snapshot 'antes' do endereço de seleção não foi capturado.");
    const current = await this.ingressContract.validatorSelectionContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.ingressSelectionBefore.toLowerCase(),
        "O endereço do contrato de seleção mudou mesmo com a transação revertida."
    );
});