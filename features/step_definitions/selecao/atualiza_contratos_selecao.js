import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';

Given('o novo contrato de admin responde com sucesso à verificação de compatibilidade', async function () {
    const isAuthorized = await this.newAdminContract.isAuthorized.staticCall(this.ethers.ZeroAddress);
    assert.strictEqual(isAuthorized, false, "O AdminMock do ambiente de teste não é compatível.");
});

Given('o novo contrato de admin reverte ao receber a verificação de compatibilidade', function () {
    this.newAdminAddr = this.unpermittedAccount.address;
});

When('a função de atualização do contrato de admin é acionada no contrato da seleção de validadores', async function () {
    const callerSigner = this.caller || this.governance;
    this.validatorsAdminBefore = await this.validatorSelection.admins();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).updateAdminContract(this.newAdminAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('o endereço do contrato de admin é atualizado para o novo endereço', async function () {
    const current = await this.validatorSelection.admins();
    assert.strictEqual(
        current.toLowerCase(),
        this.newAdminAddr.toLowerCase(),
        "O endereço do contrato de admin não foi atualizado no contrato de seleção de validadores."
    );
});

Then('um evento registrando os endereços do contrato de admin anterior e novo deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'AdminContractUpdated');
    assert.ok(hasEvent, "O evento AdminContractUpdated não foi emitido no recibo.");
});

Then('o endereço do contrato de admin no contrato da seleção de validadores permanece inalterado', async function () {
    assert.ok(this.validatorsAdminBefore, "Snapshot 'antes' do endereço de admin não foi capturado.");
    const current = await this.validatorSelection.admins();
    assert.strictEqual(
        current.toLowerCase(),
        this.validatorsAdminBefore.toLowerCase(),
        "O endereço do contrato de admin mudou mesmo com a transação revertida."
    );
});

Given('o endereço do novo contrato de regras de contas informado é diferente do atual', async function () {
    const AccountsFactory = await this.ethers.getContractFactory("AccountRulesV2ConfigurableMock");
    const newAccounts = await AccountsFactory.deploy();
    await newAccounts.waitForDeployment();
    this.newAccountsContract = newAccounts;
    this.newAccountsAddr = await newAccounts.getAddress();
});

Given('o endereço do novo contrato de regras de contas informado é válido e diferente do atual', async function () {
    if (!this.newAccountsContract) {
        const AccountsFactory = await this.ethers.getContractFactory("AccountRulesV2ConfigurableMock");
        const newAccounts = await AccountsFactory.deploy();
        await newAccounts.waitForDeployment();
        this.newAccountsContract = newAccounts;
    }
    this.newAccountsAddr = await this.newAccountsContract.getAddress();
});

Given('o endereço do novo contrato de regras de contas informado não é zero \\(0x0)', async function () {
    if (!this.newAccountsAddr) {
        if (!this.newAccountsContract) {
            const AccountsFactory = await this.ethers.getContractFactory("AccountRulesV2ConfigurableMock");
            const newAccounts = await AccountsFactory.deploy();
            await newAccounts.waitForDeployment();
            this.newAccountsContract = newAccounts;
        }
        this.newAccountsAddr = await this.newAccountsContract.getAddress();
    }
});

Given('o novo contrato de regras de contas responde com sucesso à verificação de compatibilidade na conta ativa', async function () {
    const isActive = await this.newAccountsContract.isAccountActive.staticCall(this.ethers.ZeroAddress);
    assert.strictEqual(isActive, false, "O AccountRulesV2ConfigurableMock do ambiente de teste não é compatível.");
});

Given('o endereço do novo contrato de regras de contas informado é zero \\(0x0)', function () {
    this.newAccountsAddr = this.ethers.ZeroAddress;
});

Given('o endereço do novo contrato de regras de contas informado é igual ao endereço ativo atualmente', async function () {
    this.newAccountsAddr = await this.validatorSelection.accountsContract();
});

Given('o novo contrato de regras de contas reverte ao receber a verificação de compatibilidade na conta ativa', function () {
    this.newAccountsAddr = this.unpermittedAccount.address;
});


When('a função de atualização do contrato de regras de contas é acionada no contrato de seleção de validadores', async function () {
    const callerSigner = this.caller || this.governance;
    this.validatorsAccountsBefore = await this.validatorSelection.accountsContract();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).updateAccountsContract(this.newAccountsAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('a variável de armazenamento do contrato de regras de contas no contrato de seleção de validadores é atualizada para o novo endereço', async function () {
    const current = await this.validatorSelection.accountsContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.newAccountsAddr.toLowerCase(),
        "O contrato de regras de contas não foi atualizado no contrato de seleção de validadores."
    );
});

Then('um evento registrando os endereços do contrato de regras de contas anterior e novo deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'AccountsContractUpdated');
    assert.ok(hasEvent, "O evento AccountsContractUpdated não foi emitido no recibo.");
});

Then('o endereço do contrato de regras de contas no contrato de seleção de validadores permanece inalterado', async function () {
    assert.ok(this.validatorsAccountsBefore, "Snapshot 'antes' do contrato de regras de contas não foi capturado.");
    const current = await this.validatorSelection.accountsContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.validatorsAccountsBefore.toLowerCase(),
        "O contrato de regras de contas mudou mesmo com a transação revertida."
    );
});


Given('o endereço do novo contrato de regras de nós informado é diferente do atual', async function () {
    const NodesFactory = await this.ethers.getContractFactory("NodeRulesV2ConfigurableMock");
    const newNodes = await NodesFactory.deploy();
    await newNodes.waitForDeployment();
    this.newNodesContract = newNodes;
    this.newNodesAddr = await newNodes.getAddress();
});

Given('o endereço do novo contrato de regras de nós informado é válido e diferente do atual', async function () {
    if (!this.newNodesContract) {
        const NodesFactory = await this.ethers.getContractFactory("NodeRulesV2ConfigurableMock");
        const newNodes = await NodesFactory.deploy();
        await newNodes.waitForDeployment();
        this.newNodesContract = newNodes;
    }
    this.newNodesAddr = await this.newNodesContract.getAddress();
});

Given('o endereço do novo contrato de regras de nós informado não é zero \\(0x0)', async function () {
    if (!this.newNodesAddr) {
        if (!this.newNodesContract) {
            const NodesFactory = await this.ethers.getContractFactory("NodeRulesV2ConfigurableMock");
            const newNodes = await NodesFactory.deploy();
            await newNodes.waitForDeployment();
            this.newNodesContract = newNodes;
        }
        this.newNodesAddr = await this.newNodesContract.getAddress();
    }
});

Given('o novo contrato de regras de nós responde com sucesso à verificação de compatibilidade', async function () {
    const { orgId, active } = await this.newNodesContract.allowedNodes.staticCall(0);
    assert.strictEqual(orgId, 0n, "O NodeRulesV2ConfigurableMock do ambiente de teste não é compatível (orgId).");
    assert.strictEqual(active, false, "O NodeRulesV2ConfigurableMock do ambiente de teste não é compatível (active).");
});

Given('o endereço do novo contrato de regras de nós informado é zero \\(0x0)', function () {
    this.newNodesAddr = this.ethers.ZeroAddress;
});

Given('o endereço do novo contrato de regras de nós informado é igual ao endereço ativo atualmente', async function () {
    this.newNodesAddr = await this.validatorSelection.nodesContract();
});

Given('o novo contrato de regras de nós reverte ao receber a verificação de compatibilidade', function () {
    this.newNodesAddr = this.unpermittedAccount.address;
});

When('a função de atualização do contrato de regras de nós é acionada no contrato de seleção de validadores', async function () {
    const callerSigner = this.caller || this.governance;
    this.validatorsNodesBefore = await this.validatorSelection.nodesContract();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).updateNodesContract(this.newNodesAddr);
        this.receipt = await tx.wait();
        this.lastTxError = null;
    } catch (err) {
        this.lastTxError = err;
    }
});

Then('a variável de armazenamento do contrato de regras de nós no contrato de seleção de validadores é atualizada para o novo endereço', async function () {
    const current = await this.validatorSelection.nodesContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.newNodesAddr.toLowerCase(),
        "O contrato de regras de nós não foi atualizado no contrato de seleção de validadores."
    );
});

Then('um evento registrando os endereços do contrato de regras de nós anterior e novo deve ser emitido', function () {
    assert.ok(this.receipt, "Não há recibo de transação para verificar eventos.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);

    const hasEvent = logs.some(l => l.name === 'NodesContractUpdated');
    assert.ok(hasEvent, "O evento NodesContractUpdated não foi emitido no recibo.");
});

Then('o endereço do contrato de regras de nós no contrato de seleção de validadores permanece inalterado', async function () {
    assert.ok(this.validatorsNodesBefore, "Snapshot 'antes' do contrato de regras de nós não foi capturado.");
    const current = await this.validatorSelection.nodesContract();
    assert.strictEqual(
        current.toLowerCase(),
        this.validatorsNodesBefore.toLowerCase(),
        "O contrato de regras de nós mudou mesmo com a transação revertida."
    );
});