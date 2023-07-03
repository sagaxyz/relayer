#!/bin/bash

KEYPASSWD=${KEYPASSWD:-DoNoTuSeInPrOd}

rly config init

echo $RELAYER_CHAINLET_MNEMONIC > mnemo.file.sevm
echo $RELAYER_SPC_MNEMONIC > mnemo.file.spc

mv /root/tmp/sevm_111-1.json.example /root/tmp/$CHAINLET_CHAIN_ID.json
mv /root/tmp/sevm_111-2.json.example /root/tmp/$SPC_CHAIN_ID.json

cat /root/tmp/$CHAINLET_CHAIN_ID.json | jq '.value."chain-id"="'$CHAINLET_CHAIN_ID'"' > /root/tmp/$CHAINLET_CHAIN_ID.json.tmp && mv /root/tmp/$CHAINLET_CHAIN_ID.json.tmp /root/tmp/$CHAINLET_CHAIN_ID.json
cat /root/tmp/$SPC_CHAIN_ID.json | jq '.value."chain-id"="'$SPC_CHAIN_ID'"' > /root/tmp/$SPC_CHAIN_ID.json.tmp && mv /root/tmp/$SPC_CHAIN_ID.json.tmp /root/tmp/$SPC_CHAIN_ID.json

# TODO: hardcoded port; http
cat /root/tmp/$CHAINLET_CHAIN_ID.json | jq '.value."rpc-addr"="'$CHAINLET_RPC_ADDRESS'"' > /root/tmp/$CHAINLET_CHAIN_ID.json.tmp && mv /root/tmp/$CHAINLET_CHAIN_ID.json.tmp /root/tmp/$CHAINLET_CHAIN_ID.json
cat /root/tmp/$SPC_CHAIN_ID.json | jq '.value."rpc-addr"="'$SPC_EXTERNAL_ADDRESS'"' > /root/tmp/$SPC_CHAIN_ID.json.tmp && mv /root/tmp/$SPC_CHAIN_ID.json.tmp /root/tmp/$SPC_CHAIN_ID.json

cat /root/tmp/$CHAINLET_CHAIN_ID.json | jq '.value."keyring-backend"="file"' > /root/tmp/$CHAINLET_CHAIN_ID.json.tmp && mv /root/tmp/$CHAINLET_CHAIN_ID.json.tmp /root/tmp/$CHAINLET_CHAIN_ID.json
cat /root/tmp/$SPC_CHAIN_ID.json | jq '.value."keyring-backend"="file"' > /root/tmp/$SPC_CHAIN_ID.json.tmp && mv /root/tmp/$SPC_CHAIN_ID.json.tmp /root/tmp/$SPC_CHAIN_ID.json

cat /root/tmp/$CHAINLET_CHAIN_ID.json | jq '.value."gas-prices"="'1$CHAINLET_DENOM'"' > /root/tmp/$CHAINLET_CHAIN_ID.json.tmp && mv /root/tmp/$CHAINLET_CHAIN_ID.json.tmp /root/tmp/$CHAINLET_CHAIN_ID.json
cat /root/tmp/$SPC_CHAIN_ID.json | jq '.value."gas-prices"="'1$SPC_DENOM'"' > /root/tmp/$SPC_CHAIN_ID.json.tmp && mv /root/tmp/$SPC_CHAIN_ID.json.tmp /root/tmp/$SPC_CHAIN_ID.json

cp /root/tmp/$CHAINLET_CHAIN_ID.json /root/.relayer/config/
cp /root/tmp/$SPC_CHAIN_ID.json /root/.relayer/config/

rly chains add $CHAINLET_CHAIN_ID --file /root/.relayer/config/$CHAINLET_CHAIN_ID.json
rly chains add $SPC_CHAIN_ID --file /root/.relayer/config/$SPC_CHAIN_ID.json

yq -i '.chains."'$CHAINLET_CHAIN_ID'".value.extra-codecs |= ["ethermint"]' /root/.relayer/config/config.yaml

(echo $KEYPASSWD; echo $KEYPASSWD) | rly keys restore $CHAINLET_CHAIN_ID key1 "$(cat /root/mnemo.file.sevm)" --coin-type=60
(echo $KEYPASSWD; echo $KEYPASSWD) | rly keys restore $SPC_CHAIN_ID key2 "$(cat /root/mnemo.file.spc)"

rly paths new $CHAINLET_CHAIN_ID $SPC_CHAIN_ID dp

# we want to make sure that chainlet is up and running
while true
do
    rly q node-state $CHAINLET_CHAIN_ID
    RETCODE=$?
    if [[ ${RETCODE} -eq 0 ]]; then
        break
    fi
    sleep 5
done

(echo $KEYPASSWD; sleep 1; echo $KEYPASSWD) | rly transact link dp

(echo $KEYPASSWD; sleep 1; echo $KEYPASSWD) | rly start dp
