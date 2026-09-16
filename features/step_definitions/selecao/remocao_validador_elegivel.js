import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    computeNodeFromEnode,
    generateEnodePair,
    getLastError,
    extractRevertErrorName
} from '../support/cucumber-helpers.js';

Given('o endereço do nó a ser removido foi informado', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;

    this.isEligibleRemoval = true;
});

Given('os parâmetros do nó a ser removido foram informados via enode', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;

    this.isEligibleRemoval = true;
});

Given('os parâmetros de enode do nó a ser removido foram informados', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;

    this.isEligibleRemoval = true;
});

Given('o nó informado está no conjunto de validadores elegíveis', async function () {
    this.isEligibleRemoval = true;
    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(this.targetNodeAddr, false);
});

Given('o nó informado não está no conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        !operational.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó já estava no conjunto de validadores operacionais antes do teste."
    );
});

Given('o nó informado também está no conjunto de validadores operacionais', async function () {
    await this.validatorSelection.connect(this.governance).addOperationalValidatorByAddress(this.targetNodeAddr);
});

Given('o nó informado está nos conjuntos de validadores elegíveis e operacionais', async function () {
    this.isEligibleRemoval = true;
    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(this.targetNodeAddr, true);
});

Given('ao menos {int} validador permanecerá no conjunto de validadores operacionais após a exclusão', async function (minimo) {
    let operational = await this.validatorSelection.getValidators();
    const extraSigners = [this.validator1, this.validator2, this.validator3, this.validator4, this.validator5, this.newValidator];
    let signerIndex = 0;

    while (operational.length <= minimo && signerIndex < extraSigners.length) {
        const addr = extraSigners[signerIndex].address;
        const normalize = (arr) => arr.map(a => a.toLowerCase());
        
        if (!normalize(operational).includes(addr.toLowerCase())) {
            try {
                await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(addr, true);
            } catch (e) {
                if (extractRevertErrorName(e) === 'AlreadyEligibleNode') {
                    await this.validatorSelection.connect(this.governance).addOperationalValidatorByAddress(addr);
                }
            }
        }
        signerIndex++;
        operational = await this.validatorSelection.getValidators();
    }
});

When('o endereço do nó é enviado para remoção do conjunto de elegíveis', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();

    try {
        const tx = await this.validatorSelection.connect(callerSigner).removeEligibleValidatorByAddress(this.targetNodeAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('os parâmetros do nó são enviados via enode para remoção do conjunto de elegíveis', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();

    try {
        const tx = await this.validatorSelection.connect(callerSigner).removeEligibleValidator(this.enodeHigh, this.enodeLow);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o nó não é removido de nenhum dos conjuntos', async function () {
    const eligibleAfter = await this.validatorSelection.getEligibleValidators();
    const operationalAfter = await this.validatorSelection.getValidators();
    const normalize = (arr) => arr.map(a => a.toLowerCase());

    assert.deepStrictEqual(normalize(eligibleAfter), normalize(this.eligibleBefore || []), "Conjunto elegível sofreu mutação indevida.");
    assert.deepStrictEqual(normalize(operationalAfter), normalize(this.operationalBefore || []), "Conjunto operacional sofreu mutação indevida.");
});

Then('um evento registrando a revogação da elegibilidade do nó deve ser emitido', async function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    
    const hasEvent = logs.some(l => l.name === 'EligibleValidatorRemoved');
    assert.ok(hasEvent, "O evento EligibleValidatorRemoved não foi emitido no recibo.");
});

Then('um evento adicional registrando a remoção operacional manual do nó deve ser emitido', async function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    
    const hasEvent = logs.some(l => l.name === 'OperationalValidatorManuallyRemoved');
    assert.ok(hasEvent, "O evento OperationalValidatorManuallyRemoved não foi emitido no recibo.");
});

Then('a transação deve ser revertida informando que o nó não é elegível', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado.");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'NotEligibleNode', `Erro de reversão divergente. Esperado NotEligibleNode, obtido: ${name}`);
});

Then('o nó é removido do conjunto de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    assert.ok(
        !eligible.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "Defeito: O nó ainda consta no conjunto de validadores elegíveis após a remoção."
    );
});