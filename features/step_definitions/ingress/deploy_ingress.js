import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { getLastError, extractRevertErrorName, deployStandardValidatorSelection } from '../support/cucumber-helpers.js';

async function deployIngress(context) {
    const callerSigner = context.caller || context.governance;
    try {
        const IngressFactory = await context.ethers.getContractFactory("ValidatorSelectionIngress", callerSigner);
        context.ingressContract = await IngressFactory.deploy(context.ingressAdminAddr, context.ingressSelectionAddr);
        await context.ingressContract.waitForDeployment();
        context.lastTxError = null;
    } catch (err) {
        context.lastTxError = err;
    }
}

Given('que os contratos de admin e seleção de validadores já estão implantados na rede', async function () {
    await deployStandardValidatorSelection(this);
    this.adminProxy = this.adminMock;
    this.ingressAdminAddr = this.adminProxy.target || this.adminProxy.address;
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('que os contratos de admin \\(AdminProxy) e de seleção de validadores já estão implantados na rede', function () {
    this.ingressAdminAddr = this.adminProxy.address;
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('que a chamada é executada por uma conta com permissão de deploy', function () {
    this.caller = this.governance;
});

Given('o endereço do contrato de admin informado é válido e implementa a verificação de compatibilidade', function () {
    this.ingressAdminAddr = this.adminProxy.target || this.adminProxy.address;
});

Given('o endereço do contrato de seleção de validadores informado é válido e implementa a listagem de validadores', function () {
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('a função de listagem no contrato de seleção retorna uma lista contendo pelo menos {int} validador', async function (quantidade) {
    const validators = await this.validatorSelection.getValidators.staticCall();
    assert.ok(validators.length >= quantidade, `O contrato de seleção não possui ao menos ${quantidade} validador(es) operacional(is).`);
});

Given('o endereço informado para o contrato de admin é zero \\(0x0)', function () {
    this.ingressAdminAddr = this.ethers.ZeroAddress;
});

Given('o endereço informado para o contrato de seleção de validadores é zero \\(0x0)', function () {
    this.ingressSelectionAddr = this.ethers.ZeroAddress;
});

Given('os endereços informados são diferentes de zero \\(0x0)', function () {
    this.ingressAdminAddr = this.adminProxy.target || this.adminProxy.address;
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('o contrato de admin reverte ao receber a chamada de verificação de compatibilidade', function () {
    this.ingressAdminAddr = this.unpermittedAccount.address;
});

Given('o contrato de seleção não implementa a assinatura da função de listagem de validadores', function () {
    this.ingressSelectionAddr = this.unpermittedAccount.address;
});

Given('o contrato de seleção implementa a função de listagem de validadores', function () {
    this.ingressSelectionAddr = this.validatorSelection.target || this.validatorSelection.address;
});

Given('a chamada de teste da função de listagem retorna uma lista vazia', function () {
    this.ingressSelectionAddr = this.adminProxy.target || this.adminProxy.address;
});

When('a função de implantação do ingress é acionada passando os endereços obrigatórios', async function () {
    await deployIngress(this);
});

When('a função de implantação do ingress é acionada', async function () {
    await deployIngress(this);
});

Then('os endereços informados são registrados internamente no contrato de ingress', async function () {
    const selectionAddr = await this.ingressContract.validatorSelectionContract();
    const adminAddr = await this.ingressContract.admins();
    
    assert.strictEqual(selectionAddr.toLowerCase(), this.ingressSelectionAddr.toLowerCase(), "Endereço do contrato de seleção difere.");
    assert.strictEqual(adminAddr.toLowerCase(), this.ingressAdminAddr.toLowerCase(), "Endereço do contrato de administrador difere.");
});

Then('o contrato de ingress não é implantado', function () {
    assert.ok(this.lastTxError, "A transação não reverteu como o esperado.");
});

Then('a transação deve ser revertida por incompatibilidade de interface', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão de interface.");
    const name = extractRevertErrorName(err);
    const expected = ['InvalidAdminContract', 'InvalidValidatorSelectionContract', 'InvalidAccountsContract', 'InvalidNodesContract'];
    // EOA sem código: o Hardhat não decodifica o custom error nesse caso ("unexpected amount of data"), daí o fallback restrito a essa mensagem.
    const isEoaDecodeFailure = name === null && (err.message || "").toLowerCase().includes('unexpected amount of data');
    assert.ok(expected.includes(name) || isEoaDecodeFailure, `Erro de interface divergente. Esperado um de ${expected.join(', ')}, obtido: ${name}`);
});

Then('a transação deve ser revertida para evitar o travamento do consenso da rede', function () {
    const err = getLastError(this);
    assert.ok(err, "Esperava reversão por segurança de lista vazia.");
    const name = extractRevertErrorName(err);
    assert.strictEqual(name, 'InvalidValidatorSelectionContract', `Erro de rede divergente: ${name}`);
});