// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IIdentityRegistryStorage {
    event IdentityStored(address indexed investorAddress, address indexed identity);
    event IdentityUnstored(address indexed investorAddress, address indexed identity);
    event IdentityModified(address indexed oldIdentity, address indexed newIdentity);
    event CountryModified(address indexed investorAddress, uint16 indexed country);
    event IdentityRegistryBound(address indexed identityRegistry);
    event IdentityRegistryUnbound(address indexed identityRegistry);

    function addIdentityToStorage(address _userAddress, address _identity, uint16 _country) external;
    function removeIdentityFromStorage(address _userAddress) external;
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;
    function modifyStoredIdentity(address _userAddress, address _identity) external;
    function storedIdentity(address _userAddress) external view returns (address);
    function storedInvestorCountry(address _userAddress) external view returns (uint16);
    function linkedIdentityRegistries() external view returns (address[] memory);
    function bindIdentityRegistry(address _identityRegistry) external;
    function unbindIdentityRegistry(address _identityRegistry) external;
    function transferOwnershipOnIdentityRegistryStorage(address _newOwner) external;
    function addAgentOnIdentityRegistryStorage(address _agent) external;
    function removeAgentOnIdentityRegistryStorage(address _agent) external;
}
