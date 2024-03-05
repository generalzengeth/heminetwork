FROM golang:1.22

RUN apt-get update

RUN apt-get install -y nodejs npm jq

RUN npm install -g pnpm

WORKDIR /git

RUN curl -L https://foundry.paradigm.xyz | bash

RUN . /root/.bashrc

ENV PATH="${PATH}:/root/.foundry/bin"

RUN foundryup

RUN git clone https://github.com/hemilabs/op-geth
WORKDIR /git/op-geth
RUN git checkout origin/clayton/local-eth
RUN make
RUN go install ./...
RUN abigen --version

WORKDIR /git
RUN git clone https://github.com/hemilabs/optimism

WORKDIR /git/optimism
RUN git checkout origin/clayton/local-eth

RUN git submodule update --init --recursive
RUN pnpm install
RUN make op-bindings op-node op-batcher op-proposer
RUN pnpm build

WORKDIR /git/optimism/packages/contracts-bedrock

RUN forge install
RUN forge build

WORKDIR /git/optimism

RUN make devnet-allocs || :
