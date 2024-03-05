#! /bin/sh

set -ex

sleep 60

bitcoin-cli \
 -regtest=1 \
 -rpcuser=user \
 -rpcpassword=password \
 -rpcport=18443 \
 -rpcconnect=bitcoind \
 -generatetoaddress 1 mw47rj9rG25J67G6W8bbjRayRQjWN5ZSEG