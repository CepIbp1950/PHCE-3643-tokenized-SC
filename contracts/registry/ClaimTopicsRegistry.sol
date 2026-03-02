// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IClaimTopicsRegistry.sol";

contract ClaimTopicsRegistry is IClaimTopicsRegistry, Ownable {
    uint256[] private _claimTopics;

    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = _claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            require(_claimTopics[i] != _claimTopic, "ClaimTopicsRegistry: claim topic already exists");
        }
        _claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = _claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (_claimTopics[i] == _claimTopic) {
                _claimTopics[i] = _claimTopics[length - 1];
                _claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                return;
            }
        }
        revert("ClaimTopicsRegistry: claim topic not found");
    }

    function getClaimTopics() external view override returns (uint256[] memory) {
        return _claimTopics;
    }

    function transferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
