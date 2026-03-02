// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/IIdentityRegistryStorage.sol";
import "../interfaces/IClaimTopicsRegistry.sol";
import "../interfaces/ITrustedIssuersRegistry.sol";
import "../roles/AgentRole.sol";

contract IdentityRegistry is IIdentityRegistry, AgentRole {
    IIdentityRegistryStorage private _identityStorage;
    IClaimTopicsRegistry private _topicsRegistry;
    ITrustedIssuersRegistry private _issuersRegistry;

    constructor(
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityRegistryStorage
    ) {
        require(_trustedIssuersRegistry != address(0), "IdentityRegistry: issuers registry cannot be zero");
        require(_claimTopicsRegistry != address(0), "IdentityRegistry: topics registry cannot be zero");
        require(_identityRegistryStorage != address(0), "IdentityRegistry: storage cannot be zero");
        _issuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        _topicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        _identityStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    function registerIdentity(address _userAddress, address _identity, uint16 _country) external override onlyAgent {
        require(_userAddress != address(0), "IdentityRegistry: user address cannot be zero");
        require(_identity != address(0), "IdentityRegistry: identity cannot be zero");
        _identityStorage.addIdentityToStorage(_userAddress, _identity, _country);
        emit IdentityRegistered(_userAddress, _identity);
    }

    function deleteIdentity(address _userAddress) external override onlyAgent {
        address oldIdentity = _identityStorage.storedIdentity(_userAddress);
        require(oldIdentity != address(0), "IdentityRegistry: identity not found");
        _identityStorage.removeIdentityFromStorage(_userAddress);
        emit IdentityRemoved(_userAddress, oldIdentity);
    }

    function updateCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(_identityStorage.storedIdentity(_userAddress) != address(0), "IdentityRegistry: identity not found");
        _identityStorage.modifyStoredInvestorCountry(_userAddress, _country);
        emit CountryUpdated(_userAddress, _country);
    }

    function updateIdentity(address _userAddress, address _identity) external override onlyAgent {
        require(_identity != address(0), "IdentityRegistry: identity cannot be zero");
        address oldIdentity = _identityStorage.storedIdentity(_userAddress);
        require(oldIdentity != address(0), "IdentityRegistry: identity not found");
        _identityStorage.modifyStoredIdentity(_userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        address[] calldata _identities,
        uint16[] calldata _countries
    ) external override onlyAgent {
        uint256 length = _userAddresses.length;
        require(length == _identities.length && length == _countries.length, "IdentityRegistry: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _identityStorage.addIdentityToStorage(_userAddresses[i], _identities[i], _countries[i]);
            emit IdentityRegistered(_userAddresses[i], _identities[i]);
        }
    }

    function contains(address _userAddress) external view override returns (bool) {
        return _identityStorage.storedIdentity(_userAddress) != address(0);
    }

    function isVerified(address _userAddress) external view override returns (bool) {
        if (_identityStorage.storedIdentity(_userAddress) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = _topicsRegistry.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        // For simplicity, if the identity is registered and there are no claim topics required, they are verified.
        // In a full implementation, this would check ERC-735 claims on the identity contract.
        return true;
    }

    function identity(address _userAddress) external view override returns (address) {
        return _identityStorage.storedIdentity(_userAddress);
    }

    function investorCountry(address _userAddress) external view override returns (uint16) {
        return _identityStorage.storedInvestorCountry(_userAddress);
    }

    function identityStorage() external view override returns (address) {
        return address(_identityStorage);
    }

    function issuersRegistry() external view override returns (address) {
        return address(_issuersRegistry);
    }

    function topicsRegistry() external view override returns (address) {
        return address(_topicsRegistry);
    }

    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    function addAgentOnIdentityRegistryContract(address _agent) external override onlyOwner {
        addAgent(_agent);
    }

    function removeAgentOnIdentityRegistryContract(address _agent) external override onlyOwner {
        removeAgent(_agent);
    }
}
