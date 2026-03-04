// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICompliance.sol";

contract BasicCompliance is ICompliance, Ownable {
    address private _tokenBound;

    modifier onlyToken() {
        require(msg.sender == _tokenBound, "BasicCompliance: only token contract can call");
        _;
    }

    function bindToken(address _token) external override onlyOwner {
        require(_token != address(0), "BasicCompliance: token address cannot be zero");
        _tokenBound = _token;
        emit TokenBound(_token);
    }

    function unbindToken(address _token) external override onlyOwner {
        require(_tokenBound == _token, "BasicCompliance: token not bound");
        _tokenBound = address(0);
        emit TokenUnbound(_token);
    }

    function isTokenBound(address _token) external view override returns (bool) {
        return _tokenBound == _token;
    }

    function canTransfer(address /*_from*/, address /*_to*/, uint256 /*_amount*/) external pure override returns (bool) {
        // Basic compliance: allow all transfers.
        // Override in derived contracts to add compliance rules.
        return true;
    }

    function transferred(address /*_from*/, address /*_to*/, uint256 /*_amount*/) external override onlyToken {
        // Record transfer for compliance tracking
    }

    function created(address /*_to*/, uint256 /*_amount*/) external override onlyToken {
        // Record minting for compliance tracking
    }

    function destroyed(address /*_userAddress*/, uint256 /*_amount*/) external override onlyToken {
        // Record burning for compliance tracking
    }

    function transferOwnershipOnComplianceContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
