// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface ICompliance {
    event TokenBound(address indexed token);
    event TokenUnbound(address indexed token);

    function bindToken(address _token) external;
    function unbindToken(address _token) external;
    function isTokenBound(address _token) external view returns (bool);
    function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool);
    function transferred(address _from, address _to, uint256 _amount) external;
    function created(address _to, uint256 _amount) external;
    function destroyed(address _userAddress, uint256 _amount) external;
    function transferOwnershipOnComplianceContract(address _newOwner) external;
}
