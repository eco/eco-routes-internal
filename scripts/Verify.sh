#!/bin/bash

# Load environment variables from .env safely
if [ -f .env ]; then
    set -a  # Export all variables automatically
    source .env
    set +a
fi

# Ensure `.deploy` file exists
DEPLOY_FILE="out/.deploy"
if [ ! -f "$DEPLOY_FILE" ]; then
    echo "❌ Error: $DEPLOY_FILE not found!"
    exit 1
fi

# Read the CSV file line by line
while IFS=, read -r CHAIN_ID CONTRACT_ADDRESS CONTRACT_PATH CONSTRUCTOR_ARGS; do
    # Trim whitespace
    CHAIN_ID=$(echo "$CHAIN_ID" | xargs)
    CONTRACT_ADDRESS=$(echo "$CONTRACT_ADDRESS" | xargs)
    CONTRACT_PATH=$(echo "$CONTRACT_PATH" | xargs)
    CONSTRUCTOR_ARGS=$(echo "$CONSTRUCTOR_ARGS" | xargs)

    # Debug: Print the values being read
    echo "📝 Processing: Chain ID = [$CHAIN_ID], Address = [$CONTRACT_ADDRESS], Path = [$CONTRACT_PATH], Args = [$CONSTRUCTOR_ARGS]"

    # Skip empty lines or invalid data
    if [[ -z "$CHAIN_ID" || -z "$CONTRACT_ADDRESS" || -z "$CONTRACT_PATH" ]]; then
        echo "⚠️  Warning: Skipping invalid line in .deploy"
        continue
    fi

    # Use an alternative approach to fetch API key dynamically
    eval "ETHERSCAN_API_KEY=\$ETHERSCAN_API_KEY_$CHAIN_ID"

    if [ -z "$ETHERSCAN_API_KEY" ]; then
        echo "⚠️  Warning: No API key found for Chain ID $CHAIN_ID, skipping verification."
        continue
    fi

    echo "🔍 Verifying contract $CONTRACT_ADDRESS on Chain ID $CHAIN_ID..."

    # Construct the verification command
    VERIFY_CMD="forge verify-contract \
        --chain-id $CHAIN_ID \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --constructor-args $CONSTRUCTOR_ARGS \
        $CONTRACT_ADDRESS $CONTRACT_PATH"

    # Run verification
    eval $VERIFY_CMD

    if [ $? -eq 0 ]; then
        echo "✅ Successfully verified $CONTRACT_ADDRESS ($CONTRACT_PATH) on Chain ID $CHAIN_ID"
    else
        echo "❌ Verification failed for $CONTRACT_ADDRESS on Chain ID $CHAIN_ID"
    fi

    echo ""
    echo ""
done < "$DEPLOY_FILE"