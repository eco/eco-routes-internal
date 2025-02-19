#!/bin/bash

# Load environment variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Convert space-separated CHAIN_IDS into an array
IFS=' ' read -r -a CHAINS <<< "$CHAIN_IDS"

# Loop through each chain and deploy contracts with the correct config
for CHAIN_ID in "${CHAINS[@]}"; do
    # Dynamically fetch the correct values for the chain
    RPC_URL_VAR="RPC_URL_$CHAIN_ID"
    MAILBOX_VAR="MAILBOX_$CHAIN_ID"
    ETHERSCAN_KEY_VAR="ETHERSCAN_API_KEY_$CHAIN_ID"

    RPC_URL="${!RPC_URL_VAR}"
    MAILBOX_CONTRACT="${!MAILBOX_VAR}"
    ETHERSCAN_API_KEY="${!ETHERSCAN_KEY_VAR}"

    if [[ -z "$RPC_URL" || -z "$MAILBOX_CONTRACT" || -z "$ETHERSCAN_API_KEY" ]]; then
        echo "❌ Missing environment variables for chain ID $CHAIN_ID. Skipping..."
        continue
    fi

    echo "🚀 Deploying contracts on Chain ID: $CHAIN_ID"
    echo "🔗 RPC URL: $RPC_URL"
    echo "📬 Mailbox Contract: $MAILBOX_CONTRACT"
    echo "🔑 Etherscan API Key: $ETHERSCAN_API_KEY"

    # Run Forge script with the correct values
    RPC_URL="$RPC_URL" \
    MAILBOX="$MAILBOX_CONTRACT" \
    SALT="$SALT" \
    forge script scripts/Deploy.s.sol \
        --rpc-url "$RPC_URL" \
        --broadcast \
        --private-key "$PRIVATE_KEY"

    echo "✅ Deployment on Chain ID: $CHAIN_ID completed!"
done