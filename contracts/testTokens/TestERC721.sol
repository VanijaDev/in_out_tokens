// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721("TestERC721", "T721") {
  constructor() {
    _mint(msg.sender, 0);
    _mint(msg.sender, 1);
    _mint(msg.sender, 2);
    _mint(msg.sender, 3);
    _mint(msg.sender, 4);
  }
}
