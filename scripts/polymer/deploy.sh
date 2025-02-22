echo "deploying inbox on optimism..."
optimism_output=$(npx hardhat run scripts/polymer/deployInbox.ts --network optimism | tee /dev/stderr)
optimism_inbox=$(echo "$optimism_output" | grep "inbox deployed at:" | awk '{print $4}')
echo "successfully deployed optimism inbox"

echo "deploying inbox on base..."
base_output=$(npx hardhat run scripts/polymer/deployInbox.ts --network base | tee /dev/stderr)
base_inbox=$(echo "$base_output" | grep "inbox deployed at:" | awk '{print $4}')
echo "successfully deployed base inbox"

echo "deploying polymer prover on optimism (using base inbox)..."
export INBOX_ADDRESS="$base_inbox"
optimism_prover_output=$( npx hardhat run scripts/polymer/deployPolymerProver.ts --network optimism | tee /dev/stderr)
optimism_prover=$(echo "$optimism_prover_output" | grep "polymer prover deployed at:" | awk '{print $5}')
echo "successfully deployed optimism prover"

echo "deploying polymer prover on base (using optimism inbox)..."
export INBOX_ADDRESS="$optimism_inbox"
base_prover_output=$(npx hardhat run scripts/polymer/deployPolymerProver.ts --network base | tee /dev/stderr)
base_prover=$(echo "$base_prover_output" | grep "polymer prover deployed at:" | awk '{print $5}')
echo "successfully deployed base prover"

echo "deployed addresses:"
echo "optimism inbox: $optimism_inbox"
echo "base inbox: $base_inbox"
echo "optimism prover: $optimism_prover"
echo "base prover: $base_prover"

unset INBOX_ADDRESS



