import mumbai from "../../deployments/mumbai.json";
import goerli from "../../deployments/goerli.json";
import { config } from "dotenv";

export const RPC_ENDPOINTS = {
  GOERLI: process.env.GOERLI_RPC || "http://localhost:8545",
  MUMBAI: process.env.MUMBAI_RPC || "http://localhost:8546",
};

export const ADDRESSES = {
  GOERLI: {
    COUNTER: goerli.counter,
    BRIDGE: goerli.bridge,
  },
  MUMBAI: {
    COUNTER: mumbai.counter,
    BRIDGE: mumbai.bridge,
  },
};

export const bridge_abi = [
  "event RequestForward(address from,address to,uint256 value,uint256 nonce,bytes data,uint256 bond,bytes signature)",
  "event RequestSucceeded(address from,address to,uint256 value,uint256 nonce,bytes data,uint256 bond,bytes signature)",
  "function execute(address from,address to,uint256 value,uint256 nonce,bytes memory data,uint256 bond,bytes memory signature)",
];
