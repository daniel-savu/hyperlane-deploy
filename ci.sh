# for CHAIN in anvil1 anvil2
# do
#     mkdir /tmp/$CHAIN \
#     /tmp/$CHAIN/state \
#     /tmp/$CHAIN/validator \
#     /tmp/$CHAIN/relayer && \
#     chmod 777 /tmp/$CHAIN -R
# done

# anvil --chain-id 31337 -p 8545 --state /tmp/anvil1/state > /dev/null &
# ANVIL_1_PID=$!

# anvil --chain-id 31338 -p 8555 --state /tmp/anvil2/state > /dev/null &
# ANVIL_2_PID=$!

# sleep 1

# echo "ANVIL 1 pid"
# echo $ANVIL_1_PID

# echo "ANVIL 2 pid"
# echo $ANVIL_2_PID

# set -e

# for i in "anvil1 anvil2 --no-write-agent-config" "anvil2 anvil1 --write-agent-config"
# do
#     set -- $i
#     echo "Deploying contracts to $1"
#     yarn ts-node scripts/deploy-hyperlane.ts --local $1 --remotes $2 \
#     --key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $3
# done

# echo "Deploying warp routes"
# yarn ts-node scripts/deploy-warp-routes.ts \
#   --key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# kill $ANVIL_1_PID
# kill $ANVIL_2_PID

# anvil --chain-id 31337 -p 8545 --block-time 1 --state /tmp/anvil1/state > ./anvil1.logs &
# ANVIL_1_PID=$!

# anvil --chain-id 31338 -p 8555 --block-time 1 --state /tmp/anvil2/state > ./anvil2.logs &
# ANVIL_2_PID=$!

for i in "anvil1 8545 ANVIL1" "anvil2 8555 ANVIL2"
do
    set -- $i
    echo "Running validator on $1"

    export CONFIG_FILES="./artifacts/agent_config.json"
    export HYP_VALIDATOR_ORIGINCHAINNAME=$1
    export HYP_VALIDATOR_REORGPERIOD=0 HYP_VALIDATOR_INTERVAL=1
    export "HYP_BASE_CHAINS_${3}_CONNECTION_URL"="http://127.0.0.1:${2}"
    export HYP_VALIDATOR_VALIDATOR_TYPE=hexKey
    export HYP_VALIDATOR_VALIDATOR_KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
    export HYP_VALIDATOR_CHECKPOINTSYNCER_TYPE=localStorage
    export HYP_VALIDATOR_CHECKPOINTSYNCER_PATH="./${1}-sigs"
    export HYP_BASE_TRACING_LEVEL=info HYP_BASE_TRACING_FMT=pretty
    ../hyperlane-monorepo/rust/target/release/validator > /dev/null &

done

sleep 10

# for i in "anvil1 8545" "anvil2 8555"
# do
#     set -- $i
#     echo "Announcing validator on $1"
#     VALIDATOR_ANNOUNCE_ADDRESS=$(cat ./artifacts/addresses.json | jq -r ".$1.validatorAnnounce")
#     VALIDATOR=$(cat /tmp/$1/validator/announcement.json | jq -r '.value.validator')
#     STORAGE_LOCATION=$(cat /tmp/$1/validator/announcement.json | jq -r '.value.storage_location')
#     SIGNATURE=$(cat /tmp/$1/validator/announcement.json | jq -r '.serialized_signature')
#     cast send $VALIDATOR_ANNOUNCE_ADDRESS  \
#       "announce(address, string calldata, bytes calldata)(bool)" \
#       $VALIDATOR $STORAGE_LOCATION $SIGNATURE --rpc-url http://127.0.0.1:$2 \
#       --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
# done

for i in "anvil1 anvil2 ANVIL2" "anvil2 anvil1 ANVIL1"
do
    set -- $i
    echo "Running relayer on $1"
    export CONFIG_FILES=./artifacts/agent_config.json
    export HYP_BASE_CHAINS_ANVIL1_CONNECTION_URL=http://127.0.0.1:8545
    export HYP_BASE_CHAINS_ANVIL2_CONNECTION_URL=http://127.0.0.1:8555
    export HYP_BASE_TRACING_LEVEL=info export HYP_BASE_TRACING_FMT=pretty
    export HYP_RELAYER_ORIGINCHAINNAME="$1" export HYP_RELAYER_DESTINATIONCHAINNAMES="$2"
    export HYP_RELAYER_ALLOWLOCALCHECKPOINTSYNCERS=true export HYP_RELAYER_DB="./${1}-relayer"
    export HYP_RELAYER_GASPAYMENTENFORCEMENT='[{"type":"none"}]'
    export "HYP_BASE_CHAINS_${3}_SIGNER_TYPE"=hexKey
    export "HYP_BASE_CHAINS_${3}_SIGNER_KEY"=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
    ../hyperlane-monorepo/rust/target/release/relayer
done

# echo "Testing message sending"
# yarn ts-node scripts/test-messages.ts --chains anvil1 anvil2 \
#   --key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --timeout 60

# echo "Sending a test warp transfer"
# yarn ts-node scripts/test-warp-transfer.ts \
#   --origin anvil1 --destination anvil2 --wei 1 --recipient 0xac0974bec39a17e36ba4a6b4d238ff944bacb4a5 \
#   --key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --timeout 60

docker ps -aq | xargs docker stop | xargs docker rm
# kill $ANVIL_1_PID
# kill $ANVIL_2_PID
