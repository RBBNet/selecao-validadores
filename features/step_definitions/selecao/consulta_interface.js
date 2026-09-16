import { When, Then } from '@cucumber/cucumber';
import assert from 'node:assert';

When(/^a função de verificação de suporte a interface é acionada informando o identificador da interface erc-165 \((0x[0-9a-fA-F]+)\)$/, async function (interfaceId) {
    this.queryResult = await this.validatorSelection.supportsInterface(interfaceId);
});

When('a função de verificação de suporte a interface é acionada informando o identificador da interface erc-165', async function () {
    this.queryResult = await this.validatorSelection.supportsInterface("0x01ffc9a7");
});

When('a função de verificação de suporte a interface é acionada informando o identificador da interface de seleção de validadores', async function () {
    const hardhatModule = await import('hardhat');
    const hre = hardhatModule.default || hardhatModule;

    const artifact = await hre.artifacts.readArtifact("IValidatorSelection");
    const iface = new this.ethers.Interface(artifact.abi);

    let interfaceIdBigInt = 0n;
    iface.forEachFunction((fn) => {
        interfaceIdBigInt ^= BigInt(fn.selector);
    });

    const hexInterfaceId = "0x" + interfaceIdBigInt.toString(16).padStart(8, "0");
    this.queryResult = await this.validatorSelection.supportsInterface(hexInterfaceId);
});

When(/^a função de verificação de suporte a interface é acionada informando um identificador não suportado ou inválido \((0x[0-9a-fA-F]+)\)$/, async function (interfaceId) {
    this.queryResult = await this.validatorSelection.supportsInterface(interfaceId);
});

When('a função de verificação de suporte a interface é acionada informando um identificador não suportado ou inválido', async function () {
    this.queryResult = await this.validatorSelection.supportsInterface("0xffffffff");
});

Then('a chamada de leitura deve ser concluída com sucesso', async function () {
    assert.notStrictEqual(this.queryResult, undefined);
});

Then('o contrato deve retornar o valor booleano verdadeiro', async function () {
    assert.strictEqual(this.queryResult, true);
});

Then('o contrato deve retornar o valor booleano falso', async function () {
    assert.strictEqual(this.queryResult, false);
});