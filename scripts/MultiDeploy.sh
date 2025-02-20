#!/bin/bash

# Load environment variables from .env safely
if [ -f .env ]; then
    set -a  # Export all variables automatically
    source .env
    set +a
fi

# Ensure CHAIN_IDS is properly set
if [ -z "$CHAIN_IDS" ]; then
    echo "❌ Error: CHAIN_IDS variable is empty! Set it in the .env file."
    exit 1
fi

# Convert space-separated CHAIN_IDS into an array
IFS=' ' read -r -a CHAINS <<< "$CHAIN_IDS"

# Loop through each chain and deploy contracts with the correct config
for CHAIN_ID in "${CHAINS[@]}"; do
    # Dynamically fetch the correct values for the chain
    RPC_URL_VAR="RPC_URL_$CHAIN_ID"
    MAILBOX_VAR="MAILBOX_$CHAIN_ID"

    RPC_URL="${!RPC_URL_VAR}"
    MAILBOX_CONTRACT="${!MAILBOX_VAR}"

    # Debug: Print fetched values
    echo "🔄 Deploying contracts for Chain ID: $CHAIN_ID"
    echo "📬 Mailbox Contract: $MAILBOX_CONTRACT"

    # Check if all required variables are set
    if [[ -z "$RPC_URL" || -z "$MAILBOX_CONTRACT" ]]; then
        echo "⚠️  Warning: Missing variables for Chain ID $CHAIN_ID. Skipping..."
        continue
    fi

    # Run Foundry script for the chain
    MAILBOX="$MAILBOX_CONTRACT" SALT="$SALT" forge script scripts/Deploy.s.sol \
        --rpc-url "$RPC_URL" \
        --broadcast \
        --private-key "$PRIVATE_KEY"

    echo "✅ Deployment on Chain ID: $CHAIN_ID completed!"
    # New line
    echo ""
done