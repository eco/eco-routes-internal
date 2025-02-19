#!/bin/bash

# Load environment variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Convert space-separated values into arrays
IFS=' ' read -r -a RPCS <<< "$RPC_URLS"
IFS=' ' read -r -a CHAINS <<< "$CHAIN_IDS"
IFS=' ' read -r -a ETHERSCAN_KEYS <<< "$ETHERSCAN_API_KEYS"

# Read deployed contracts from .deploy file and verify per chain
while IFS=',' read -r chain address contractPath encodedArgs; do
    for index in "${!CHAINS[@]}"; do
        if [[ "${CHAINS[$index]}" == "$chain" ]]; then
            ETHERSCAN_API_KEY="${ETHERSCAN_KEYS[$index]}"
            echo "Verifying contract at $address on chain $chain using $contractPath..."

            if [[ -z "$encodedArgs" || "$encodedArgs" == "0x" ]]; then
                forge verify-contract --chain "$chain" --watch \
                    "$address" \
                    "$contractPath" \
                    --etherscan-api-key "$ETHERSCAN_API_KEY"
            else
                forge verify-contract --chain "$chain" --watch \
                    "$address" \
                    "$contractPath" \
                    --constructor-args "$encodedArgs" \
                    --etherscan-api-key "$ETHERSCAN_API_KEY"
            fi
        fi
    done
done < .deploy