// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStablePool {
    struct WithdrawalQueueEntry {
        address user;
        uint96 amount;
    }

    event TokenWhitelistChanged(address indexed token, bool allowed);
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

    // Custom Errors for Gas Efficiency
    error InvalidToken();
    error InvalidAmount();
    error InsufficientTokenBalance(address _token);
    error TransferFailed();

    function setAllowedToken(address token, bool allowed) external;
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getBalance(
        address user,
        address token
    ) external view returns (uint256);
}
