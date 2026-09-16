import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { getLastError, assertSameAddressSet } from '../support/cucumber-helpers.js';

Given('foi inicializado com pelo menos 1 validador operacional ativo', async function () {
    if (!(await this.validatorSelection.isOperational(this.validator1.address))) {
        await this.validatorSelection.connect(this.governance).addOperationalValidatorByAddress(this.validator1.address);
    }
});

Given('o contrato de seleção de validadores está operando no modo automático', async function () {
    const currentMode = await this.validatorSelection.operationMode();
    if (currentMode !== 1n) {
        await this.validatorSelection.connect(this.governance).setOperationMode(1);
    }
});

Given('o contrato de seleção de validadores está operando no modo manual', async function () {
    const currentMode = await this.validatorSelection.operationMode();
    if (currentMode !== 0n) {
        await this.validatorSelection.connect(this.governance).setOperationMode(0);
    }
});

Given(/^o contrato de seleção de validadores já está operando no modo "([^"]+)"$/, async function (modo) {
    const modeVal = modo === 'automático' || modo === 'Automatic' ? 1 : 0;
    const currentMode = await this.validatorSelection.operationMode();
    if (currentMode !== BigInt(modeVal)) {
        await this.validatorSelection.connect(this.governance).setOperationMode(modeVal);
    }
});

When('a função para alterar o modo de operação para manual é executada', async function () {
    const callerSigner = this.caller || this.governance;
    this.modeBefore = await this.validatorSelection.operationMode();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).setOperationMode(0);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('a função para alterar o modo de operação para automático é executada', async function () {
    const callerSigner = this.caller || this.governance;
    this.modeBefore = await this.validatorSelection.operationMode();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).setOperationMode(1);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When(/^a função para alterar o modo de operação para "([^"]+)" é executada$/, async function (modo) {
    const callerSigner = this.caller || this.governance;
    const modeVal = modo === 'automático' || modo === 'Automatic' ? 1 : 0;
    this.modeBefore = await this.validatorSelection.operationMode();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).setOperationMode(modeVal);
        await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('a função para alterar o modo de operação é executada', async function () {
    const callerSigner = this.caller || this.governance;
    this.modeBefore = await this.validatorSelection.operationMode();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).setOperationMode(1);
        await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('a função para alterar o modo de operação é executada informando um modo fora das opções permitidas', async function () {
    const callerSigner = this.caller || this.governance;
    this.modeBefore = await this.validatorSelection.operationMode();
    try {
        const tx = await callerSigner.sendTransaction({
            to: await this.validatorSelection.getAddress(),
            data: this.validatorSelection.interface.encodeFunctionData("setOperationMode", [2])
        });
        await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o modo de operação do contrato é ajustado para manual', async function () {
    const mode = await this.validatorSelection.operationMode();
    assert.strictEqual(Number(mode), 0);
});

Then('o modo de operação do contrato é ajustado para automático', async function () {
    const mode = await this.validatorSelection.operationMode();
    assert.strictEqual(Number(mode), 1);
});

Then('o modo de operação do contrato permanece inalterado', async function () {
    assert.ok(getLastError(this), "Esperava reversão, mas não houve erro registrado");
    if (this.modeBefore !== undefined) {
        const modeAfter = await this.validatorSelection.operationMode();
        assert.strictEqual(Number(modeAfter), Number(this.modeBefore), "O modo de operação mudou mesmo com a transação revertida");
    }
});

Then('a transação deve ser revertida por falta de permissão', function () {
    assert.ok(getLastError(this), "Esperava reversão por falta de permissão, mas não houve erro registrado");
});

Then('a transação deve ser revertida com erro de modo de operação inválido', function () {
    assert.ok(getLastError(this), "Esperava reversão por modo de operação inválido, mas não houve erro registrado");
});

Then('a transação deve ser revertida por redundância de estado', function () {
    assert.ok(getLastError(this), "Esperava reversão por redundância de estado, mas não houve erro registrado");
});

Then('as modificações nos conjuntos de validadores passam a ser regidas estritamente pela governança', async function () {
    const mode = await this.validatorSelection.operationMode();
    assert.strictEqual(Number(mode), 0, "Esperava modo Manual, sob o qual toda alteração dos conjuntos de validadores passa a depender exclusivamente das funções restritas à governança.");
});

Then('o conjunto de validadores protegidos deve ser populado com todos os validadores operacionais ativos', async function () {
    const operational = await this.validatorSelection.getValidators();
    const protectedSet = await this.validatorSelection.getProtectedValidators();
    assertSameAddressSet(protectedSet, operational);
});

Then(/^as informações acumuladas de produção de blocos pelos validadores são inicializadas \(zeradas\)$/, async function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar o reinício do ciclo.");
    const cycleStartBlock = await this.validatorSelection.cycleStartBlock();
    assert.strictEqual(cycleStartBlock, BigInt(this.receipt.blockNumber), "O ciclo de acompanhamento de produção de blocos não foi reiniciado no bloco da transação.");
});

Then('um novo ciclo de monitoramento automático é iniciado', async function () {
    const startBlock = await this.validatorSelection.cycleStartBlock();
    assert.notStrictEqual(startBlock, 0n);
});

Then('um evento registrando o novo modo selecionado deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(logs.some(l => l.name === 'OperationModeChanged'), "O evento OperationModeChanged não foi emitido no recibo.");
});

Then('um evento deve ser emitido registrando os novos valores configurados', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(logs.some(l => l.name === 'SelectionParametersUpdated'), "O evento SelectionParametersUpdated não foi emitido no recibo.");
});