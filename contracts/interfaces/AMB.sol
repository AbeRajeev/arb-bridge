// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAMB {
    function send(
        address user,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signature
    ) external payable;

    function executeSignatures(
        address user,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) external payable;
}
