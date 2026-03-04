// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IERC3643.sol";
import "../interfaces/IIdentityRegistry.sol";
import "../interfaces/ICompliance.sol";
import "../roles/AgentRole.sol";

/**
 * @title Token
 * @dev ERC-3643 compliant security token implementation.
 * Implements permissioned transfers with identity verification and compliance checks.
 */
contract Token is IERC3643, ERC20, Pausable, AgentRole {
    uint8 private _tokenDecimals;
    string private _tokenVersion;
    address private _tokenOnchainID;
    IIdentityRegistry private _identityRegistry;
    ICompliance private _tokenCompliance;

    mapping(address => bool) private _frozen;
    mapping(address => uint256) private _frozenTokens;
    bool private _forcedTransferInProgress;

    constructor(
        address _identityRegistryAddress,
        address _complianceAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address tokenOnchainID
    ) ERC20(tokenName, tokenSymbol) {
        require(_identityRegistryAddress != address(0), "Token: identity registry cannot be zero");
        require(_complianceAddress != address(0), "Token: compliance cannot be zero");
        _tokenDecimals = tokenDecimals;
        _tokenVersion = "4.0";
        _tokenOnchainID = tokenOnchainID;
        _identityRegistry = IIdentityRegistry(_identityRegistryAddress);
        _tokenCompliance = ICompliance(_complianceAddress);
        emit IdentityRegistryAdded(_identityRegistryAddress);
        emit ComplianceAdded(_complianceAddress);
    }

    function decimals() public view override(ERC20, IERC3643) returns (uint8) {
        return _tokenDecimals;
    }

    function name() public view override(ERC20, IERC3643) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(ERC20, IERC3643) returns (string memory) {
        return super.symbol();
    }

    function onchainID() external view override returns (address) {
        return _tokenOnchainID;
    }

    function version() external view override returns (string memory) {
        return _tokenVersion;
    }

    function identityRegistry() external view override returns (address) {
        return address(_identityRegistry);
    }

    function compliance() external view override returns (address) {
        return address(_tokenCompliance);
    }

    function paused() public view override(Pausable, IERC3643) returns (bool) {
        return super.paused();
    }

    function pause() external override onlyAgent {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external override onlyAgent {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function isFrozen(address _userAddress) external view override returns (bool) {
        return _frozen[_userAddress];
    }

    function getFrozenTokens(address _userAddress) external view override returns (uint256) {
        return _frozenTokens[_userAddress];
    }

    function setAddressFrozen(address _userAddress, bool _freeze) external override onlyAgent {
        _setAddressFrozen(_userAddress, _freeze);
    }

    function freezePartialTokens(address _userAddress, uint256 _amount) external override onlyAgent {
        _freezePartialTokens(_userAddress, _amount);
    }

    function unfreezePartialTokens(address _userAddress, uint256 _amount) external override onlyAgent {
        _unfreezePartialTokens(_userAddress, _amount);
    }

    function setIdentityRegistry(address _identityRegistryAddress) external override onlyOwner {
        require(_identityRegistryAddress != address(0), "Token: identity registry cannot be zero");
        _identityRegistry = IIdentityRegistry(_identityRegistryAddress);
        emit IdentityRegistryAdded(_identityRegistryAddress);
    }

    function setCompliance(address _complianceAddress) external override onlyOwner {
        require(_complianceAddress != address(0), "Token: compliance cannot be zero");
        _tokenCompliance = ICompliance(_complianceAddress);
        emit ComplianceAdded(_complianceAddress);
    }

    function mint(address _to, uint256 _amount) external override onlyAgent whenNotPaused {
        _agentMint(_to, _amount);
    }

    function burn(address _userAddress, uint256 _amount) external override onlyAgent whenNotPaused {
        _agentBurn(_userAddress, _amount);
    }

    function forcedTransfer(address _from, address _to, uint256 _amount) external override onlyAgent whenNotPaused returns (bool) {
        return _agentForcedTransfer(_from, _to, _amount);
    }

    function recoveryAddress(address _lostWallet, address _newWallet, address _investorOnchainID) external override onlyAgent returns (bool) {
        require(balanceOf(_lostWallet) > 0, "Token: no tokens to recover");
        require(_identityRegistry.isVerified(_newWallet), "Token: new wallet is not verified");
        uint256 amount = balanceOf(_lostWallet);
        uint256 frozenAmt = _frozenTokens[_lostWallet];
        if (frozenAmt > 0) {
            _frozenTokens[_lostWallet] = 0;
            emit TokensUnfrozen(_lostWallet, frozenAmt);
        }
        _transfer(_lostWallet, _newWallet, amount);
        _identityRegistry.updateIdentity(_lostWallet, _identityRegistry.identity(_newWallet));
        emit RecoverySuccess(_lostWallet, _newWallet, _investorOnchainID);
        return true;
    }

    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external override whenNotPaused {
        uint256 length = _toList.length;
        require(length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            transfer(_toList[i], _amounts[i]);
        }
    }

    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override onlyAgent whenNotPaused {
        uint256 length = _fromList.length;
        require(length == _toList.length && length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _agentForcedTransfer(_fromList[i], _toList[i], _amounts[i]);
        }
    }

    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external override onlyAgent whenNotPaused {
        uint256 length = _toList.length;
        require(length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _agentMint(_toList[i], _amounts[i]);
        }
    }

    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external override onlyAgent whenNotPaused {
        uint256 length = _userAddresses.length;
        require(length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _agentBurn(_userAddresses[i], _amounts[i]);
        }
    }

    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external override onlyAgent {
        uint256 length = _userAddresses.length;
        require(length == _freeze.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _setAddressFrozen(_userAddresses[i], _freeze[i]);
        }
    }

    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override onlyAgent {
        uint256 length = _userAddresses.length;
        require(length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _freezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override onlyAgent {
        uint256 length = _userAddresses.length;
        require(length == _amounts.length, "Token: arrays length mismatch");
        for (uint256 i = 0; i < length; i++) {
            _unfreezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    function updateTokenInformation(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        string calldata _version,
        address _onchainID
    ) external override onlyOwner {
        _tokenDecimals = _decimals;
        _tokenVersion = _version;
        _tokenOnchainID = _onchainID;
        emit UpdatedTokenInformation(_name, _symbol, _decimals, _version, _onchainID);
    }

    function transferOwnershipOnTokenContract(address _newOwner) external override onlyOwner {
        transferOwnership(_newOwner);
    }

    function addAgentOnTokenContract(address _agent) external override onlyOwner {
        addAgent(_agent);
    }

    function removeAgentOnTokenContract(address _agent) external override onlyOwner {
        removeAgent(_agent);
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        return super.transfer(to, amount);
    }

    function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    // ---- Internal helpers ----

    function _agentMint(address _to, uint256 _amount) internal {
        require(_identityRegistry.isVerified(_to), "Token: investor is not verified");
        require(_tokenCompliance.canTransfer(address(0), _to, _amount), "Token: compliance check failed");
        _mint(_to, _amount);
        _tokenCompliance.created(_to, _amount);
    }

    function _agentBurn(address _userAddress, uint256 _amount) internal {
        require(
            balanceOf(_userAddress) - _frozenTokens[_userAddress] >= _amount,
            "Token: insufficient unfrozen balance"
        );
        _burn(_userAddress, _amount);
        _tokenCompliance.destroyed(_userAddress, _amount);
    }

    function _agentForcedTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        require(_identityRegistry.isVerified(_to), "Token: receiver is not verified");
        require(balanceOf(_from) >= _amount, "Token: insufficient balance");
        uint256 freeBalance = balanceOf(_from) - _frozenTokens[_from];
        if (_amount > freeBalance) {
            uint256 tokensToUnfreeze = _amount - freeBalance;
            _frozenTokens[_from] -= tokensToUnfreeze;
            emit TokensUnfrozen(_from, tokensToUnfreeze);
        }
        _forcedTransferInProgress = true;
        _transfer(_from, _to, _amount);
        _forcedTransferInProgress = false;
        // _afterTokenTransfer handles compliance.transferred for regular transfers;
        // forced transfers call it directly here so the flag is already cleared.
        _tokenCompliance.transferred(_from, _to, _amount);
        return true;
    }

    function _setAddressFrozen(address _userAddress, bool _freeze) internal {
        _frozen[_userAddress] = _freeze;
        emit AddressFrozen(_userAddress, _freeze, msg.sender);
    }

    function _freezePartialTokens(address _userAddress, uint256 _amount) internal {
        uint256 balance = balanceOf(_userAddress);
        require(balance >= _frozenTokens[_userAddress] + _amount, "Token: amount exceeds available balance");
        _frozenTokens[_userAddress] += _amount;
        emit TokensFrozen(_userAddress, _amount);
    }

    function _unfreezePartialTokens(address _userAddress, uint256 _amount) internal {
        require(_frozenTokens[_userAddress] >= _amount, "Token: amount exceeds frozen tokens");
        _frozenTokens[_userAddress] -= _amount;
        emit TokensUnfrozen(_userAddress, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal override whenNotPaused {
        if (from != address(0) && to != address(0)) {
            if (!_forcedTransferInProgress) {
                require(!_frozen[from] && !_frozen[to], "Token: wallet is frozen");
                require(
                    value <= balanceOf(from) - _frozenTokens[from],
                    "Token: insufficient unfrozen balance"
                );
            }
            require(_identityRegistry.isVerified(to), "Token: receiver is not verified");
            require(_tokenCompliance.canTransfer(from, to, value), "Token: compliance check failed");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0) && !_forcedTransferInProgress) {
            _tokenCompliance.transferred(from, to, value);
        }
    }
}
