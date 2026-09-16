import assert from 'node:assert';

/**
 * Helper para decodificar e extrair o nome do erro customizado de EVM
 */
export function extractRevertErrorName(error, ifaces = []) {
    if (!error) return null;
    if (error.errorName) return error.errorName;
    if (error.revert && error.revert.name) return error.revert.name;

    const data = error.data ?? error.error?.data ?? error.info?.error?.data ?? null;

    if (typeof data === 'string' && data.startsWith('0x')) {
        for (const iface of ifaces) {
            if (!iface) continue;
            try {
                const parsed = iface.parseError(data);
                if (parsed) return parsed.name;
            } catch (_) {}
        }
    }

    const match = /(?:custom error|error) '?(\w+)\(/.exec(error.message || '') || /reverted with reason string '(\w+)'/.exec(error.message || '');
    return match ? match[1] : null;
}

/**
 * Compara arrays de endereços ignorando ordem e capitalização
 */
export function assertSameAddressSet(actual, expected, message) {
    const normalize = (arr) => [...arr].map((a) => a.toLowerCase()).sort();
    assert.deepStrictEqual(normalize(actual), normalize(expected), message);
}

/**
 * Alguns cenários guardam o erro da transação em world.lastTxError (fluxos "genéricos",
 * tipo configuração/modo) e outros em world.deployError (fluxo de deploy_selecao.feature).
 * Como vários textos de Then são reaproveitados entre os dois .feature, este helper
 * olha os dois campos para não quebrar dependendo de qual fluxo chamou o step.
 */
export function getLastError(world) {
    return world.lastTxError ?? world.deployError ?? null;
}

/**
 * Helper: deriva endereço e "nodeKey" a partir de um par de enode, espelhando
 * exatamente _calculateAddress/_calculateKey do ValidatorSelection.sol:
 *   nodeKey = uint256(keccak256(abi.encodePacked(enodeHigh, enodeLow)))
 *   address = address(uint160(nodeKey))  -> ou seja, os últimos 20 bytes do mesmo hash
 */
export function computeNodeFromEnode(enodeHigh, enodeLow, ethers) {
    const hash = ethers.solidityPackedKeccak256(["bytes32", "bytes32"], [enodeHigh, enodeLow]);
    const address = ethers.getAddress("0x" + hash.slice(-40));
    const nodeKey = BigInt(hash);
    return { address, nodeKey };
}

/**
 * Gera um par de enode "único" por cenário (evita colisão entre Cenários que
 * rodam na mesma rede simulada dentro do mesmo processo).
 */
export function generateEnodePair(world) {
    const n = (world._enodeCounter++).toString(16).padStart(4, "0");
    const enodeHigh = "0x" + ("11" + n).padEnd(64, "0");
    const enodeLow = "0x" + ("22" + n).padEnd(64, "0");
    return { enodeHigh, enodeLow };
}

/**
 * Retorna a lista padrão de validadores (primeiros 5 signers)
 */
export function getStandardValidatorsList(world) {
    return [
        world.validator1.address,
        world.validator2.address,
        world.validator3.address,
        world.validator4.address,
        world.validator5.address
    ];
}

/**
 * Implanta o ValidatorSelection com os parâmetros padrão de teste (2, 10, 10) e a lista padrão de validadores
 */
export async function deployStandardValidatorSelection(world) {
    world.initialValidatorsList = getStandardValidatorsList(world);
    const ValidatorSelectionFactory = await world.ethers.getContractFactory("ValidatorSelection");
    world.validatorSelection = await ValidatorSelectionFactory.deploy(
        await world.adminMock.getAddress(),
        await world.accountRulesMock.getAddress(),
        await world.nodeRulesMock.getAddress(),
        world.initialValidatorsList,
        2, 10, 10
    );
    await world.validatorSelection.waitForDeployment();
    return world.validatorSelection;
}