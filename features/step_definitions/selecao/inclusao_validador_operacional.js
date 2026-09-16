import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    computeNodeFromEnode,
    generateEnodePair,
    getLastError,
    extractRevertErrorName,
    assertSameAddressSet
} from '../support/cucumber-helpers.js';

Given(/^que a chamada será executada por um administrador \(Global ou Local\) ativo de uma organização ativa$/, async function () {
    this.caller = this.adminLocal;
    this.adminOrgId = 1;
    await this.accountRulesMock.setHasRole(this.ethers.id('LOCAL_ADMIN_ROLE'), this.adminLocal.address, true);
    await this.accountRulesMock.setAccountActive(this.adminLocal.address, true);
    await this.accountRulesMock.setAccountOrgId(this.adminLocal.address, this.adminOrgId);
});

Given(/^que a chamada será executada por um administrador \(Global ou Local\) inativo$/, async function () {
    this.caller = this.adminLocal;
    this.adminOrgId = 1;
    await this.accountRulesMock.setHasRole(this.ethers.id('LOCAL_ADMIN_ROLE'), this.adminLocal.address, true);
    await this.accountRulesMock.setAccountActive(this.adminLocal.address, false);
    await this.accountRulesMock.setAccountOrgId(this.adminLocal.address, this.adminOrgId);
});

Given('que a chamada será executada por uma conta sem permissão', function () {
    this.caller = this.unpermittedAccount;
});

Given('existe um nó no conjunto de validadores elegíveis', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
});

Given('existe um nó no conjunto de validadores elegíveis vinculado à organização deste administrador', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
    await this.nodeRulesMock.setNodeOrgId(nodeKey, this.adminOrgId ?? 1);
});

Given('existe um nó no conjunto de validadores elegíveis vinculado a uma outra organização', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
    const adminOrg = this.adminOrgId ?? 1;
    await this.nodeRulesMock.setNodeOrgId(nodeKey, adminOrg + 999);
});

Given('existe um nó no conjunto de validadores elegíveis que não está nos operacionais', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
});

Given('esse nó não está no conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        !operational.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó já estava no conjunto de validadores operacionais antes do teste."
    );
});

Given('esse nó já está no conjunto de validadores operacionais', async function () {
    await this.validatorSelection.connect(this.governance).addOperationalValidator(this.enodeHigh, this.enodeLow);
});

Given('existe um nó que não está no conjunto de validadores elegíveis', function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
});

Given('existe um nó vinculado à organização deste administrador que não está no conjunto de validadores elegíveis', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    await this.nodeRulesMock.setNodeOrgId(nodeKey, this.adminOrgId ?? 1);
});

When('o endereço do nó é enviado para inclusão', async function () {
    const callerSigner = this.caller || this.governance;
    this.protectedBefore = await this.validatorSelection.getProtectedValidators();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).addOperationalValidatorByAddress(this.targetNodeAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('os parâmetros de enode do nó são enviados para inclusão', async function () {
    const callerSigner = this.caller || this.governance;
    this.protectedBefore = await this.validatorSelection.getProtectedValidators();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).addOperationalValidator(this.enodeHigh, this.enodeLow);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('o administrador tenta enviar o endereço direto da função em vez dos parâmetros de enode', async function () {
    const callerSigner = this.caller || this.governance;
    try {
        let tx;
     
        if (this.isRemoval) {
            tx = await this.validatorSelection.connect(callerSigner).removeOperationalValidatorByAddress(this.targetNodeAddr);
        } else {
            tx = await this.validatorSelection.connect(callerSigner).addOperationalValidatorByAddress(this.targetNodeAddr);
        }
        await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o nó passa a integrar o conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        operational.map((a) => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó esperado não está no conjunto de validadores operacionais"
    );
});

Then('o nó é injetado ao conjunto de validadores protegidos', async function () {
    const protectedSet = await this.validatorSelection.getProtectedValidators();
    assert.ok(
        protectedSet.map((a) => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó esperado não está no conjunto de validadores protegidos"
    );
});

Then('o nó permanece no conjunto de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    assert.ok(
        eligible.map((a) => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó esperado não está mais no conjunto de validadores elegíveis"
    );
});

Then('o nó não passa a constar no conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        !operational.map((a) => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó não deveria estar no conjunto de validadores operacionais"
    );
});

Then('um evento registrando o endereço do nó deve ser emitido', async function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    const nodeAddressEvents = ['OperationalValidatorAdded', 'EligibleValidatorAdded', 'EligibleValidatorRemoved', 'OperationalValidatorManuallyRemoved'];
    const hasEvent = logs.some(l => nodeAddressEvents.includes(l.name) && l.args[0].toLowerCase() === this.targetNodeAddr.toLowerCase());
    assert.ok(hasEvent, `Nenhum evento (${nodeAddressEvents.join(', ')}) registrando o endereço ${this.targetNodeAddr} foi emitido no recibo.`);
});

Then('a transação deve ser revertida por incompatibilidade de chamada para o perfil', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'UnauthorizedAccess');
});

Then('a transação deve ser revertida informando que o administrador está inativo', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");

    const name = extractRevertErrorName(err);
    assert.ok(
        name === 'InactiveAccount' || name === 'UnauthorizedAccess',
        `Esperava InactiveAccount ou UnauthorizedAccess, recebido: ${name}`
    );
});

Then('a transação deve ser revertida por violação de vínculo organizacional', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'NotLocalNode');
});

Then('a transação deve ser revertida informando que o nó já é operacional', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'AlreadyOperationalNode');
});

Then('o conjunto de validadores protegidos permanece inalterado', async function () {
    assert.ok(this.protectedBefore, "Snapshot 'antes' do conjunto protegido não foi capturado");
    const protectedAfter = await this.validatorSelection.getProtectedValidators();
    assertSameAddressSet(protectedAfter, this.protectedBefore, "O conjunto de validadores protegidos mudou mesmo com a transação revertida");
});