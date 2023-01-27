// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library BridgeLib {
    using ECDSA for bytes32;

    struct BridgeTransaction {
        address to;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 bond;
        bytes signature;
    }

    function toTransactionHash(BridgeTransaction memory transaction)
        internal
        pure
        returns (bytes32 result)
    {
        return
            keccak256(
                abi.encodePacked(
                    transaction.to,
                    transaction.value,
                    transaction.nonce,
                    transaction.data,
                    transaction.bond
                )
            );
    }

    function executeTrasaction(BridgeTransaction memory transaction)
        internal
        returns (bool success, bytes memory result)
    {
        (success, result) = transaction.to.call{
            value: transaction.value,
            gas: gasleft()
        }(bytes(transaction.data));
    }

    function recoverSender(BridgeTransaction memory transaction)
        internal
        pure
        returns (address sender)
    {
        sender = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(toTransactionHash(transaction)),
            transaction.signature
        );
    }
}
