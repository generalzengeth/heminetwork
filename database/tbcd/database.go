// Copyright (c) 2024 Hemi Labs, Inc.
// Use of this source code is governed by the MIT License,
// which can be found in the LICENSE file.

package tbcd

import (
	"context"

	"github.com/hemilabs/heminetwork/database"
)

type Database interface {
	database.Database

	// Version table
	Version(ctx context.Context) (int, error)

	// Block header
	BlockHeaderByHash(ctx context.Context, hash []byte) (*BlockHeader, error)
	BlockHeadersBest(ctx context.Context) ([]BlockHeader, error)
	BlockHeadersInsert(ctx context.Context, bhs []BlockHeader) error
	BlockHeadersByHeight(ctx context.Context, height uint64) ([]BlockHeader, error)

	// Block
	BlocksMissing(ctx context.Context, count int) ([]BlockIdentifier, error)
	BlockInsert(ctx context.Context, b *Block) (int64, error)
	// BlocksInsert(ctx context.Context, bs []*Block) (int64, error)

	// Peer manager
	PeersInsert(ctx context.Context, peers []Peer) error     // insert or update
	PeerDelete(ctx context.Context, host, port string) error // remove peer
	PeersRandom(ctx context.Context, count int) ([]Peer, error)
}

type BlockHeader struct {
	Hash      database.ByteArray
	Height    uint64
	Header    database.ByteArray
	CreatedAt database.Timestamp `deep:"-"`
}

type Block struct {
	Hash      database.ByteArray
	Block     database.ByteArray
	CreatedAt database.Timestamp `deep:"-"`
}

// BlockIdentifier uniquely identifies a block using it's hash and height.
type BlockIdentifier struct {
	Height uint64
	Hash   database.ByteArray
}

type Peer struct {
	Host      string
	Port      string
	LastAt    database.Timestamp `deep:"-"` // Last time connected
	CreatedAt database.Timestamp `deep:"-"`
}
