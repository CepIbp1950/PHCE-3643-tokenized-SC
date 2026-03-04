// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AgentRole is Ownable {
    mapping(address => bool) private _agents;

    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);

    modifier onlyAgent() {
        require(isAgent(msg.sender), "AgentRole: caller is not an agent");
        _;
    }

    function addAgent(address _agent) public onlyOwner {
        require(_agent != address(0), "AgentRole: agent address cannot be zero");
        _agents[_agent] = true;
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        require(_agents[_agent], "AgentRole: agent not found");
        _agents[_agent] = false;
        emit AgentRemoved(_agent);
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agents[_agent];
    }
}
