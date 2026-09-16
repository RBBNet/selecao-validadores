import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { assertSameAddressSet } from '../support/cucumber-helpers.js';

When('a função de consulta do endereço de admin é acionada no ingress', async function () {
    this.queryResult = await this.ingressContract.admins();
});

Then('o endereço atual do contrato de admin é retornado', async function () {
    const expected = this.adminProxy.target || this.adminProxy.address;
    assert.strictEqual(this.queryResult.toLowerCase(), expected.toLowerCase(), "O endereço de admin consultado difere do esperado.");
});

When('a função de consulta do endereço de seleção é acionada no ingress', async function () {
    this.queryResult = await this.ingressContract.validatorSelectionContract();
});

Then('o endereço atual do contrato de seleção de validadores é retornado', async function () {
    const expected = this.validatorSelection.target || this.validatorSelection.address;
    assert.strictEqual(this.queryResult.toLowerCase(), expected.toLowerCase(), "O endereço de seleção consultado difere do esperado.");
});

Given('que a chamada de leitura é executada por qualquer conta ou cliente Besu', function () {
    this.caller = this.unpermittedAccount;
});

Given('existe um contrato de seleção de validadores registrado e funcional no ingress', async function () {
    const registered = await this.ingressContract.validatorSelectionContract();
    const expected = this.validatorSelection.target || this.validatorSelection.address;
    assert.strictEqual(registered.toLowerCase(), expected.toLowerCase(), "O ingress não está registrado para o contrato de seleção esperado.");
    const validators = await this.validatorSelection.getValidators.staticCall();
    assert.ok(Array.isArray(validators), "O contrato de seleção registrado no ingress não está funcional.");
});

Given('a chamada ao contrato de seleção retorna uma lista contendo pelo menos 1 validador operacional', async function () {
    const validators = await this.validatorSelection.getValidators.staticCall();
    assert.ok(validators.length >= 1, "O contrato de seleção não possui ao menos 1 validador operacional.");
});

Given('o endereço registrado no ingress para o contrato de seleção de validadores é zero \\(0x0)', async function () {
    const tx = await this.ingressContract.connect(this.governance).removeValidatorSelectionContract();
    await tx.wait();
});

async function pointIngressToStateMock(world, mode) {
    const StateMockFactory = await world.ethers.getContractFactory("ValidatorListStateMock");
    const stateMock = await StateMockFactory.deploy();
    await stateMock.waitForDeployment();

    const updateTx = await world.ingressContract.connect(world.governance).updateValidatorSelectionContract(await stateMock.getAddress());
    await updateTx.wait();

    if (mode === 'revert') {
        await stateMock.setBroken(true);
    } else {
        await stateMock.setEmpty(true);
    }
}

Given('a execução da consulta reverte no contrato de seleção de validadores', async function () {
    await pointIngressToStateMock(this, 'revert');
});

Given('a chamada ao contrato de seleção de validadores retorna uma lista vazia', async function () {
    await pointIngressToStateMock(this, 'empty');
});

When('a função de consulta de validadores operacionais é acionada no ingress', async function () {
    this.queryResult = await this.ingressContract.connect(this.caller || this.validator1).getValidators();
});

Then('a lista de validadores operacionais da rede é retornada', async function () {
    const expected = await this.validatorSelection.getValidators();
    assertSameAddressSet(this.queryResult, expected);
});

Then('a chamada de leitura deve ser concluída com sucesso sem propagar erro', function () {
    assert.ok(Array.isArray(this.queryResult), "A consulta não retornou uma lista de validadores.");
});

Then('a chamada de leitura deve ser concluída com sucesso sem propagar erro ou reversão', function () {
    assert.ok(Array.isArray(this.queryResult), "A consulta não retornou uma lista de validadores.");
});

Then('o ingress deve acionar o mecanismo de fallback', function () {
    assert.strictEqual(this.queryResult.length, 1, "O mecanismo de fallback deveria retornar exatamente 1 endereço.");
});

Then('o ingress deve retornar uma lista contendo unicamente o endereço do validador do bloco atual', async function () {
    assert.strictEqual(this.queryResult.length, 1, "O fallback deveria retornar exatamente 1 endereço.");
    const block = await this.ethers.provider.getBlock("latest");
    assert.strictEqual(
        this.queryResult[0].toLowerCase(),
        block.miner.toLowerCase(),
        "O fallback não retornou o validador do bloco atual (block.coinbase)."
    );
});