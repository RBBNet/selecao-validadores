import { Given, When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { extractRevertErrorName, assertSameAddressSet } from '../support/cucumber-helpers.js';

Given('existem pelo menos {int} validadores operacionais ativos', async function (minimo) {
    let operational = await this.validatorSelection.getValidators();
    const extraSigners = [this.validator1, this.validator2, this.validator3, this.validator4, this.validator5, this.newValidator];
    let signerIndex = 0;

    while (operational.length < minimo && signerIndex < extraSigners.length) {
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
    this.operationalBefore = operational;
    this.eligibleBefore = await this.validatorSelection.getEligibleValidators();
});

Given('o intervalo entre seleções e o limite de inatividade estão configurados', async function () {
    const eligible = await this.validatorSelection.getEligibleValidators();
    const threshold = eligible.length;
    const interval = threshold + 5; 
    
    await this.validatorSelection.connect(this.governance).setSelectionParameters(interval, threshold);
});

Given('que o contrato de seleção de validadores está operando no modo manual', async function () {
    const currentMode = await this.validatorSelection.operationMode();
    if (currentMode !== 0n) {
        await this.validatorSelection.connect(this.governance).setOperationMode(0);
    }
});

Given('que o contrato de seleção de validadores está operando no modo automático', async function () {
    const currentMode = await this.validatorSelection.operationMode();
    if (currentMode !== 1n) {
        await this.validatorSelection.connect(this.governance).setOperationMode(1);
    }
});

Given('o bloco atual da rede ainda não atingiu o intervalo para selecionar validadores', async function () {
    await this.validatorSelection.runner.provider.send("hardhat_mine", ["0x1"]);
});

Given('o bloco atual da rede atingiu o intervalo para selecionar validadores', async function () {
    const interval = await this.validatorSelection.blocksBetweenSelection();
    await this.validatorSelection.runner.provider.send("hardhat_mine", [this.ethers.toBeHex(interval)]);
});

Given('o bloco atual da rede atingiu o intervalo parametrizado para selecionar validadores', async function () {
    const interval = await this.validatorSelection.blocksBetweenSelection();
    await this.validatorSelection.runner.provider.send("hardhat_mine", [this.ethers.toBeHex(interval)]);
});

Given('a monitoração ainda não foi executada para o bloco atual', async function () {
    const lastMonitoredBlock = await this.validatorSelection.lastMonitoredBlock();
    const currentBlock = await this.validatorSelection.runner.provider.getBlockNumber();
    assert.notStrictEqual(lastMonitoredBlock.toString(), currentBlock.toString(), "A monitoração já havia sido executada para o bloco atual.");
});

Given('a monitoração já foi executada para o bloco atual', async function () {
    await this.validatorSelection.runner.provider.send("evm_setAutomine", [false]);
    this.txExec1 = await this.validatorSelection.connect(this.validator1).executeMonitoring();
});

Given('existem validadores operacionais há mais blocos sem propor do que o limite tolerado', async function () {
    const interval = await this.validatorSelection.blocksBetweenSelection();
    await this.validatorSelection.runner.provider.send("hardhat_mine", [this.ethers.toBeHex(interval)]);
});

Given('esses validadores pré-selecionados para remoção não estão contidos no conjunto de validadores protegidos', async function () {
    await this.validatorSelection.connect(this.validator1).executeMonitoring();
    const interval = await this.validatorSelection.blocksBetweenSelection();
    await this.validatorSelection.runner.provider.send("hardhat_mine", [this.ethers.toBeHex(interval)]);
});

Given('esses validadores pré-selecionados estão contidos no conjunto de validadores protegidos', async function () {
    const operational = await this.validatorSelection.getValidators();
    const protectedSet = await this.validatorSelection.getProtectedValidators();
    assertSameAddressSet(protectedSet, operational, "O conjunto de validadores protegidos não contém todos os validadores operacionais.");
});

Given('ao menos {int} validadores permanecerão no conjunto de validadores operacionais após a exclusão', async function (minimo) {
    const protectedValidators = await this.validatorSelection.getProtectedValidators();
    const protectedCount = protectedValidators.length;
    const neededProtected = minimo - protectedCount;
    const newAddrs = [];

    for (let i = 0; i < neededProtected; i++) {
        const randomWallet = this.ethers.Wallet.createRandom();
        const addr = randomWallet.address;
        await this.validatorSelection.connect(this.governance).addEligibleValidatorByAddress(addr, true);
        newAddrs.push(addr);
    }

    const threshold = await this.validatorSelection.blocksWithoutProposeThreshold();
    const nextSelectionBlock = await this.validatorSelection.nextSelectionBlock();
    const cycleStart = await this.validatorSelection.cycleStartBlock();
    const currentBlock = await this.validatorSelection.runner.provider.getBlockNumber();

    const targetBlock = Math.max(
        Number(nextSelectionBlock),
        Number(cycleStart) + Number(threshold) + 1
    );

    if (currentBlock < targetBlock) {
        const blocksToMine = targetBlock - currentBlock;
        await this.validatorSelection.runner.provider.send("hardhat_mine", [this.ethers.toBeHex(blocksToMine)]);
    }

    const currentBlockAfterMine = await this.validatorSelection.runner.provider.getBlockNumber();
    const contractAddr = await this.validatorSelection.getAddress();

    for (const addr of newAddrs) {
        const slot = this.ethers.keccak256(
            this.ethers.AbiCoder.defaultAbiCoder().encode(["address", "uint256"], [addr, 15])
        );
        await this.validatorSelection.runner.provider.send("hardhat_setStorageAt", [
            contractAddr,
            slot,
            this.ethers.toBeHex(currentBlockAfterMine, 32)
        ]);
    }

    this.operationalBeforeExec = await this.validatorSelection.getValidators();
    this.eligibleBeforeExec = await this.validatorSelection.getEligibleValidators();
});

Given('após a eventual exclusão, não permaneceriam pelo menos {int} validadores no conjunto de operacionais', async function (minimo) {
    let operational = await this.validatorSelection.getValidators();
    while (operational.length > minimo) {
        await this.validatorSelection.connect(this.governance).removeOperationalValidatorByAddress(operational[0]);
        operational = await this.validatorSelection.getValidators();
    }
    this.operationalBeforeExec = operational;
});

When('a monitoração automática é executada por qualquer conta', async function () {
    const callerSigner = this.caller || this.validator1;
    this.operationalBeforeExec = await this.validatorSelection.getValidators();
    this.eligibleBeforeExec = await this.validatorSelection.getEligibleValidators();
    try {
        const tx = await this.validatorSelection.connect(callerSigner).executeMonitoring();
        this.receipt = await tx.wait();
    } catch (err) {
        this.lastTxError = err;
    }
});

When('a monitoração automática é executada novamente no mesmo bloco', async function () {
    const callerSigner = this.caller || this.validator1;
    this.txExec2 = await this.validatorSelection.connect(callerSigner).executeMonitoring();

    await this.validatorSelection.runner.provider.send("evm_setAutomine", [true]);
    await this.validatorSelection.runner.provider.send("evm_mine", []);
    
    await this.txExec1.wait();
    this.receipt = await this.txExec2.wait();
});

Then('a execução encerra imediatamente sem realizar registros de blocos ou seleções de validadores', async function () {
    assert.ok(this.receipt, "Não há recibo.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    
    const hasSelectionEvent = logs.some(l => l.name === 'SelectionExecuted');
    assert.ok(!hasSelectionEvent, "A seleção ocorreu indevidamente.");
});

Then('os conjuntos de validadores permanecem inalterados', async function () {
    const operationalAfter = await this.validatorSelection.getValidators();
    const normalize = (arr) => arr.map(a => a.toLowerCase());
    assert.deepStrictEqual(
        normalize(operationalAfter), 
        normalize(this.operationalBefore || this.operationalBeforeExec || []), 
        "O conjunto operacional sofreu mutação indevida."
    );
});

Then('um evento indicando a execução da monitoração deve ser emitido', async function () {
    assert.ok(this.receipt, "Não há recibo.");
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(logs.some(l => l.name === 'MonitorExecuted'), "Evento MonitorExecuted ausente.");
});

Then('a monitoração registra sua execução para o bloco atual', async function () {
    const lastMonitoredBlock = await this.validatorSelection.lastMonitoredBlock();
    assert.strictEqual(lastMonitoredBlock.toString(), this.receipt.blockNumber.toString(), "Bloco monitorado difere do bloco da transação.");
});

Then('a monitoração contabiliza o bloco atual na métrica de desempenho do validador que o propôs', async function () {
    const block = await this.validatorSelection.runner.provider.getBlock(this.receipt.blockNumber);
    const lastProposed = await this.validatorSelection.lastBlockProposedBy(block.miner);
    assert.strictEqual(lastProposed.toString(), this.receipt.blockNumber.toString(), "Bloco não contabilizado na mapping.");
});

Then('a monitoração contabiliza o bloco atual para o validador que o propôs', async function () {
    const block = await this.validatorSelection.runner.provider.getBlock(this.receipt.blockNumber);
    const lastProposed = await this.validatorSelection.lastBlockProposedBy(block.miner);
    assert.strictEqual(lastProposed.toString(), this.receipt.blockNumber.toString(), "Bloco não contabilizado na mapping.");
});

Then('a monitoração encerra sem selecionar ou remover validadores', async function () {
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(!logs.some(l => l.name === 'SelectionExecuted' || l.name === 'OperationalValidatorRemoved'), "Houve seleção ou remoção antes da hora.");
});

Then('a monitoração emite evento indicando os validadores operacionais a serem removidos', async function () {
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(logs.some(l => l.name === 'OperationalValidatorRemoved'), "Nenhum evento de remoção isolada foi emitido.");
});

Then('os validadores pré-selecionados são removidos do conjunto operacional, sendo mantidos como validadores elegíveis', async function () {
    const operationalAfter = await this.validatorSelection.getValidators();
    const eligibleAfter = await this.validatorSelection.getEligibleValidators();
    assert.ok(operationalAfter.length < this.operationalBeforeExec.length, "Ninguém foi expulso do conjunto operacional.");
    assert.strictEqual(eligibleAfter.length, this.eligibleBeforeExec.length, "Eles não deveriam ser expulsos do conjunto de elegíveis.");
});

Then('o conjunto de validadores protegidos é completamente esvaziado', async function () {
    const protectedList = await this.validatorSelection.getProtectedValidators();
    assert.strictEqual(protectedList.length, 0, "A lista de imunidade não foi esvaziada ao final do ciclo.");
});

Then('as informações acumuladas de produção de blocos são inicializadas \\(zeradas) e um novo ciclo de monitoração é iniciado', async function () {
    const cycleStart = await this.validatorSelection.cycleStartBlock();
    assert.strictEqual(cycleStart.toString(), this.receipt.blockNumber.toString(), "A variável cycleStartBlock não foi reinicializada.");
});

Then('a monitoração emite um evento final indicando a realização da seleção automática informando o conjunto resultante', async function () {
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(logs.some(l => l.name === 'SelectionExecuted'), "Evento final SelectionExecuted não foi encontrado no recibo.");
});

Then('a monitoração encerra sem realizar registros de blocos ou seleções adicionais', async function () {
    const logs = this.receipt.logs.map(log => {
        try { return this.validatorSelection.interface.parseLog(log); } catch (e) { return null; }
    }).filter(l => l !== null);
    assert.ok(!logs.some(l => l.name === 'SelectionExecuted'), "Ocorreu uma seleção indevida no mesmo bloco.");
});

Then('a remoção é vetada por segurança e os validadores pré-selecionados são mantidos como operacionais', async function () {
    const operationalAfter = await this.validatorSelection.getValidators();
    assert.strictEqual(operationalAfter.length, this.operationalBeforeExec.length, "A trava de segurança de nós operacionais falhou e nós foram removidos.");
});

Then('os validadores pré-selecionados são imunes e mantidos no conjunto de validadores operacionais', async function () {
    const operationalAfter = await this.validatorSelection.getValidators();
    assert.strictEqual(operationalAfter.length, this.operationalBeforeExec.length, "O bloqueio do conjunto de protegidos falhou.");
});