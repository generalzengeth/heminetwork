#! /bin/sh
set -ex

while :
do
    sleep 5

    geth \
    attach \
    --exec \
    "eth.sendTransaction({from: \"0x78697c88847dfbbb40523e42c1f2e28a13a170be\", to: \"0x06f0f8ee8119b2a0b7a95ba267231be783d8d2ab\", value: 1})" \
    /tmp/geth/geth.ipc
done