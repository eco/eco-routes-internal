#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Ensure DEPLOY_FILE is set
if [ -z "$DEPLOY_FILE" ]; then
    echo "❌ Error: DEPLOY_FILE is not set in .env!"
    exit 1
fi

# Ensure deploy file exists
if [ ! -f "$DEPLOY_FILE" ]; then
    echo "❌ Error: $DEPLOY_FILE not found!"
    exit 1
fi

# Read deployment data and verify contracts
while IFS=, read -r CHAIN_ID CONTRACT_ADDRESS CONTRACT_PATH CONSTRUCTOR_ARGS; do
    CHAIN_ID=$(echo "$CHAIN_ID" | tr -d '[:space:]')
    CONTRACT_ADDRESS=$(echo "$CONTRACT_ADDRESS" | tr -d '[:space:]')
    CONTRACT_PATH=$(echo "$CONTRACT_PATH" | xargs)
    CONSTRUCTOR_ARGS=$(echo "$CONSTRUCTOR_ARGS" | xargs)

    echo "🔍 Verifying contract $CONTRACT_ADDRESS on Chain ID $CHAIN_ID"

    eval "ETHERSCAN_API_KEY=\$ETHERSCAN_API_KEY_$CHAIN_ID"

    if [ -z "$ETHERSCAN_API_KEY" ]; then
        echo "⚠️  Warning: No API key found for Chain ID $CHAIN_ID, skipping verification."
        continue
    fi

    VERIFY_CMD="forge verify-contract \
        --chain-id $CHAIN_ID \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --constructor-args $CONSTRUCTOR_ARGS \
        $CONTRACT_ADDRESS $CONTRACT_PATH"

    eval $VERIFY_CMD

    if [ $? -eq 0 ]; then
        echo "✅ Successfully verified $CONTRACT_ADDRESS ($CONTRACT_PATH) on Chain ID $CHAIN_ID"
    else
        echo "❌ Verification failed for $CONTRACT_ADDRESS on Chain ID $CHAIN_ID"
    fi

    # New lines
    echo ""
    echo ""
done < "$DEPLOY_FILE"