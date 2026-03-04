// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ITrustedIssuersRegistry {
    event TrustedIssuerAdded(address indexed trustedIssuer, uint256[] claimTopics);
    event TrustedIssuerRemoved(address indexed trustedIssuer);
    event ClaimTopicsUpdated(address indexed trustedIssuer, uint256[] claimTopics);

    function addTrustedIssuer(address _trustedIssuer, uint256[] calldata _claimTopics) external;
    function removeTrustedIssuer(address _trustedIssuer) external;
    function updateIssuerClaimTopics(address _trustedIssuer, uint256[] calldata _claimTopics) external;
    function getTrustedIssuers() external view returns (address[] memory);
    function isTrustedIssuer(address _issuer) external view returns (bool);
    function getTrustedIssuerClaimTopics(address _trustedIssuer) external view returns (uint256[] memory);
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);
    function transferOwnershipOnIssuersRegistryContract(address _newOwner) external;
}
