#!/bin/sh

mkdir /src/bitcoin/src/regtest
echo "regtest=1" > /src/bitcoin/src/regtest/bitcoin.conf

./bitcoind -datadir=./regtest -daemon
printf "Waiting for regtest bitcoind to start"
sleep 1

./bitcoin-cli -datadir=/src/bitcoin/src/regtest createwallet signer || ./bitcoin-cli -datadir=/src/bitcoin/src/regtest loadwallet signer 

DESCS=$(./bitcoin-cli -datadir=/src/bitcoin/src/regtest listdescriptors true | jq -M .descriptors | tr -d " \t\n\r")
ADDR=$(./bitcoin-cli -datadir=/src/bitcoin/src/regtest getnewaddress bech32)
SIGNET_CHALLENGE=$(./bitcoin-cli -datadir=/src/bitcoin/src/regtest getaddressinfo $ADDR | jq -r .scriptPubKey)
echo "SIGNET CHALLENGE"
echo $SIGNET_CHALLENGE

./bitcoin-cli -datadir=/src/bitcoin/src/regtest stop

mkdir /src/bitcoin/src/signet

echo "signet=1
rpcuser=alice
rpcpassword=alice

[signet]
daemon=1

server=1
txindex=1
rest=1

fallbackfee=0.00001

signetchallenge=$SIGNET_CHALLENGE" > /src/bitcoin/src/signet/bitcoin.conf

./bitcoind -datadir=/src/bitcoin/src/signet -daemon -rpcuser=alice -rpcpassword=alice -rpcallowip=0.0.0.0/0 -rpcbind=0.0.0.0:38332
printf "Waiting for signet bitcoind to start"
sleep 3

./bitcoin-cli -datadir=/src/bitcoin/src/signet createwallet miner || ./bitcoin-cli -datadir=/src/bitcoin/src/signet loadwallet miner
./bitcoin-cli -datadir=/src/bitcoin/src/signet importdescriptors $DESCS

ADDR=$(./bitcoin-cli -datadir=/src/bitcoin/src/signet getnewaddress bech32)
echo "ADDR"
echo $ADDR
# ./bitcoin-cli -datadir=./signet listdescriptors true
# DESC=$(./bitcoin-cli -datadir=./signet listdescriptors true | jq -r .descriptors[0].desc)
# echo $DESC

res=$(../contrib/signet/miner --cli="./bitcoin-cli -datadir=/src/bitcoin/src/signet" calibrate --grind-cmd="./bitcoin-util grind" --seconds=600)
export NBITS=$(echo $res | grep -oP 'nbits=\K[^ ]+')
../contrib/signet/miner --cli="./bitcoin-cli -datadir=/src/bitcoin/src/signet" generate --address $ADDR --grind-cmd="./bitcoin-util grind" --nbits=$NBITS
../contrib/signet/miner --cli="./bitcoin-cli -datadir=/src/bitcoin/src/signet" generate --max-interval=960 --address $ADDR --grind-cmd="./bitcoin-util grind" --nbits=$NBITS --ongoing
