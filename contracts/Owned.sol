// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

abstract contract Owned {
    address public owner;

    event OwnerUpdated(address indexed user, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
        emit OwnerUpdated(address(0), _owner);
    }

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }
}
