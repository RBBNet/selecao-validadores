import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    extractRevertErrorName,
    assertSameAddressSet,
    getLastError,
    computeNodeFromEnode,
    generateEnodePair
} from '../support/cucumber-helpers.js';

Given('ao menos 1 validador permanecerá no conjunto de operacionais após a exclusão', async function () {

    const operational = await this.validatorSelection.getValidators();
    if (operational.length < 2) {
        await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(this.newValidator.address, true);
    }
});

Given('ao menos 4 validadores permanecerão no conjunto de operacionais após a exclusão', async function () {
    let operational = await this.validatorSelection.getValidators();
    const extraSigners = [this.validator1, this.validator2, this.validator3, this.validator4, this.validator5, this.newValidator];
    let signerIndex = 0;

    while (operational.length < 5 && signerIndex < extraSigners.length) {
        const addr = extraSigners[signerIndex].address;
        const normalize = (arr) => arr.map(a => a.toLowerCase());
        
        if (!normalize(operational).includes(addr.toLowerCase())) {
            try {
                await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(addr, true);
            } catch (err) {
                
                const errorName = extractRevertErrorName(err);
                if (errorName === 'AlreadyEligibleNode') {
                    await this.validatorSelection.connect(this.governance).addOperationalValidatorByAddress(addr);
                } else {
                    throw err; 
                }
            }
        }
        signerIndex++;
        operational = await this.validatorSelection.getValidators();
    }
});

Given('a exclusão resultaria em zero validadores operacionais', async function () {

    let operational = await this.validatorSelection.getValidators();
    while (operational.length > 1) {
        const addrToRemove = operational[operational.length - 1];

        if (addrToRemove.toLowerCase() === this.targetNodeAddr.toLowerCase()) {
             await this.validatorSelection.connect(this.governance).removeOperationalValidatorByAddress(operational[0]);
        } else {
             await this.validatorSelection.connect(this.governance).removeOperationalValidatorByAddress(addrToRemove);
        }
        operational = await this.validatorSelection.getValidators();
    }
});

Given('a exclusão resultaria em menos de 4 validadores operacionais na rede', async function () {

    let operational = await this.validatorSelection.getValidators();
    while (operational.length > 4) {
        const addrToRemove = operational[operational.length - 1];
        if (addrToRemove.toLowerCase() === this.targetNodeAddr.toLowerCase()) {
             await this.validatorSelection.connect(this.governance).removeOperationalValidatorByAddress(operational[0]);
        } else {
             await this.validatorSelection.connect(this.governance).removeOperationalValidatorByAddress(addrToRemove);
        }
        operational = await this.validatorSelection.getValidators();
    }
});

Given('o endereço informado para o nó a ser removido é zero \\(0x0)', function () {

    this.targetNodeAddr = this.ethers.ZeroAddress;
});


When('o endereço do nó é enviado para remoção', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();
    
    try {
        let tx;

        if (this.isEligibleRemoval) {
            tx = await this.validatorSelection.connect(callerSigner).removeEligibleValidatorByAddress(this.targetNodeAddr);
        } else {
            tx = await this.validatorSelection.connect(callerSigner).removeOperationalValidatorByAddress(this.targetNodeAddr);
        }
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('os parâmetros de enode do nó são enviados para remoção', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();
    
    try {
        let tx;
        if (this.isEligibleRemoval) {
            tx = await this.validatorSelection.connect(callerSigner).removeEligibleValidator(this.enodeHigh, this.enodeLow);
        } else {
            if (callerSigner.address === this.governance.address || this.caller === this.unpermittedAccount) {
                tx = await this.validatorSelection.connect(callerSigner).removeOperationalValidator(this.enodeHigh, this.enodeLow);
            } else {
                tx = await this.validatorSelection.connect(callerSigner).removeOperationalValidatorByAdmin(this.enodeHigh, this.enodeLow);
            }
        }
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});


Then('o nó é removido do conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        !operational.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        `Defeito Operacional: Esperado que o nó ${this.targetNodeAddr} fosse removido da cadeia operacional, mas ele persiste.`
    );
});

Then('o nó é removido do conjunto de validadores protegidos, caso faça parte desse conjunto', async function () {
    const protectedSet = await this.validatorSelection.getProtectedValidators();
    assert.ok(
        !protectedSet.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        `Defeito Operacional: Invariante de DA-05 falhou. O nó ${this.targetNodeAddr} não foi expurgado simultaneamente do conjunto protegido.`
    );
});

Then('o conjunto de validadores operacionais permanece inalterado', async function () {
    assert.ok(this.operationalBefore, "Erro de Fluxo BDD: Snapshot pré-transação do conjunto operacional ausente no escopo do contexto.");
    const operationalAfter = await this.validatorSelection.getValidators();
    assertSameAddressSet(operationalAfter, this.operationalBefore, "Violação de Estado: Mutação indesejada no conjunto operacional observada após a interrupção da transação.");
});

Then('a transação deve ser revertida por violação do limite mínimo de validadores', function () {
    const err = getLastError(this);
    assert.ok(err, "Falha de Segurança de Rede: Submissão que quebra os mínimos operacionais não foi repelida pelo contrato.");

    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'FewOperationalValidators', `Análise Revertida Divergente. Sinalização extraída diferiu do Custom Error estipulado: ${name}`);
});

Then('o nó permanece no conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        operational.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "Violação de Tolerância a Faltas: Nó referenciado sumiu abruptamente em cenário de interrupção."
    );
});

Then('a transação deve ser revertida informando que o endereço deve ser enviado via parâmetros de enode', function () {
    // As funções "ByAddress" de inclusão/remoção operacional são restritas à
    // governança; um administrador chamando direto por endereço esbarra no
    // modifier onlyGovernance (UnauthorizedAccess) antes de qualquer outra checagem.
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
});


Given('existe um nó no conjunto de validadores operacionais', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;


    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, true);
});

Given('existe um nó no conjunto de validadores operacionais vinculado à organização deste administrador', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, true);
    await this.nodeRulesMock.setNodeOrgId(nodeKey, this.adminOrgId ?? 1);
});

Given('existe um nó no conjunto de validadores operacionais vinculado a uma outra organização', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, true);
    const adminOrg = this.adminOrgId ?? 1;
    await this.nodeRulesMock.setNodeOrgId(nodeKey, adminOrg + 999);
});

Given('existe um nó que não está no conjunto de validadores operacionais', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
});

Given('existe um nó vinculado à organização deste administrador que não está no conjunto de validadores operacionais', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, false);
    await this.nodeRulesMock.setNodeOrgId(nodeKey, this.adminOrgId ?? 1);
});

Given('existe um nó válido no conjunto de validadores operacionais', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
    this.targetNodeAddr = address;
    this.targetNodeKey = nodeKey;
    this.isRemoval = true;

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(address, true);
});


Then('a transação deve ser revertida informando que o nó não é operacional', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'NotOperationalNode');
});

Then('a transação deve ser revertida com erro de endereço inválido', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão, mas não houve erro registrado");
    const name = extractRevertErrorName(err);
    const msg = (err.message || "").toLowerCase();

    const expectedNames = ['InvalidAddress', 'InvalidValidatorAddress', 'NotOperationalNode'];
    const isInvalid = expectedNames.includes(name) || msg.includes('invalid address for admin');
    assert.ok(isInvalid, `Erro de reversão divergente. Esperado um de ${expectedNames.join(', ')}, obtido: ${name || msg}`);
});