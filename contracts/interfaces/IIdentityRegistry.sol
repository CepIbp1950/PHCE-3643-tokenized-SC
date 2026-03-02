// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IIdentityRegistry {
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);
    event IdentityStorageSet(address indexed identityStorage);
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);
    event IdentityRegistered(address indexed investorAddress, address indexed identity);
    event IdentityRemoved(address indexed investorAddress, address indexed identity);
    event IdentityUpdated(address indexed oldIdentity, address indexed newIdentity);
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    function registerIdentity(address _userAddress, address _identity, uint16 _country) external;
    function deleteIdentity(address _userAddress) external;
    function updateCountry(address _userAddress, uint16 _country) external;
    function updateIdentity(address _userAddress, address _identity) external;
    function batchRegisterIdentity(address[] calldata _userAddresses, address[] calldata _identities, uint16[] calldata _countries) external;
    function contains(address _userAddress) external view returns (bool);
    function isVerified(address _userAddress) external view returns (bool);
    function identity(address _userAddress) external view returns (address);
    function investorCountry(address _userAddress) external view returns (uint16);
    function identityStorage() external view returns (address);
    function issuersRegistry() external view returns (address);
    function topicsRegistry() external view returns (address);
    function transferOwnershipOnIdentityRegistryContract(address _newOwner) external;
    function addAgentOnIdentityRegistryContract(address _agent) external;
    function removeAgentOnIdentityRegistryContract(address _agent) external;
}
