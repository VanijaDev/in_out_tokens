// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("TestERC20", "T20") {
  constructor() {
    _mint(msg.sender, 1000 * 10**18);
  }
}
