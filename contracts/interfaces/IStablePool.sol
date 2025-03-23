// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Route, TokenAmount} from "../types/Intent.sol";

interface IStablePool {
    struct WithdrawalQueueEntry {
        address user;
        uint80 amount;
        uint16 next; // may need a higher number...
    }

    struct WithdrawalQueueInfo {
        // same size as WithdrawalQueueEntry.next
        uint16 head;
        uint16 tail;
        uint16 highest;
        uint16 lowest;
    }

    event LitPaused();
    event LitUnpaused();

    event WhitelistUpdated(address[] _newWhitelist);
    event TokenThresholdsChanged(TokenAmount[] _newThresholds);

    event TokenThresholdChanged(address indexed token, uint256 threshold);
    event Deposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event AddedToWithdrawalQueue(
        address indexed user,
        WithdrawalQueueEntry entry
    );

    // this is basically an error state
    event WithdrawalQueueThresholdReached(address token);

    // Custom Errors for Gas Efficiency
    error InvalidToken();
    error InvalidAmount();
    error InsufficientTokenBalance(
        address _token,
        uint256 _balance,
        uint256 _needed
    );
    error InsufficientFees(uint256 _requiredFee);
    error TransferFailed();

    error UseAddToken();
    error UseDelistToken();
    error UseUpdateThreshold();

    error InvalidCaller(address _caller, address _expectedCaller);
    error PoolClosedForCleaning();
    error InvalidSignature(bytes32 _hash, bytes _signature);
    error InvalidTokensHash(bytes32 _expectedHash);

    // privileged functions
    function addTokens(
        address[] calldata _oldTokens,
        TokenAmount[] calldata _whitelistChanges
    ) external;

    function delistTokens(
        address[] calldata _oldTokens,
        address[] calldata _toDelist
    ) external;

    function updateThresholds(
        address[] memory _oldTokens,
        TokenAmount[] memory _thresholdChanges
    ) external;
    function initiateRebase(address[] calldata _tokens) external;
    function unpauseLit() external;
    function pauseLit() external;

    //public functions
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint80 amount) external;
    function getBalance(address user) external view returns (uint256);
    function getProtocolFee() external view returns (uint256);
    function accessLiquidity(
        bytes32 _intentHash,
        uint96 _executionFee,
        uint96 _protocolFee,
        Route calldata _route,
        bytes32 _rewardhash,
        address _prover,
        bytes calldata _signature
    ) external payable;
    function processWithdrawalQueue(address _token) external;
}
