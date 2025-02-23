#!/bin/bash

# Prompt user for network choice
echo "Do you want to deploy to testnets or mainnet?"
echo "1) Testnets (Optimism Sepolia and Base Sepolia)"
echo "2) Mainnets (Optimism and Base)"
read -p "Enter choice (1 or 2): " NETWORK_CHOICE

case $NETWORK_CHOICE in
    1)
        # Configure for testnets
        export HARDHAT_NETWORK_OPTIMISM="optimismSepolia"
        export HARDHAT_NETWORK_BASE="baseSepolia"
        echo "Deploying to testnets (Optimism Sepolia and Base Sepolia)..."
        ;;
    2)
        # Configure for mainnet
        export HARDHAT_NETWORK_OPTIMISM="optimism"
        export HARDHAT_NETWORK_BASE="base"
        echo "Deploying to mainnets (Optimism and Base)..."
        ;;
    *)
        echo "Invalid choice. Please enter 1 or 2"
        exit 1
        ;;
esac


echo "deploying intent source on $HARDHAT_NETWORK_OPTIMISM..."
optimism_intent_source_output=$(npx hardhat run scripts/polymer/deployIntentSource.ts --network $HARDHAT_NETWORK_OPTIMISM | tee /dev/stderr)
optimism_intent_source=$(echo "$optimism_intent_source_output" | grep "intent source deployed at:" | awk '{print $5}')
echo "successfully deployed intent source on $HARDHAT_NETWORK_OPTIMISM"

echo "deploying intent source on $HARDHAT_NETWORK_BASE..."
base_intent_source_output=$(npx hardhat run scripts/polymer/deployIntentSource.ts --network $HARDHAT_NETWORK_BASE | tee /dev/stderr)
base_intent_source=$(echo "$base_intent_source_output" | grep "intent source deployed at:" | awk '{print $5}')
echo "successfully deployed intent source on $HARDHAT_NETWORK_BASE"

echo "waiting 10 seconds for nonces to settle..."
sleep 10

echo "deploying inbox on $HARDHAT_NETWORK_OPTIMISM..."
optimism_output=$(npx hardhat run scripts/polymer/deployInbox.ts --network $HARDHAT_NETWORK_OPTIMISM | tee /dev/stderr)
optimism_inbox=$(echo "$optimism_output" | grep "inbox deployed at:" | awk '{print $4}')
echo "successfully deployed $HARDHAT_NETWORK_OPTIMISM inbox"

echo "deploying inbox on $HARDHAT_NETWORK_BASE..."
base_output=$(npx hardhat run scripts/polymer/deployInbox.ts --network $HARDHAT_NETWORK_BASE | tee /dev/stderr)
base_inbox=$(echo "$base_output" | grep "inbox deployed at:" | awk '{print $4}')
echo "successfully deployed $HARDHAT_NETWORK_BASE inbox"

echo "waiting 10 seconds for nonces to settle..."
sleep 10

echo "deploying polymer prover on $HARDHAT_NETWORK_OPTIMISM (using $HARDHAT_NETWORK_BASE inbox)..."
export INBOX_ADDRESS="$base_inbox"
optimism_prover_output=$( npx hardhat run scripts/polymer/deployPolymerProver.ts --network $HARDHAT_NETWORK_OPTIMISM | tee /dev/stderr)
optimism_prover=$(echo "$optimism_prover_output" | grep "polymer prover deployed at:" | awk '{print $5}')
echo "successfully deployed $HARDHAT_NETWORK_OPTIMISM prover"

echo "deploying polymer prover on $HARDHAT_NETWORK_BASE (using $HARDHAT_NETWORK_OPTIMISM inbox)..."
export INBOX_ADDRESS="$optimism_inbox"
base_prover_output=$(npx hardhat run scripts/polymer/deployPolymerProver.ts --network $HARDHAT_NETWORK_BASE | tee /dev/stderr)
base_prover=$(echo "$base_prover_output" | grep "polymer prover deployed at:" | awk '{print $5}')
echo "successfully deployed $HARDHAT_NETWORK_BASE prover"

echo "deployed addresses:"
echo "$HARDHAT_NETWORK_OPTIMISM intent source: $optimism_intent_source"
echo "$HARDHAT_NETWORK_BASE intent source: $base_intent_source"
echo "$HARDHAT_NETWORK_OPTIMISM inbox: $optimism_inbox"
echo "$HARDHAT_NETWORK_BASE inbox: $base_inbox"
echo "$HARDHAT_NETWORK_OPTIMISM prover: $optimism_prover"
echo "$HARDHAT_NETWORK_BASE prover: $base_prover"

unset INBOX_ADDRESS
unset HARDHAT_NETWORK_OPTIMISM
unset HARDHAT_NETWORK_BASE


