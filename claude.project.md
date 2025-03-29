# ECO ROUTES PROTOCOL - AGENT INSTRUCTIONS

## PROJECT OVERVIEW

The Eco Routes Protocol is a decentralized intent-based system that allows users to submit their intent to the network and have it fulfilled by a solver on the destination rollup of their choice. The protocol is designed for permissionless, trust-neutral cross-L2 transactions with proof verification.

### Core Components

1. **IntentSource**: Source-chain contract for intent creation and reward management
   - Handles publishing, funding, and reward claims for intents
   - Creates unique vaults for each intent to store rewards

2. **Inbox**: Destination-chain contract for executing intents
   - Processes solver fulfillment requests
   - Executes the intent's target calls
   - Supports different proving methods (storage-based and message-based)

3. **Prover System**:
   - **BaseProver**: Abstract contract defining proving interface
   - **HyperProver**: Fast cross-chain verification using Hyperlane messaging
   - **StorageProver**: Secure verification using cross-chain state root proofs

4. **ERC7683 Implementation**:
   - **Eco7683OriginSettler**: ERC-7683 compliant contract for creating intents
   - **Eco7683DestinationSettler**: ERC-7683 compliant contract for fulfilling intents

## DEVELOPMENT ENVIRONMENT

### Prerequisites

- Node.js v18.20.3 (using nvm)
- Yarn v1.22.19
- Foundry (forge, anvil, cast)
- Solidity v0.8.26

### Project Structure

- `/contracts`: Solidity smart contracts
  - `/interfaces`: Contract interfaces
  - `/prover`: Prover implementations
  - `/types`: Custom data types
  - `/tools`: Deployment utilities
- `/scripts`: Deployment and utility scripts
  - `/viem_deploy`: Viem-based deployment system
- `/test`: Test files (mix of Hardhat and Forge tests)
- `/config`: Chain-specific configurations

## BUILD SYSTEM

The project is transitioning from Hardhat to Foundry while maintaining compatibility with both.

### Foundry Setup

```toml
# foundry.toml
solc_version="0.8.26"
evm_version = "paris"
src = "contracts"
out = "out"
libs = ["lib"]
bytecode_hash = "none"
cbor_metadata = false
optimize = true
via-ir = true
runs = 1000
```

### Environment Setup

Create a `.env` file based on `.env.example` with:

- Chain RPC URLs and API keys
- Private keys for deployment
- Hyperlane mailbox addresses
- Deploy settings

## COMMAND REFERENCE

### Core Development Commands

```bash
# Install dependencies
yarn install

# Build contracts (Hardhat)
yarn build

# Format code
yarn format

# Lint code
yarn lint

# Run tests
yarn test               # Run all tests
yarn test:hardhat       # Run only Hardhat tests
yarn test:ts            # Run TypeScript tests

# Clean build artifacts
yarn clean
```

### Foundry Commands

```bash
# Compile contracts
forge build

# Run Forge tests
forge test

# Run specific test
forge test --match-contract <ContractName>

# Generate gas report
forge snapshot

# Format code
forge fmt

# Deploy contracts (using Foundry script)
forge script scripts/Deploy.s.sol --rpc-url <RPC_URL> --broadcast --private-key <PRIVATE_KEY>

# Multi-chain deployment
./scripts/MultiDeploy.sh

# Verify contracts
./scripts/Verify.sh
```

### Security Analysis

```bash
# Generate call graph
yarn callGraph

# Generate inheritance graph
yarn inheritanceGraph 

# Analyze contract with Slither
yarn vulnerability

# Generate contract summary
yarn contractSummary
```

## MIGRATION STRATEGY (HARDHAT TO FORGE)

The project is transitioning from Hardhat to Forge following these practices:

1. **Dual Compatibility**:
   - Maintain both Hardhat and Forge configurations
   - Support both testing frameworks in parallel
   - Use foundry scripts for new deployments

2. **Migration Process**:
   - Update all contracts to be Forge-compatible
   - Create Forge deployment scripts (Deploy.s.sol)
   - Move tests to Forge format for new features
   - Maintain Hardhat tests for backwards compatibility

3. **Best Practices**:
   - Use forge fmt to format code
   - Prefer forge test over hardhat test for new tests
   - Run forge snapshot for gas analysis
   - Use Forge scripts for deployments

## TESTING PROTOCOLS

1. **Contract Testing**:
   - Run `forge test` for basic contract validation
   - Use `forge test --match-contract <ContractName>` for specific tests
   - Check gas usage with `forge snapshot`

2. **End-to-End Testing**:
   - Testnet deployment with `yarn deployTestnet`
   - Cross-chain intent fulfillment with `yarn intentSolve`
   - Intent withdrawal with `yarn intentWithdraw`

3. **Security Testing**:
   - Run `slither .` for comprehensive security analysis
   - Address critical issues before deployments
   - Document accepted risks with slither-disable-next-line comments

## DEPLOYMENT PROTOCOLS

### Testnet Deployment

```bash
# Deploy on EcoTestnet
yarn deployEcoTestnet

# Deploy on BaseSepolia
yarn deployBaseSepolia

# Deploy on OptimismSepolia
yarn deployOptimismSepolia

# Deploy provers
yarn proverDeployEcoTestnet
```

### Mainnet Deployment

```bash
# Deploy on Base
yarn deployBase

# Deploy on Optimism
yarn deployOptimism

# Deploy provers
yarn proverDeployBase
```

### Foundry Deployment

```bash
# Set up environment variables in .env file
PRIVATE_KEY=<private_key>
DEPLOY_FILE="out/deploy.csv"
SALT=<deployment_salt>
CHAIN_IDS="10,8453"  # Chain IDs to deploy to
RPC_URL_10=<optimism_rpc_url>
RPC_URL_8453=<base_rpc_url>
MAILBOX_10=<optimism_hyperlane_mailbox>
MAILBOX_8453=<base_hyperlane_mailbox>

# Run multi-chain deployment
./scripts/MultiDeploy.sh

# Verify deployed contracts
./scripts/Verify.sh
```

## CODE STANDARDS

1. **Solidity Standards**:
   - Solidity v0.8.26
   - Format with `forge fmt`
   - 4 spaces indentation
   - Function order: external → public → internal → private
   - Use custom errors instead of require strings
   - NatSpec documentation for all public/external interfaces
   - Emit events for state changes

2. **Security Standards**:
   - Always check for reentrancy in asset-transferring functions
   - Implement checks-effects-interactions pattern
   - Validate cross-chain compatibility
   - Use proper access control

3. **Testing Standards**:
   - Write comprehensive tests for each contract
   - Test edge cases and failure modes
   - Use Forge's built-in testing utilities

## PERFORMANCE CONSIDERATIONS

1. **Gas Optimization**:
   - Monitor gas usage with `forge snapshot`
   - Optimize storage layouts
   - Batch operations where possible

2. **Cross-Chain Efficiency**:
   - Use HyperProver for faster cross-chain verification
   - Batch cross-chain messages when possible
   - Consider gas costs on destination chains

## TROUBLESHOOTING GUIDELINES

1. **Compilation Issues**:
   - Check Solidity version compatibility
   - Verify import paths
   - Run `forge build --force` to rebuild all contracts

2. **Test Failures**:
   - Use `forge test -vvv` for verbose output
   - Check event logs for error information
   - Verify test environment setup

3. **Deployment Issues**:
   - Verify RPC URL connectivity
   - Check gas price settings
   - Ensure correct private key and sufficient funds

## MAINTENANCE PROTOCOLS

1. **Version Control**:
   - Branch naming convention: `<type>/<component>/<description>`
   - Commit messages should be clear and descriptive
   - Run tests before making pull requests

2. **Documentation**:
   - Update relevant documentation for any contract changes
   - Document security considerations 
   - Maintain clear NatSpec comments

3. **Security Audits**:
   - Run Slither analysis before major releases
   - Document any ignored warnings with justification
   - Regular security reviews of critical components

By following these instructions, you'll be able to effectively contribute to the Eco Routes Protocol codebase, leveraging both Hardhat and Forge as the project transitions between build systems.