// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIdentityRegistryStorage.sol";
import "../roles/AgentRole.sol";

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRole {
    struct Identity {
        address identityContract;
        uint16 investorCountry;
    }

    mapping(address => Identity) private _identities;
    address[] private _linkedRegistries;

    function addIdentityToStorage(address _userAddress, address _identity, uint16 _country) external override onlyAgent {
        require(_identity != address(0), "IdentityRegistryStorage: identity cannot be zero address");
        require(_identities[_userAddress].identityContract == address(0), "IdentityRegistryStorage: identity already stored");
        _identities[_userAddress] = Identity(_identity, _country);
        emit IdentityStored(_userAddress, _identity);
    }

    function removeIdentityFromStorage(address _userAddress) external override onlyAgent {
        require(_identities[_userAddress].identityContract != address(0), "IdentityRegistryStorage: identity not found");
        address oldIdentity = _identities[_userAddress].identityContract;
        delete _identities[_userAddress];
        emit IdentityUnstored(_userAddress, oldIdentity);
    }

    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(_identities[_userAddress].identityContract != address(0), "IdentityRegistryStorage: identity not found");
        _identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    function modifyStoredIdentity(address _userAddress, address _identity) external override onlyAgent {
        require(_identities[_userAddress].identityContract != address(0), "IdentityRegistryStorage: identity not found");
        require(_identity != address(0), "IdentityRegistryStorage: identity cannot be zero address");
        address oldIdentity = _identities[_userAddress].identityContract;
        _identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    function storedIdentity(address _userAddress) external view override returns (address) {
        return _identities[_userAddress].identityContract;
    }

    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return _identities[_userAddress].investorCountry;
    }

    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return _linkedRegistries;
    }

    function bindIdentityRegistry(address _identityRegistry) external override onlyAgent {
        require(_identityRegistry != address(0), "IdentityRegistryStorage: registry cannot be zero address");
        _linkedRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    function unbindIdentityRegistry(address _identityRegistry) external override onlyAgent {
        uint256 length = _linkedRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (_linkedRegistries[i] == _identityRegistry) {
                _linkedRegistries[i] = _linkedRegistries[length - 1];
                _linkedRegistries.pop();
                emit IdentityRegistryUnbound(_identityRegistry);
                return;
            }
        }
        revert("IdentityRegistryStorage: registry not found");
    }

    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    function addAgentOnIdentityRegistryStorage(address _agent) external override onlyOwner {
        addAgent(_agent);
    }

    function removeAgentOnIdentityRegistryStorage(address _agent) external override onlyOwner {
        removeAgent(_agent);
    }
}
