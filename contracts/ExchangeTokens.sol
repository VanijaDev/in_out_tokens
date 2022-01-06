// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ExchangeTokens is Ownable {
  enum TokenType {
    erc20,
    erc721,
    erc1155
  }

  mapping(address => bool) public allowedTokenIn;
  mapping(address => bool) public allowAllIdsForToken;
  mapping(address => mapping(uint256 => bool)) public allowedTokenIdForTokenIn; //  token => (index => bool)
  
  address[] public tokensOut;
  mapping(address => uint256[]) public tokenIdsOut;
  //  TODO: add mapping token index in tokensOut. It is needed if owner wants to remove tokens.
  //  TODO: add mapping token id index in tokenIdsOut. It is needed if owner wants to remove token ids.
  mapping(address => mapping(uint256 => uint256)) public allowedAmountForTokenIdForTokenOut;  //  token => (index => amount)

  event Exchanged(address tokenIn, uint256 tokenIdIn, address tokenOut, uint256 tokenIdOut);

  /**
   * @dev Constructor.
   * @notice Use token index 0 if all ids are allowed.
   * @param _allowedTokensIn Token addresses allowed to be accepted.
   * @param _tokenIdsIn Token ids for address allowed to be accepted. Index of _tokenIdsIn array should match respectful index of _allowedTokensIn. Set 0 if _allowAllIn for token. Example: ([false, true, false], [0x123, 0x234, 0x345], [[1, 2, 4], [0], [111]], [...], [...]).
   * @param _allowAllIn Whether should allow all ids for token to be accepted.
   * @param _allowedTokensOut Token addresses allowed to be returned.
   * @param _tokenIdsOut Token ids for address allowed to be returned. Index of _tokenIdsOut array should match respectful index of _allowedTokensOut.
   * @param _tokenAmountOut Allowed amount of each _tokenIdsOut to be transferred out.
   */
  constructor(address[] _allowedTokensIn, uint256[][] _tokenIdsIn, bool[] _allowAllIn, address[] _allowedTokensOut, uint256[][] _tokenIdsOut, uint256[] _tokenAmountForIdxOut) {
    //  in
    uint256 tokensLengthIn = _allowedTokensIn.length; //  less gas if a lot of items.
    for (uint256 i = 0; i < tokensLengthIn; i++) {
      address tokenIn = _allowedTokensIn[i];
      allowedTokenIn[tokenIn] = true;

      if (_allowAllIn[i]) {
        allowAllIdsForToken[tokenIn] = true;
      } else {
        uint256 idsIn = _tokenIdsIn[i];
        uint256 idsLengthIn = idsIn.length; //  less gas if a lot of items.
        for (uint256 j = 0; j < _tokenIdsIn.length; j++) {
          allowedTokenIdForTokenIn[tokenIn][idsIn[i][j]] = true;
        }
      }
    }

    //  out
    uint256 tokenLengthOut = _allowedTokensOut.length;
    for (uint256 k = 0; k < tokenLengthOut; k++) {
      address tokenOut = _allowedTokensOut[k];
      tokensOut.push(tokenOut);
      tokenIdsOut[tokenOut].push(_tokenIdsOut);

      uint256 tokenIdsLengthOut = _tokenIdsOut.length;
      for (uint256 l = 0; l < tokenIdsLengthOut.length; l++) {
        uint256 tokenId = _tokenIdsOut[k];
        uint256 amount = _tokenAmountForIdxOut[tokenId];
        allowedAmountForTokenIdForTokenOut[tokenOut][tokenId] = amount;
      }
    }
  }

  /**
    * @dev Adds token addresses allowed to be accepted.
    * @notice Use token index 0 if all ids are allowed.
    * @param _allowedTokensIn Token addresses allowed to be accepted.
    * @param _tokenIdsIn Token ids for address allowed to be accepted. Index of _tokenIdsIn array should match respectful index of _allowedTokensIn.
    * @param _allowAllIn Whether should allow all ids for token to be accepted.
   */
  function addTokensIn(address[] _allowedTokensIn, uint256[][] _tokenIdsIn, bool[] _allowAllIn) external onlyOwner {
    uint256 tokensLengthIn = _allowedTokensIn.length; //  less gas if a lot of items.
    for (uint256 i = 0; i < tokensLengthIn; i++) {
      address tokenIn = _allowedTokensIn[i];
      require(!allowAllIdsForToken[tokenIn], "All allowed");
      
      if (_allowAllIn[i]) {
        allowAllIdsForToken[tokenIn] = true;
        continue;
      }

      if (!allowedTokenIn[tokenIn]) {
        allowedTokenIn[tokenIn] = true; //  don't spend gas on writing if already added.
      }

      uint256 idsIn = _tokenIdsIn[i];
      uint256 idsLengthIn = idsIn.length; //  less gas if a lot of items.
      for (uint256 j = 0; j < _tokenIdsIn.length; j++) {
        if (!allowedTokenIdForTokenIn[tokenIn][idsIn[i][j]]) {
          allowedTokenIdForTokenIn[tokenIn][idsIn[i][j]] = true;  //  don't spend gas on writing if already added.
        }
      }
    }
  }

  /**
   * @dev Exchanges tokens.
   * @notice User must approve before this call.
   * @param _token Token address.
   * @param _id Token id
   * @param _amount Amount to be sent.
   */
  function exchange(TokenType _tokenType, address _token, uint256 _id, uint256 _amount) external {
    if (_tokenType == TokenType.erc20) {
      IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    } else if (_tokenType == TokenType.erc721) {
      ERC721(_token).transferFrom(msg.sender, address(this), _id);
    } else if (_tokenType == TokenType.erc1155) {
      IERC1155(_token).safeTransferFrom(msg.sender, address(this), _id, _amount, "");
    }

    //  TODO: better randomness
    
  }
}
