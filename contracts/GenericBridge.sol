// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.15;

//import "@openzeppelin/contracts/access/Ownable.sol";
import {Owned} from "./Owned.sol";
import {BridgeLib} from "./BridgeLib.sol";

contract GenericBridge is Owned {
    using BridgeLib for *;

    mapping(address => uint256) public nonces;

    uint256 public totalBonded;

    constructor() Owned(msg.sender) {}

    event RequestForward(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 nonce,
        bytes data,
        uint256 bond,
        bytes signature
    );

    event RequestSucceeded(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 nonce,
        bytes data,
        uint256 bond,
        bytes signature
    );

    event RelayerPayment(uint256 value);

    function send(
        address user,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signature
    ) public payable {
        require(msg.value >= value, "NOT ENOUGH ETH");

        uint256 bond = msg.value - value;

        BridgeLib.BridgeTransaction memory transaction = BridgeLib
            .BridgeTransaction({
                to: to,
                value: value,
                data: data,
                nonce: nonces[msg.sender]++,
                bond: bond,
                signature: signature
            });

        require(transaction.recoverSender() == user, "INVALID_SIGNATURE");

        totalBonded += bond;

        emitForward(transaction, user);
    }

    function harvest() public onlyOwner {
        address payable sender = payable(msg.sender);
        sender.transfer(totalBonded);
        totalBonded = 0;
        emit RelayerPayment(totalBonded);
    }

    function withdrawValue(uint256 value) public onlyOwner {
        address payable sender = payable(msg.sender);
        require(
            value <= address(this).balance + totalBonded,
            "Must reserve ETH for bonded transactions"
        );
        totalBonded -= value;
        sender.transfer(value);
        emit RelayerPayment(value);
    }

    function execute(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        bytes memory data,
        uint256 bond,
        bytes memory signature
    ) public onlyOwner {
        BridgeLib.BridgeTransaction memory transaction = BridgeLib
            .BridgeTransaction({
                to: to,
                value: value,
                data: data,
                nonce: nonce,
                bond: bond,
                signature: signature
            });

        require(transaction.recoverSender() == from, "INVALID_SIGNATURE");

        (bool success, ) = BridgeLib.executeTrasaction(transaction);

        require(success, "TRANSACTION_FAILED");

        emitSuccess(transaction, from);
    }

    function getMessageHash(
        address _to,
        uint256 _value,
        uint256 _nonce,
        bytes memory _data,
        uint256 _bond
    ) public pure returns (bytes32) {
        BridgeLib.BridgeTransaction memory transaction = BridgeLib
            .BridgeTransaction({
                to: _to,
                value: _value,
                data: _data,
                nonce: _nonce,
                bond: _bond,
                signature: new bytes(0)
            });
        return BridgeLib.toTransactionHash(transaction);
    }

    function emitSuccess(
        BridgeLib.BridgeTransaction memory transaction,
        address sender
    ) internal {
        emit RequestSucceeded(
            sender,
            transaction.to,
            transaction.value,
            transaction.nonce,
            transaction.data,
            transaction.bond,
            transaction.signature
        );
    }

    function emitForward(
        BridgeLib.BridgeTransaction memory transaction,
        address sender
    ) internal {
        emit RequestForward(
            sender,
            transaction.to,
            transaction.value,
            transaction.nonce,
            transaction.data,
            transaction.bond,
            transaction.signature
        );
    }
}
