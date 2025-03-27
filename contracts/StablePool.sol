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

    // address of Lit agent
    address public immutable LIT_AGENT;

    // address of inbox
    address public immutable INBOX;

    // address of rebase token
    address public immutable REBASE_TOKEN;

    // address of master chain
    uint32 public immutable HOME_CHAIN;

    // address of the Rebaser contract on the master chain
    bytes32 public immutable REBASER;

    // address of mailbox
    address public immutable MAILBOX;

    // address of the relayer
    address public immutable RELAYER; // relayer?

    address public immutable TOKEN_MESSENGER;

    address public immutable MESSAGE_TRANSMITTER;

    // fee leveed on accessLiquidity to fund rebases
    uint256 public rebaseFee;

    // fee leveed on accessLiquidity to fund rebalances
    uint256 public rebalanceFee;

    // fee leveed on intent withdrawal to fund protocol
    uint256 public protocolFee;

    // fee leveed on intent withdrawal to incentivize withdraw call
    uint256 public withdrawerFee;

    // reward for calling rebase
    uint256 public rebasePurse;

    // reward for calling rebalance
    uint256 public rebalancePurse;

    // whether the pool's liquidity can be accessed by solvers via Lit
    bool public litPaused;

    // whether a rebase is currently in progress
    bool public rebaseInProgress;

    // hash of the current token list
    // check event logs to find the current token list
    bytes32 public tokensHash;

    // token address => threshold for rebase
    mapping(address => uint256) public tokenThresholds;

    // token address => withdrawal queue info
    mapping(address => WithdrawalQueueInfo) public queueInfos;

    // keccak256(token, index) => withdrawal queue entry
    mapping(bytes32 => WithdrawalQueueEntry) private withdrawalQueues;

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
        address[] memory init;
        _addTokens(init, _initialTokens);
    }

    //////////////////////////////// PUBLIC FUNCTIONS ////////////////////////////////

    function deposit(address _token, uint256 _amount) external {
        _deposit(_token, _amount);
        EcoDollar(REBASE_TOKEN).mint(msg.sender, _amount);
        emit Deposited(msg.sender, _token, _amount);
    }

    /**
     * @notice Withdraw `_amount` of `_preferredToken` from the pool
     * @param _preferredToken The token to withdraw
     * @param _amount The amount to withdraw
     * @dev if the pool's balance is below the threshold, the user's funds will be taken and they will be added to the withdrawal queue
     */
    function withdraw(address _preferredToken, uint80 _amount) external {
        uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);

        require(
            tokenBalance >= _amount,
            InsufficientTokenBalance(
                _preferredToken,
                tokenBalance,
                _amount - tokenBalance
            )
        );

        IEcoDollar(REBASE_TOKEN).burn(msg.sender, _amount);

        if (tokenBalance > tokenThresholds[_preferredToken]) {
            IERC20(_preferredToken).safeTransfer(msg.sender, _amount);
            emit Withdrawn(msg.sender, _preferredToken, _amount);
        } else {
            // need to rebase, add to withdrawal queue
            _addToWithdrawalQueue(_preferredToken, msg.sender, _amount);
        }
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
        // withdrawal queue processing
        processWithdrawalQueue(_token);

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

        uint256 length = _tokens.length;
        uint256 localTokens = 0;
        for (uint256 i = 0; i < length; ++i) {
            localTokens += IERC20(_tokens[i]).balanceOf(address(this));
        }

        uint256 localShares = EcoDollar(REBASE_TOKEN).totalShares();

        uint256 fee = IMailbox(MAILBOX).quoteDispatch(
            HOME_CHAIN,
            REBASER,
            abi.encodePacked(localTokens, localShares),
            "", // metadata for relayer
            IPostDispatchHook(RELAYER)
        );
        IMailbox(MAILBOX).dispatch{value: fee}(
            HOME_CHAIN,
            REBASER,
            abi.encodePacked(localTokens, localShares),
            "", // metadata for relayer
            IPostDispatchHook(RELAYER)
        );
    }

    /**
     * @notice finishes the rebase flow
     * @param _origin The origin chain of the message
     * @param _sender The address of the sender on the origin chain
     * @param _message The message body
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable override {
        // Ensure only the local mailbox can call this
        require(msg.sender == MAILBOX, "Caller is not the local mailbox");

        require(_sender == REBASER, "sender is not the rebaser contract");

        // Check that the origin chain is valid (non-zero mailbox address)
        require(_origin == HOME_CHAIN, "Invalid origin chain");

        (uint256 rewardMultiplier, uint256 protocolMintRate) = abi.decode(
            _message,
            (uint256, uint256)
        );
        IEcoDollar(REBASE_TOKEN).rebase(rewardMultiplier);

        IEcoDollar(REBASE_TOKEN).mint(
            address(this),
            ((protocolMintRate * IEcoDollar(REBASE_TOKEN).getTotalShares()) /
                1E18)
        );

        rebaseInProgress = false;
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

    /**
     * @notice Processes the withdrawal queue for a token
     * @param _token The token whose withdrawalQueue is being processed
     */
    function processWithdrawalQueue(address _token) internal {
        WithdrawalQueueInfo memory queueInfo = queueInfos[_token];
        WithdrawalQueueEntry memory entry = withdrawalQueues[
            keccak256(abi.encodePacked(_token, queueInfo.head))
        ];
        uint16 head = queueInfo.head;
        while (entry.next != 0) {
            IERC20 stable = IERC20(_token);
            if (stable.balanceOf(address(this)) > tokenThresholds[_token]) {
                stable.safeTransfer(entry.user, entry.amount);
                head = entry.next;
                entry = withdrawalQueues[
                    keccak256(abi.encodePacked(_token, entry.next))
                ];
            } else {
                // dip below threshold during withdrawal queue processing
                emit WithdrawalQueueThresholdReached(_token);
                break;
            }
        }
        queueInfos[_token].head = head;
    }

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

    function _addToWithdrawalQueue(
        address _token,
        address _withdrawer,
        uint80 _amount
    ) internal {
        uint16 index;
        WithdrawalQueueInfo memory queueInfo = queueInfos[_token];
        if (queueInfo.lowest == 0) {
            index = queueInfo.highest;
            queueInfo.highest++;
        } else {
            index = queueInfo.lowest;
            queueInfo.lowest--;
        }
        WithdrawalQueueEntry memory entry = WithdrawalQueueEntry(
            _withdrawer,
            _amount,
            0 //sentinel value
        );
        withdrawalQueues[keccak256(abi.encodePacked(_token, queueInfo.tail))]
            .next = index;
        queueInfo.tail = index;

        withdrawalQueues[keccak256(abi.encodePacked(_token, index))] = entry;

        queueInfos[_token] = queueInfo;

        emit AddedToWithdrawalQueue(_token, entry);
    }
}
