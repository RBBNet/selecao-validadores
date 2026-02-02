// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAdminProxy} from "src/interfaces/IAdminProxy.sol";

/**
 * @title AdminMockDev
 * @notice Mock simplificado do AdminProxy para desenvolvimento local
 * @dev Autoriza automaticamente o deployer e qualquer endereço Anvil padrão
 */
contract AdminMockDev is IAdminProxy {
    address[] private admins;
    
    modifier onlyAdmin() {
        require(isAuthorized(msg.sender), "Sender not authorized");
        _;
    }

    modifier notSelf(address _address) {
        require(msg.sender != _address, "Cannot invoke method with own account as parameter");
        _;
    }

    constructor() {
        admins.push(msg.sender);
        
        admins.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266); // Account #0
        admins.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8); // Account #1
        admins.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC); // Account #2
    }

    /**
     * @notice Verifica se um endereço é autorizado
     * @dev Permite contas Anvil padrão OU admins adicionados
     */
    function isAuthorized(address _address) public view returns (bool) {
        if (_address == 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) return true; // Account #0
        if (_address == 0x70997970C51812dc3A010C7d01b50e0d17dc79C8) return true; // Account #1
        if (_address == 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) return true; // Account #2
        if (_address == 0x90F79bf6EB2c4f870365E785982E1f101E93b906) return true; // Account #3
        if (_address == 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65) return true; // Account #4
        
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _address) {
                return true;
            }
        }
        
        return false;
    }

    function addAdmin(address _address) public onlyAdmin returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _address) {
                return true;
            }
        }
        
        admins.push(_address);
        return true;
    }

    function removeAdmin(address _address) public onlyAdmin notSelf(_address) returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _address) {
                // Move último elemento para a posição e remove último
                admins[i] = admins[admins.length - 1];
                admins.pop();
                return true;
            }
        }
        return false;
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }

    function addAdmins(address[] memory accounts) public onlyAdmin returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            addAdmin(accounts[i]);
        }
        return true;
    }
}
