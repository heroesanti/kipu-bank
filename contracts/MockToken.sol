// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract MockToken is ERC20, Ownable, ERC20Burnable, ERC20Permit {
    constructor(address initialOwner) ERC20("Mock Token", "MTK") Ownable(initialOwner) ERC20Permit("Mock Token") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
    //ERC20("PegoToken", "PET")
        // Ownable(initialOwner)
        // ERC20Permit("PegoToken")

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
