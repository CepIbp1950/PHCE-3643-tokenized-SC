// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrustedIssuersRegistry.sol";

contract TrustedIssuersRegistry is ITrustedIssuersRegistry, Ownable {
    address[] private _trustedIssuers;
    mapping(address => uint256[]) private _claimTopics;

    function addTrustedIssuer(address _trustedIssuer, uint256[] calldata _issuerClaimTopics) external override onlyOwner {
        require(_trustedIssuer != address(0), "TrustedIssuersRegistry: issuer address cannot be zero");
        require(_claimTopics[_trustedIssuer].length == 0, "TrustedIssuersRegistry: trusted issuer already exists");
        require(_issuerClaimTopics.length > 0, "TrustedIssuersRegistry: claim topics cannot be empty");
        _trustedIssuers.push(_trustedIssuer);
        _claimTopics[_trustedIssuer] = _issuerClaimTopics;
        emit TrustedIssuerAdded(_trustedIssuer, _issuerClaimTopics);
    }

    function removeTrustedIssuer(address _trustedIssuer) external override onlyOwner {
        require(_claimTopics[_trustedIssuer].length > 0, "TrustedIssuersRegistry: issuer not found");
        uint256 length = _trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (_trustedIssuers[i] == _trustedIssuer) {
                _trustedIssuers[i] = _trustedIssuers[length - 1];
                _trustedIssuers.pop();
                break;
            }
        }
        delete _claimTopics[_trustedIssuer];
        emit TrustedIssuerRemoved(_trustedIssuer);
    }

    function updateIssuerClaimTopics(address _trustedIssuer, uint256[] calldata _issuerClaimTopics) external override onlyOwner {
        require(_claimTopics[_trustedIssuer].length > 0, "TrustedIssuersRegistry: issuer not found");
        require(_issuerClaimTopics.length > 0, "TrustedIssuersRegistry: claim topics cannot be empty");
        _claimTopics[_trustedIssuer] = _issuerClaimTopics;
        emit ClaimTopicsUpdated(_trustedIssuer, _issuerClaimTopics);
    }

    function getTrustedIssuers() external view override returns (address[] memory) {
        return _trustedIssuers;
    }

    function isTrustedIssuer(address _issuer) external view override returns (bool) {
        return _claimTopics[_issuer].length > 0;
    }

    function getTrustedIssuerClaimTopics(address _trustedIssuer) external view override returns (uint256[] memory) {
        require(_claimTopics[_trustedIssuer].length > 0, "TrustedIssuersRegistry: issuer not found");
        return _claimTopics[_trustedIssuer];
    }

    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view override returns (bool) {
        uint256[] memory topics = _claimTopics[_issuer];
        uint256 length = topics.length;
        for (uint256 i = 0; i < length; i++) {
            if (topics[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }

    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }
}
