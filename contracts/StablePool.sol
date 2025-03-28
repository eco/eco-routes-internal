// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMailbox, IPostDispatchHook} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import {IMessageRecipient} from "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStablePool} from "./interfaces/IStablePool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EcoDollar} from "./EcoDollar.sol";
import {IEcoDollar} from "./interfaces/IEcoDollar.sol";
import {IInbox} from "./interfaces/IInbox.sol";
import {Route, TokenAmount} from "./types/Intent.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract StablePool is IStablePool, Ownable, IMessageRecipient {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // Immutable address variables
    address public immutable LIT_AGENT;
    address public immutable INBOX;
    address public immutable REBASE_TOKEN;
    uint32 public immutable HOME_CHAIN;
    bytes32 public immutable REBASER;
    address public immutable MAILBOX;
    address public immutable RELAYER;
    address public immutable TOKEN_MESSENGER;
    address public immutable MESSAGE_TRANSMITTER;
    
    // Processor address for withdrawal queue processing
    address public PROCESSOR;

    // Fee parameters
    uint256 public rebaseFee;
    uint256 public rebalanceFee;
    uint256 public protocolFee;
    uint256 public withdrawerFee;
    uint256 public rebasePurse;
    uint256 public rebalancePurse;

    // Emergency withdrawal fee constants
    uint256 public constant EMERGENCY_FEE_RATE = 50;        // 0.5% in basis points (50/10000)
    uint256 public constant EMERGENCY_FEE_MAX = 10000;      // Basis points denominator
    
    // Withdrawal queue constants
    uint256 public constant MIN_QUEUE_TIME = 1 hours;       // Minimum time in queue before eligible for processing
    uint256 public constant MAX_QUEUE_TIME = 7 days;        // Maximum guaranteed queue time before processing
    uint256 public constant MAX_WITHDRAWALS_PER_BATCH = 50; // Gas limit protection
    uint256 public constant GAS_BUFFER = 100000;            // Gas buffer for safe transaction completion
    uint256 public constant MAX_REBASE_AGE = 7 days;        // Maximum age of rebase data before considered stale
    
    // State variables
    bool public litPaused;
    bool public rebaseInProgress;
    bool public withdrawalProcessingActive;      // Processing state flag
    
    // Rebase tracking
    uint256 public lastRebaseTimestamp;          // Last time a rebase was processed
    uint256 public lastRebaseId;                 // ID of the last processed rebase
    uint256 public accumulatedProfit;            // Accumulated profit for rebase
    uint256 public accumulatedProtocolProfit;    // Accumulated profit from emergency withdrawals
    
    // Token management
    bytes32 public tokensHash;  // Hash of the current token list
    mapping(address => uint256) public tokenThresholds;
    
    // Enhanced withdrawal queue with priority
    mapping(uint256 => WithdrawalRequest) public withdrawalQueue;
    uint256 public nextWithdrawalId;             // Next ID to assign
    uint256 public firstPendingWithdrawal;       // First unprocessed withdrawal
    uint256 public totalQueuedWithdrawals;       // Total tokens in withdrawal queue

    modifier checkTokenList(address[] memory tokenList) {
        require(
            keccak256(abi.encode(tokenList)) == tokensHash,
            InvalidTokensHash(tokensHash)
        );
        _;
    }

    constructor(
        address _owner,
        address _litAgent,
        address _inbox,
        address _rebaseToken,
        uint32 _homeChain,
        bytes32 _rebaser,
        address _mailbox,
        address _relayer,
        address _tokenMessenger,
        address _messageTransmitter,
        uint256 _rebaseFee,
        uint256 _rebalanceFee,
        uint256 _protocolFee,
        uint256 _withdrawerFee,
        TokenAmount[] memory _initialTokens
    ) Ownable(_owner) {
        LIT_AGENT = _litAgent;
        INBOX = _inbox;
        REBASE_TOKEN = _rebaseToken;
        HOME_CHAIN = _homeChain;
        REBASER = _rebaser;
        MAILBOX = _mailbox;
        RELAYER = _relayer;
        TOKEN_MESSENGER = _tokenMessenger;
        MESSAGE_TRANSMITTER = _messageTransmitter;
        rebaseFee = _rebaseFee;
        rebalanceFee = _rebalanceFee;
        protocolFee = _protocolFee;
        withdrawerFee = _withdrawerFee;
        
        // Initialize withdrawal queue variables
        PROCESSOR = _owner;  // Initially set processor to owner
        nextWithdrawalId = 1;  // Start with ID 1 for better UX
        firstPendingWithdrawal = 1;
        
        // Initialize timestamps
        lastRebaseTimestamp = block.timestamp;
        
        address[] memory init;
        _addTokens(init, _initialTokens);
    }

    //////////////////////////////// PUBLIC FUNCTIONS ////////////////////////////////

    function deposit(address _token, uint256 _amount) external {
        _deposit(_token, _amount);
        // Update accumulated profit tracking (for yield tracking)
        _updateProfit();
        EcoDollar(REBASE_TOKEN).mint(msg.sender, _amount);
        emit Deposited(msg.sender, _token, _amount);
    }

    /**
     * @notice Standard withdraw function - now adds to the withdrawal queue for fair profit distribution
     * @param _preferredToken The token to withdraw
     * @param _amount The amount to withdraw
     * @dev this adds to the withdrawal queue to be processed after the next rebase
     */
    function withdraw(address _preferredToken, uint80 _amount) external {
        // This now uses the enhanced withdrawal system
        requestWithdrawal(_preferredToken, uint256(_amount), 0);
    }
    
    /**
     * @notice Queue a standard withdrawal request - tokens locked but not burned until after rebase
     * @param _preferredToken The token to withdraw
     * @param _amount The amount to withdraw in tokens
     * @param _waitingPeriod Optional min waiting period (0 for default MIN_QUEUE_TIME)
     */
    function requestWithdrawal(
        address _preferredToken, 
        uint256 _amount,
        uint32 _waitingPeriod
    ) public {
        // Verify token is whitelisted
        if (tokenThresholds[_preferredToken] == 0) {
            revert InvalidToken();
        }
        
        // Check user's balance
        uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);
        if (tokenBalance < _amount) {
            revert InsufficientTokenBalance(
                _preferredToken,
                tokenBalance,
                _amount
            );
        }
        
        // Use default waiting period if 0 is specified
        uint32 waitPeriod = _waitingPeriod == 0 ? uint32(MIN_QUEUE_TIME) : _waitingPeriod;
        
        // Cap maximum waiting period
        if (waitPeriod > MAX_QUEUE_TIME) {
            waitPeriod = uint32(MAX_QUEUE_TIME);
        }
        
        // Calculate share amount at current multiplier
        uint256 currentMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
        uint256 shares = (_amount * 1e18) / currentMultiplier;
        
        // Transfer tokens to contract (lock them without burning)
        IERC20(REBASE_TOKEN).transferFrom(msg.sender, address(this), _amount);
        
        // Add to withdrawal queue using shares
        withdrawalQueue[nextWithdrawalId] = WithdrawalRequest({
            user: msg.sender,
            shareAmount: shares,
            preferredToken: _preferredToken,
            requestTime: block.timestamp,
            waitingPeriod: waitPeriod,
            processed: false
        });
        
        // Update total queued withdrawals
        totalQueuedWithdrawals += _amount;
        
        // Emit withdrawal queued event
        emit WithdrawalQueued(
            nextWithdrawalId,
            msg.sender, 
            _preferredToken, 
            _amount,
            shares
        );
        
        // Increment queue counter
        nextWithdrawalId++;
    }
    
    /**
     * @notice Process emergency withdrawal with fee - immediate processing without waiting
     * @param _preferredToken The token to withdraw
     * @param _amount The amount to withdraw in tokens
     */
    function emergencyWithdraw(address _preferredToken, uint256 _amount) external {
        // Verify token is whitelisted
        if (tokenThresholds[_preferredToken] == 0) {
            revert InvalidToken();
        }
        
        // Check user's balance
        uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);
        if (tokenBalance < _amount) {
            revert InsufficientTokenBalance(
                _preferredToken,
                tokenBalance,
                _amount
            );
        }
        
        // Check if pool has enough liquidity
        uint256 poolTokenBalance = IERC20(_preferredToken).balanceOf(address(this));
        if (poolTokenBalance < tokenThresholds[_preferredToken] + _amount) {
            revert InsufficientPoolLiquidity(_preferredToken, _amount);
        }
        
        // Calculate fee
        uint256 feeAmount = (_amount * EMERGENCY_FEE_RATE) / EMERGENCY_FEE_MAX;
        
        // Calculate net withdrawal amount
        uint256 netWithdrawal = _amount - feeAmount;
        
        // Burn tokens from user
        IEcoDollar(REBASE_TOKEN).burn(msg.sender, _amount);
        
        // Transfer preferred token to user
        IERC20(_preferredToken).safeTransfer(msg.sender, netWithdrawal);
        
        // Add fee to protocol profit
        accumulatedProtocolProfit += feeAmount;
        
        // Emit emergency withdrawal event
        emit EmergencyWithdrawal(
            msg.sender,
            _preferredToken,
            _amount,
            netWithdrawal,
            feeAmount
        );
    }
    
    /**
     * @notice Process the withdrawal queue after rebase
     * @dev Processes withdrawals with priority based on time in queue
     */
    function processWithdrawalQueue() external {
        // Only callable by authorized processors or admin
        if (msg.sender != PROCESSOR && msg.sender != owner()) {
            revert UnauthorizedWithdrawalProcessor(msg.sender);
        }
        
        // Ensure rebase has happened recently
        if (block.timestamp - lastRebaseTimestamp > MAX_REBASE_AGE) {
            revert StaleRebase(lastRebaseTimestamp);
        }
        
        // Set processing active
        withdrawalProcessingActive = true;
        
        // Get current multiplier after rebase
        uint256 currentMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
        
        // Keep track of processed count and gas usage
        uint256 processedCount = 0;
        uint256 initialGas = gasleft();
        
        // First pass: Process withdrawals that have exceeded MAX_QUEUE_TIME (priority)
        for (uint256 i = firstPendingWithdrawal; i < nextWithdrawalId && processedCount < MAX_WITHDRAWALS_PER_BATCH; i++) {
            // Check remaining gas
            if (gasleft() < GAS_BUFFER) break;
            
            WithdrawalRequest storage request = withdrawalQueue[i];
            
            // Skip already processed requests
            if (request.processed) continue;
            
            // Check if this is an old withdrawal (priority processing)
            if (block.timestamp - request.requestTime > MAX_QUEUE_TIME) {
                if (_processWithdrawal(i, request, currentMultiplier)) {
                    processedCount++;
                }
            }
        }
        
        // Second pass: Process withdrawals that meet minimum waiting period
        for (uint256 i = firstPendingWithdrawal; i < nextWithdrawalId && processedCount < MAX_WITHDRAWALS_PER_BATCH; i++) {
            // Check remaining gas
            if (gasleft() < GAS_BUFFER) break;
            
            WithdrawalRequest storage request = withdrawalQueue[i];
            
            // Skip already processed requests
            if (request.processed) continue;
            
            // Process if minimum waiting period has passed
            if (block.timestamp - request.requestTime >= request.waitingPeriod) {
                if (_processWithdrawal(i, request, currentMultiplier)) {
                    processedCount++;
                }
            }
        }
        
        // Update first pending withdrawal
        _updateFirstPendingWithdrawal();
        
        // Reset processing state
        withdrawalProcessingActive = false;
        
        // Emit batch processing event
        emit WithdrawalQueueProcessed(
            processedCount,
            initialGas - gasleft(),
            totalQueuedWithdrawals
        );
    }
    
    /**
     * @notice Cancels a pending withdrawal request
     * @param _withdrawalId The ID of the withdrawal to cancel
     */
    function cancelWithdrawal(uint256 _withdrawalId) external {
        // Get the withdrawal request
        WithdrawalRequest storage request = withdrawalQueue[_withdrawalId];
        
        // Verify request exists and belongs to caller
        if (request.user != msg.sender) {
            revert UnauthorizedCancellation(_withdrawalId, msg.sender);
        }
        
        // Verify request hasn't been processed
        if (request.processed) {
            revert WithdrawalAlreadyProcessed(_withdrawalId);
        }
        
        // Verify withdrawal processing isn't active
        if (withdrawalProcessingActive) {
            revert WithdrawalProcessingActive();
        }
        
        // Calculate token amount at current multiplier
        uint256 currentMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
        uint256 tokenAmount = (request.shareAmount * currentMultiplier) / 1e18;
        
        // Return tokens to user
        IERC20(REBASE_TOKEN).transfer(msg.sender, tokenAmount);
        
        // Mark as processed
        request.processed = true;
        
        // Update total queued withdrawals
        if (tokenAmount <= totalQueuedWithdrawals) {
            totalQueuedWithdrawals -= tokenAmount;
        } else {
            totalQueuedWithdrawals = 0;
        }
        
        // Emit cancellation event
        emit WithdrawalCancelled(_withdrawalId, msg.sender, tokenAmount);
    }
    
    /**
     * @notice Get estimated wait time for a new withdrawal
     * @return waitTime Estimated wait time in seconds
     */
    function getEstimatedWaitTime() external view returns (uint256) {
        // If no rebase for a long time, estimate based on MAX_QUEUE_TIME
        if (block.timestamp - lastRebaseTimestamp > 2 days) {
            return MAX_QUEUE_TIME;
        }
        
        // Base estimate on time since last rebase and number of queued withdrawals
        uint256 avgRebaseInterval = 1 days; // Can be made dynamic based on history
        uint256 queueFactor = totalQueuedWithdrawals > 0 ? 
            (totalQueuedWithdrawals / 10000) + 1 : 1;
        
        uint256 estimatedTime = avgRebaseInterval * queueFactor;
        return estimatedTime > MAX_QUEUE_TIME ? MAX_QUEUE_TIME : estimatedTime;
    }

    /**
     * @notice Checks stable balance of user
     * @param user the address whose balance is to be checked
     */
    function getBalance(address user) external view returns (uint256) {
        return IERC20(REBASE_TOKEN).balanceOf(user);
    }

    function getProtocolFee() external view override returns (uint256) {
        return protocolFee;
    }

    function getWithdrawerFee() external view override returns (uint256) {
        return withdrawerFee;
    }

    /**
     * @notice Called by a solver to fulfill an intent using the pool's liquidity
     * @param _route the route of the intent
     * @param _rewardHash the hash of the intent's reward
     * @param _intentHash the hash of the intent
     * @param _prover the address of the prover
     * @param _litSignature the Lit PKP's signature over the intentHash
     * @dev the Lit agent will only sign the intentHash if the intent is valid, funded on the origin chain, and profitable
     */
    function accessLiquidity(
        bytes32 _intentHash,
        uint96 _executionFee, // stable-denominated
        Route calldata _route,
        bytes32 _rewardHash,
        address _prover,
        bytes calldata _litSignature
    ) external payable {
        require(!litPaused, PoolClosedForCleaning());
        require(
            LIT_AGENT ==
                keccak256(abi.encode(_intentHash, _executionFee)).recover(
                    _litSignature
                ),
            InvalidSignature(_intentHash, _litSignature)
        );
        uint256 requiredFee = rebaseFee + rebalanceFee;
        require(msg.value >= requiredFee, InsufficientFees(requiredFee));

        IInbox(INBOX).fulfillPool{value: msg.value - requiredFee}(
            _route,
            _rewardHash,
            msg.sender, // is this ok, should we have the claimant be an input
            _intentHash,
            _prover,
            _executionFee
        );
    }

    function rebalancePool(
        address _token,
        address _amount,
        uint32 _destinationDomain, //different than chainID, this is the domainID as defined by CCTP
        bytes calldata _litSignature
    ) external payable {
        bytes32 hash = keccak256(
            abi.encode(_token, _amount, _destinationDomain)
        );
        require(
            LIT_AGENT == hash.recover(_litSignature),
            InvalidSignature(hash, _litSignature)
        );
        // TODO: rebalance the pool via CCTP
        (bool success, ) = TOKEN_MESSENGER.call{value: msg.value}(
            abi.encodeWithSignature(
                "depositForBurn(uint256,uint32,bytes32,address)",
                _amount,
                _destinationDomain,
                bytes32(uint256(uint160(address(this)))),
                _token
            )
        );
        // Process withdrawal queue with the new system
        processWithdrawalQueue();

        // send reward to caller
        uint256 toSend = rebalancePurse;
        rebalancePurse = 0;
        (success, ) = payable(msg.sender).call{value: toSend}("");
    }

    function finalizeRebalance(
        bytes calldata message,
        bytes calldata attestation
    ) external {
        (bool success, ) = MESSAGE_TRANSMITTER.call(
            abi.encodeWithSignature(
                "receiveMessage(bytes, bytes)",
                message,
                attestation
            )
        );

        (, uint32 sourceDomain, , , , uint256 amount, ) = abi.decode(
            message,
            (uint8, uint32, uint32, uint64, address, uint256, bytes32)
        );

        emit RebalanceComplete(sourceDomain, amount);
    }

    /**
     * @notice Broadcasts yield information to a central chain for rebase calculations
     * @param _tokens The current list of token addresses
     */
    function initiateRebase(
        address[] calldata _tokens
    ) external onlyOwner checkTokenList(_tokens) {
        require(!rebaseInProgress, "Rebase already in progress");
        rebaseInProgress = true;

        // Calculate local profit
        uint256 localProfit = accumulatedProfit;
        
        // Reset accumulated profit
        accumulatedProfit = 0;
        
        // Add protocol profit from emergency withdrawals
        localProfit += accumulatedProtocolProfit;
        accumulatedProtocolProfit = 0;
        
        // Get total shares from EcoDollar contract
        uint256 localShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
        
        // Create LocalMetrics structure
        LocalMetrics memory metrics = LocalMetrics({
            profit: localProfit,
            totalShares: localShares,
            timestamp: uint64(block.timestamp)
        });
        
        // Encode using consistent format for future service integration
        bytes memory message = abi.encode(metrics);
        
        // Send to Rebaser on home chain
        uint256 fee = IMailbox(MAILBOX).quoteDispatch(
            HOME_CHAIN,
            REBASER,
            message,
            "", // Empty metadata for relayer
            IPostDispatchHook(RELAYER)
        );
        
        IMailbox(MAILBOX).dispatch{value: fee}(
            HOME_CHAIN,
            REBASER,
            message,
            "", // Empty metadata for relayer
            IPostDispatchHook(RELAYER)
        );
        
        // Emit rebase initiated event
        emit RebaseInitiated(localProfit, localShares);
    }

    /**
     * @notice Handles incoming messages from Rebaser
     * @param _origin The origin chain ID
     * @param _sender The sender address in 32-byte form
     * @param _message The message payload
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable override {
        // Security validations
        if (msg.sender != MAILBOX) {
            revert UnauthorizedMailbox(msg.sender, MAILBOX);
        }
        
        if (_sender != REBASER) {
            revert UnauthorizedSender(_sender, REBASER);
        }
        
        if (_origin != HOME_CHAIN) {
            revert InvalidOriginChain(_origin, HOME_CHAIN);
        }
        
        // Decode the rebase result
        RebaseResult memory result = abi.decode(_message, (RebaseResult));
        
        // Store the last rebase timestamp and ID
        lastRebaseTimestamp = result.timestamp;
        lastRebaseId = result.rebaseId;
        
        // Get current multiplier for event emission
        uint256 oldMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
        
        // Update EcoDollar's reward multiplier
        IEcoDollar(REBASE_TOKEN).updateRewardMultiplier(result.multiplier);
        
        // Emit the multiplier update event
        emit RewardMultiplierUpdated(oldMultiplier, result.multiplier, result.rebaseId);
        
        // Reset rebase in progress flag
        rebaseInProgress = false;
        
        // Process withdrawal queues if indicated
        if (result.processQueues) {
            // Auto-process the withdrawal queue after rebase
            _processWithdrawalQueue();
            
            // Emit queue processing event
            emit WithdrawalQueueProcessingTriggered(result.rebaseId);
        }
    }
    
    /**
     * @notice Internal function to process the withdrawal queue
     * @dev Processes a batch of withdrawal requests with the updated multiplier
     */
    function _processWithdrawalQueue() private {
        // Set processing state
        withdrawalProcessingActive = true;
        
        // Get current multiplier after rebase
        uint256 currentMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
        
        // Track processed count for event emission
        uint256 processedCount = 0;
        uint256 initialGas = gasleft();
        
        // Process queue up to gas limit or count limit
        for (uint256 i = firstPendingWithdrawal; i < nextWithdrawalId && processedCount < MAX_WITHDRAWALS_PER_BATCH; i++) {
            // Break if we're running low on gas
            if (gasleft() < GAS_BUFFER) break;
            
            WithdrawalRequest storage request = withdrawalQueue[i];
            
            // Skip already processed requests
            if (request.processed) {
                continue;
            }
            
            // Try to process this withdrawal
            if (_processWithdrawal(i, request, currentMultiplier)) {
                processedCount++;
            }
        }
        
        // Update first pending withdrawal pointer
        _updateFirstPendingWithdrawal();
        
        // Reset processing state
        withdrawalProcessingActive = false;
        
        // Emit batch processing event
        emit WithdrawalQueueProcessed(
            processedCount,
            initialGas - gasleft(),
            totalQueuedWithdrawals
        );
    }

    //////////////////////////////// OWNER FUNCTIONS ////////////////////////////////

    // pause Lit's access to pool funds
    function pauseLit() external onlyOwner {
        litPaused = true;
    }

    // unpause Lit's access to pool funds
    function unpauseLit() external onlyOwner {
        litPaused = false;
    }

    /**
     * @notice Add tokens to the whitelist
     * @param _currentTokens The current list of token addresses
     * @param _tokensToAdd List of addresses of tokens to add
     */
    function addTokens(
        address[] calldata _currentTokens,
        TokenAmount[] calldata _tokensToAdd
    ) external onlyOwner checkTokenList(_currentTokens) {
        _addTokens(_currentTokens, _tokensToAdd);
    }

    /**
     * @notice Remove tokens from the whitelist
     * @param _currentTokens The current list of token addresses
     * @param _tokensToDelist List of addresses of tokens to remove
     */
    function delistTokens(
        address[] calldata _currentTokens,
        address[] calldata _tokensToDelist
    ) external onlyOwner checkTokenList(_currentTokens) {
        uint256 oldLength = _currentTokens.length;
        uint256 delistLength = _tokensToDelist.length;
        // address[] memory newTokens = new address[](oldLength - delistLength); //optimistic case where delist has no duplicates, no unlisted tokens
        address[] memory newTokens = new address[](oldLength); //protects against such cases, but leaves gaps in the array. not a huge problem though, as the array is only in memory, and these methods are not expected to be used often.

        for (uint256 i = 0; i < delistLength; ++i) {
            tokenThresholds[_tokensToDelist[i]] = 0;
        }
        uint256 counter = 0;
        for (uint256 i = 0; i < oldLength; ++i) {
            bool remains = true;
            for (uint256 j = 0; j < delistLength; ++j) {
                if (_currentTokens[i] == _tokensToDelist[j]) {
                    remains = false;
                    break;
                }
            }
            if (remains) {
                newTokens[counter] = _currentTokens[i];
                ++counter;
            }
        }
        tokensHash = keccak256(abi.encode(newTokens));
        emit WhitelistUpdated(newTokens);
    }

    /**
     * @notice Update token thresholds
     * @param _currentTokens The current list of token addresses
     * @param _thresholdChanges List of token addresses and their new thresholds
     */
    function updateThresholds(
        address[] memory _currentTokens,
        TokenAmount[] memory _thresholdChanges
    ) external onlyOwner checkTokenList(_currentTokens) {
        uint256 oldLength = _currentTokens.length;
        uint256 changesLength = _thresholdChanges.length;

        for (uint256 i = 0; i < changesLength; ++i) {
            TokenAmount memory currChange = _thresholdChanges[i];
            require(currChange.amount != 0, UseDelistToken());
            bool whitelisted = false;
            for (uint256 j = 0; j < oldLength; ++j) {
                if (currChange.token == _currentTokens[j]) {
                    tokenThresholds[currChange.token] = currChange.amount;
                    whitelisted = true;
                    break;
                }
            }
            require(whitelisted, UseAddToken());
        }
        emit TokenThresholdsChanged(_thresholdChanges);
    }

    // Legacy code removed - replaced with enhanced withdrawal queue system

    function setRebaseFee(uint96 _fee) external onlyOwner {
        rebaseFee = _fee;
        emit ProtocolFeeChanged(_fee);
    }

    function setRebalanceFee(uint256 _fee) external onlyOwner {
        rebalanceFee = _fee;
        emit ProtocolFeeChanged(_fee);
    }

    function setProtocolFee(uint256 _fee) external onlyOwner {
        protocolFee = _fee;
        emit ProtocolFeeChanged(_fee);
    }

    function setWithdrawerFee(uint256 _fee) external onlyOwner {
        withdrawerFee = _fee;
        emit WithdrawerFeeChanged(_fee);
    }
    
    /**
     * @notice Set the authorized processor address for withdrawal queue processing
     * @param _processor The address of the authorized processor
     */
    function setProcessor(address _processor) external onlyOwner {
        PROCESSOR = _processor;
    }

    //////////////////////////////// INTERNAL FUNCTIONS ////////////////////////////////

    function _addTokens(
        address[] memory _currentTokens,
        TokenAmount[] memory _tokensToAdd
    ) internal {
        uint256 oldLength = _currentTokens.length;
        uint256 addLength = _tokensToAdd.length;

        address[] memory newTokens = new address[](oldLength + addLength);

        uint256 i = 0;
        for (i = 0; i < oldLength; ++i) {
            address curr = _currentTokens[i];
            for (uint256 j = 0; j < addLength; ++j) {
                require(curr != _tokensToAdd[j].token, UseUpdateThreshold());
            }
            newTokens[i] = curr;
        }
        for (uint256 j = 0; j < addLength; ++j) {
            address token = _tokensToAdd[j].token;
            newTokens[i] = token;
            IERC20(token).approve(TOKEN_MESSENGER, type(uint256).max);
            ++i;
        }
        tokensHash = keccak256(abi.encode(newTokens));

        emit WhitelistUpdated(newTokens);
        emit TokenThresholdsChanged(_tokensToAdd);
    }

    function _deposit(address _token, uint256 _amount) internal {
        require(tokenThresholds[_token] > 0, InvalidToken());
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    // Legacy code removed
    
    /**
     * @notice Internal helper to process a single withdrawal
     * @param _id The withdrawal request ID
     * @param _request The withdrawal request
     * @param _currentMultiplier Current EcoDollar multiplier
     * @return success Whether the withdrawal was successfully processed
     */
    function _processWithdrawal(
        uint256 _id,
        WithdrawalRequest storage _request,
        uint256 _currentMultiplier
    ) private returns (bool) {
        // Convert shares to tokens at current post-rebase multiplier
        uint256 tokenAmount = (_request.shareAmount * _currentMultiplier) / 1e18;
        
        // Check if we have sufficient liquidity
        address token = _request.preferredToken;
        if (IERC20(token).balanceOf(address(this)) < tokenThresholds[token] + tokenAmount) {
            // Skip this request if insufficient liquidity
            return false;
        }
        
        // Burn the tokens that were transferred to the contract during queue
        IEcoDollar(REBASE_TOKEN).burn(address(this), tokenAmount);
        
        // Transfer preferred token to user
        IERC20(token).safeTransfer(_request.user, tokenAmount);
        
        // Mark as processed
        _request.processed = true;
        
        // Update total queued withdrawals
        if (tokenAmount <= totalQueuedWithdrawals) {
            totalQueuedWithdrawals -= tokenAmount;
        } else {
            totalQueuedWithdrawals = 0;
        }
        
        // Emit withdrawal processed event
        emit WithdrawalProcessed(
            _id,
            _request.user,
            token,
            tokenAmount,
            block.timestamp - _request.requestTime
        );
        
        return true;
    }
    
    /**
     * @notice Updates the firstPendingWithdrawal pointer
     */
    function _updateFirstPendingWithdrawal() private {
        for (uint256 i = firstPendingWithdrawal; i < nextWithdrawalId; i++) {
            if (!withdrawalQueue[i].processed) {
                firstPendingWithdrawal = i;
                return;
            }
        }
        
        // If all are processed, set to next ID
        firstPendingWithdrawal = nextWithdrawalId;
    }
    
    /**
     * @notice Track accumulated profit for rebase calculations
     */
    function _updateProfit() internal {
        // Here we would add logic to calculate and track the profit
        // This is a placeholder that would be filled with actual profit tracking code
        // For now, it's just a stub to show where profit would be tracked
    }
}
