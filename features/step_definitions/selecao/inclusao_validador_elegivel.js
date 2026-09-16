import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import {
    extractRevertErrorName,
    computeNodeFromEnode,
    generateEnodePair
} from '../support/cucumber-helpers.js';

Given('o endereço do nó a ser adicionado foi informado', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
});

Given('os parâmetros do nó a ser adicionado foram informados via enode', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
});

Given('os parâmetros de enode do nó a ser adicionado foram informados', async function () {
    const { enodeHigh, enodeLow } = generateEnodePair(this);
    const { address, nodeKey } = computeNodeFromEnode(enodeHigh, enodeLow, this.ethers);
    this.targetNodeAddr = address;
    this.enodeHigh = enodeHigh;
    this.enodeLow = enodeLow;
});

Given('é definido que o nó não deve ser automaticamente adicionado como validador operacional', function () {
    this.autoAddOperational = false;
});

Given('é definido que o nó deve ser automaticamente adicionado como validador operacional', function () {
    this.autoAddOperational = true;
});

Given('o nó informado não está no conjunto de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    assert.ok(
        !eligible.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó já estava no conjunto de validadores elegíveis antes do teste."
    );
});

Given('o nó definido já está no conjunto de validadores elegíveis', async function () {

    await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(this.targetNodeAddr, false);
});

Given('o endereço informado para o nó a ser adicionado é zero \\(0x0)', function () {
    this.targetNodeAddr = this.ethers.ZeroAddress;
});

Given('que a chamada será executada por uma conta que não é a governança', function () {
    this.caller = this.unpermittedAccount;
});


Given('o limite de inatividade atual é menor que a nova quantidade de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    const currentLimit = eligible.length;
    
    const currentInterval = await this.validatorSelection.blocksBetweenSelection();
    await this.validatorSelection.connect(this.governance).setSelectionParameters(currentInterval, currentLimit);
    
    this.idleLimitBefore = await this.validatorSelection.blocksWithoutProposeThreshold();
});

When('o endereço do nó é enviado para adição', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).addEligibleValidatorByAddress(
            this.targetNodeAddr, 
            !!this.autoAddOperational
        );
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

When('os parâmetros de enode do nó são enviados para adição', async function () {
    const callerSigner = this.caller || this.governance;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
    this.operationalBefore = await this.validatorSelection.getValidators();
    try {
        let tx;
        if (callerSigner.address === this.governance.address || callerSigner === this.unpermittedAccount) {
            tx = await this.validatorSelection.connect(callerSigner).addEligibleValidator(
                this.enodeHigh, 
                this.enodeLow, 
                !!this.autoAddOperational
            );
        } else {
            tx = await this.validatorSelection.connect(callerSigner).addEligibleValidatorByAdmin(
                this.enodeHigh, 
                this.enodeLow, 
                !!this.autoAddOperational
            );
        }
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o nó é adicionado ao conjunto de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    assert.ok(
        eligible.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "O nó não foi adicionado à lista de elegíveis."
    );
});

Then('o nó é adicionado ao conjunto de validadores operacionais', async function () {
    const operational = await this.validatorSelection.getValidators();
    assert.ok(
        operational.map(a => a.toLowerCase()).includes(this.targetNodeAddr.toLowerCase()),
        "A flag de auto-inclusão operacional não surtiu efeito."
    );
});

Given('o limite de inatividade já é maior ou igual à nova quantidade de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    const newLimit = eligible.length + 5; 
    
    const currentInterval = await this.validatorSelection.blocksBetweenSelection();
    
    await this.validatorSelection.connect(this.governance).setSelectionParameters(currentInterval, newLimit);
    
    this.idleLimitBefore = await this.validatorSelection.blocksWithoutProposeThreshold();
});


Then('o parâmetro limite de inatividade permanece inalterado', async function () {
    const idleLimitAfter = await this.validatorSelection.blocksWithoutProposeThreshold();
    assert.strictEqual(
        idleLimitAfter.toString(), 
        this.idleLimitBefore.toString(), 
        "O limite de inatividade sofreu mutação indevida."
    );
});

Then('o parâmetro limite de inatividade é atualizado para ser igual à nova quantidade de validadores elegíveis', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    const idleLimitAfter = await this.validatorSelection.blocksWithoutProposeThreshold();
    assert.strictEqual(
        idleLimitAfter.toString(), 
        eligible.length.toString(), 
        "O limite de inatividade não foi reajustado para proteger a proporção de nós da rede."
    );
});
Then('um evento registrando o intervalo de seleção e o novo limite de inatividade deve ser emitido', async function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    
    const logsDecodificados = this.receipt.logs.map(log => {
        try {
            return this.validatorSelection.interface.parseLog(log);
        } catch (e) {
            return null;
        }
    }).filter(l => l !== null);
    
    const hasConfigEvent = logsDecodificados.some(l => l.name === 'SelectionParametersUpdated');
    
    assert.ok(hasConfigEvent, "O evento de reajuste do limite de inatividade (SelectionParametersUpdated) não foi emitido no recibo.");
});

Then('o nó não é adicionado novamente', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    const count = eligible.filter(a => a.toLowerCase() === this.targetNodeAddr.toLowerCase()).length;
    assert.strictEqual(count, 1, "O nó foi duplicado na lista, falhando a restrição de exclusividade.");
});

Then('o conjunto de validadores elegíveis permanece inalterado', async function () {
    const eligibleAfter = await this.validatorSelection.getEligibleValidators();
    const normalize = (arr) => arr.map(a => a.toLowerCase());
    assert.deepStrictEqual(
        normalize(eligibleAfter), 
        normalize(this.eligibleBefore || []), 
        "A operação de falha corrompeu o conjunto de validadores elegíveis prévio."
    );
});

Then('o conjunto de validadores permanece inalterado', async function () {
    const operationalAfter = await this.validatorSelection.getValidators();
    const normalize = (arr) => arr.map(a => a.toLowerCase());
    assert.deepStrictEqual(
        normalize(operationalAfter), 
        normalize(this.operationalBefore || []), 
        "A operação falha corrompeu o estado operacional da rede."
    );
});