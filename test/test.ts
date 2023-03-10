import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, tracer } from "hardhat";

const {
    utils: {hexZeroPad, hexlify, hashMessage, zeroPad, getAddress, arrayify}, BigNumber,
} = ethers;

const events_abi = [
    "event RequestForward(address from, address to, uint256 value, bytes data, bytes signature)",
    "event RequestSucceeded(address from, address to, uint256 value, bytes data, bytes signature)",
    "event CounterLatest(uint256 counter);",
];

describe("Bridge-Counter", function () {
    async function deployBridgeAndCounter() {
        const [owner, otherAccount, randomRecipient] = await ethers.getSigners();

        tracer.nameTags[getAddress(owner.address)] = "owner";
        tracer.nameTags[getAddress(otherAccount.address)] = "otherAccount";
        tracer.nameTags[getAddress(randomRecipient.address)] = "randomRecipient";

        const GenericBridge = await ethers.getContractFactory("GenericBridge");
        const genericBridge = await GenericBridge.deploy();
        await genericBridge.deployed();

        const Counter = await ethers.getContractFactory("Counter");
        const counter = await Counter.deploy(genericBridge.address);
        await counter.deployed();

        return {genericBridge, counter, owner, otherAccount, randomRecipient};
    }

    describe("Crosschain execution", function () {
        it("deploy bridge and counter", async function () {
            const {genericBridge, counter, owner, otherAccount} = await loadFixture(
                deployBridgeAndCounter
            );
            console.log("genericBridge", genericBridge.address);
            console.log("counter", counter.address);
            console.log("owner", owner.address);
            console.log("otherAccount", otherAccount.address);
        });

        it("should emit event when Counter.send() is called [broadcating->relayer]",async () => {
            const {genericBridge, counter, owner, otherAccount, randomRecipient} = await loadFixture(
                deployBridgeAndCounter
            );

            const selector = counter.interface.getSighash("increment");

            const hash = await genericBridge.getMessageHash(
                getAddress(randomRecipient.address),
                0,
                0,  // nonce
                selector,
                0
            );

            const signature = await otherAccount.signMessage(arrayify(hash));

        // call .send() on Counter from otherAccount as signer
        // and expect an event to be emitted
        await expect(
            counter
            .connect(otherAccount)
            .send(
                getAddress(randomRecipient.address),
                BigNumber.from(0),
                selector,
                signature,
                {
                // set bond here
                value: 0,
                }
            )
        )
            .to.emit(genericBridge, "RequestForward")
            .withArgs(
            otherAccount.address,
            randomRecipient.address,
            0,
            0,
            selector,
            0,
            signature
            );
        });

        it("should properly run executeMessage() [relayer -> target chain interaction]", async () => {
            const {
              genericBridge,
              counter,
              owner,
              otherAccount: accountSendingMessage,
              randomRecipient,
            } = await loadFixture(deployBridgeAndCounter);
      
            // get increment() function selector
            const selector = counter.interface.getSighash("increment()");
      
            // get hash and sign it (as )
            const hash = await genericBridge.getMessageHash(
              getAddress(randomRecipient.address),
              0,
              0,
              selector,
              0
            );
            const signature = await accountSendingMessage.signMessage(arrayify(hash));
      
            await expect(
              genericBridge
                .connect(owner)
                .execute(
                  accountSendingMessage.address,
                  randomRecipient.address,
                  0,
                  0,
                  selector,
                  0,
                  signature
                )
            )
              .to.emit(genericBridge, "RequestSucceeded")
              .withArgs(
                accountSendingMessage.address,
                randomRecipient.address,
                0,
                0,
                selector,
                0,
                signature
              );
          });

    });
});