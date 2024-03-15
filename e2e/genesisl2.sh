#! /bin/sh
set -ex

JSON_RPC="http://op-geth-l1:8545"

# start geth in a local container
# wait for geth to become responsive
until curl --silent --fail $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"net_version\", \"params\": []}"; do sleep 12; done

sleep 12

# extract the variables we need from json output
MY_ADDRESS="0x78697c88847dfbbb40523e42c1f2e28a13a170be"
ONE_TIME_SIGNER_ADDRESS="0x$(cat output/deployment.json | jq --raw-output '.signerAddress')"
GAS_COST="0x$(printf '%x' $(($(cat output/deployment.json | jq --raw-output '.gasPrice') * $(cat output/deployment.json | jq --raw-output '.gasLimit'))))"
TRANSACTION="0x$(cat output/deployment.json | jq --raw-output '.transaction')"
DEPLOYER_ADDRESS="0x$(cat output/deployment.json | jq --raw-output '.address')"


sleep 12

# send gas money to signer
curl $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_sendTransaction\", \"params\": [{\"from\":\"$MY_ADDRESS\",\"to\":\"$ONE_TIME_SIGNER_ADDRESS\",\"value\":\"$GAS_COST\"}]}"

sleep 12

# deploy the deployer contract
curl $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_sendRawTransaction\", \"params\": [\"$TRANSACTION\"]}"

sleep 12

# deploy our contract
# contract: pragma solidity 0.5.8; contract Apple {function banana() external pure returns (uint8) {return 42;}}
BYTECODE="6080604052348015600f57600080fd5b5060848061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063c3cafc6f14602d575b600080fd5b6033604f565b604051808260ff1660ff16815260200191505060405180910390f35b6000602a90509056fea165627a7a72305820ab7651cb86b8c1487590004c2444f26ae30077a6b96c6bc62dda37f1328539250029"
MY_CONTRACT_ADDRESS=$(curl $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --silent --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_call\", \"params\": [{\"from\":\"$MY_ADDRESS\",\"to\":\"$DEPLOYER_ADDRESS\", \"data\":\"0x0000000000000000000000000000000000000000000000000000000000000000$BYTECODE\"}, \"latest\"]}" | jq --raw-output '.result')

sleep 12

curl $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_sendTransaction\", \"params\": [{\"from\":\"$MY_ADDRESS\",\"to\":\"$DEPLOYER_ADDRESS\", \"gas\":\"0xf4240\", \"data\":\"0x0000000000000000000000000000000000000000000000000000000000000000$BYTECODE\"}]}"

sleep 12

# call our contract (NOTE: MY_CONTRACT_ADDRESS is the same no matter what chain we deploy to!)
MY_CONTRACT_METHOD_SIGNATURE="c3cafc6f"
curl $JSON_RPC -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_call\", \"params\": [{\"to\":\"$MY_CONTRACT_ADDRESS\", \"data\":\"0x$MY_CONTRACT_METHOD_SIGNATURE\"}, \"latest\"]}"
# expected result is 0x000000000000000000000000000000000000000000000000000000000000002a (hex encoded 42)

cd /git/optimism/packages/contracts-bedrock

forge script ./scripts/Deploy.s.sol:Deploy --private-key=dfe61681b31b12b04f239bc0692965c61ffc79244ed9736ffa1a72d00a23a530 --broadcast --rpc-url http://op-geth-l1:8545 
forge script ./scripts/Deploy.s.sol:Deploy --sig 'sync()' --private-key=dfe61681b31b12b04f239bc0692965c61ffc79244ed9736ffa1a72d00a23a530 --broadcast --rpc-url http://op-geth-l1:8545

curl -H 'Content-Type: application/json' -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x2", true],"id":1}' http://op-geth-l1:8545 > /tmp/blockl1.json

echo $(jq '.result' /tmp/blockl1.json) > /tmp/blockl1.json

cat /tmp/blockl1.json

echo $(jq '.l2OutputOracleProposer = "0x78697c88847dfbbb40523e42c1f2e28a13a170be"' /git/optimism/packages/contracts-bedrock/deploy-config/devnetL1-template.json) > /git/optimism/packages/contracts-bedrock/deploy-config/devnetL1-template.json

/git/optimism/op-node/bin/op-node \
    genesis \
    l2 \
    --deploy-config  \
    /git/optimism/packages/contracts-bedrock/deploy-config/devnetL1-template.json \
    --deployment-dir  \
    /git/optimism/packages/contracts-bedrock/deployments/devnetL1 \
    --outfile.l2  \
    /l2configs/genesis.json \
    --outfile.rollup  \
    /l2configs/rollup.json \
    --l1-starting-block \
    /tmp/blockl1.json

echo $(jq '.l1_chain_id = 1337' /l2configs/rollup.json) > /l2configs/rollup.json
echo $(jq '.block_time = 1' /l2configs/rollup.json) > /l2configs/rollup.json
