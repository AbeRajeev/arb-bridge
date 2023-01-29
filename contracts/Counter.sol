// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Owned} from "./Owned.sol";
import {IAMB} from "./interfaces/AMB.sol";

contract Counter is Owned {
    address public immutable bridge;

    uint256 public count;

    event CounterLatest(uint256 counter);

    constructor(address _bridge) Owned(_bridge) {
        bridge = _bridge;
    }

    function increment() public onlyOwner {
        count += 1;
        emit CounterLatest(count);
    }

    function send(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signature
    ) public payable {
        IAMB(bridge).send(msg.sender, to, value, data, signature);
    }
}
