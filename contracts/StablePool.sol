// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStablePool} from "./interfaces/IStablePool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EcoDollar} from "./EcoDollar.sol";

contract StablePool is IStablePool, Ownable {
    using SafeERC20 for IERC20;

    address public immutable LIT_AGENT;

    address public immutable TOKEN;

    address public immutable MAILBOX;

    address[] public allowedTokens;

    mapping(address => uint256) public tokenThresholds;

    mapping(address => WithdrawalQueueEntry[]) public withdrawalQueues;

    constructor(
        address _owner,
        address _litAgent,
        address _token,
        address _mailbox,
        address[] memory _initialTokens
    ) Ownable(_owner) {
        LIT_AGENT = _litAgent;
        TOKEN = token;
        MAILBOX = _mailbox;
        // Initialize with a predefined list of tokens
        for (uint256 i = 0; i < _initialTokens.length; ++i) {
            allowedTokens.push(_initialTokens[i]);
            emit TokenWhitelistChanged(_initialTokens[i], true);
        }
    }

    // Owner can update allowed tokens
    function setAllowedToken(address _token, bool _allowed) external onlyOwner {
        allowedTokens[_token] = _allowed;
        emit TokenWhitelistChanged(_token, _allowed);
    }

    // Deposit function
    function deposit(address _token, uint96 _amount) external {
        _deposit(_token, _amount);
        EcoDollar(TOKEN).mint(LIT_AGENT, _amount);
        emit Deposited(msg.sender, _token, _amount);
    }

    function _deposit(address _token, uint96 _amount) internal {
        require(tokenWhitelist[_token], InvalidToken());
        tokenTotals[_token] += _amount;
        total += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Withdraw `_amount` of `_preferredToken` from the pool
     * @param _preferredToken The token to withdraw
     * @param _amount The amount to withdraw
     */
    function withdraw(address _preferredToken, uint96 _amount) external {
        uint256 tokenTotal = tokenTotals[_preferredToken];
        require(
            tokenTotal >= _amount,
            InsufficientTokenBalance(_preferredToken)
        );

        IERC20(TOKEN).burn(msg.sender, _amount);

        if (tokenTotal > tokenThresholds[_preferredToken]) {
            IERC20(_preferredToken).safeTransfer(msg.sender, _amount);
        } else {
            // need to rebase, add to withdrawal queue
            withdrawalQueues[_preferredToken].push(
                WithdrawalQueueEntry(msg.sender, _amount)
            );
        }
        IERC20(TOKEN).burn(msg.sender, _amount);

        emit Withdrawn(msg.sender, _preferredToken, _amount);
    }

    // Check balance of a user for a specific _token
    function getBalance(
        address user,
        address _token
    ) external view returns (uint256) {
        return IERC20(TOKEN).balanceOf(user);
    }

    function getWithdrawalQueue(
        address _token
    ) external view returns (WithdrawalQueueEntry[] memory) {
        return withdrawalQueues[_token];
    }

    function broadcastYieldInfo() external onlyLitAction {
        uint256 localTokens = 0;
        uint256 length = allowedTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            localTokens += IERC20(allowedTokens[i]).balanceOf(address(this));
        }
        uint256 localShares = EcoDollar(TOKEN).totalShares();

        // hyperlane broadcasting
    }

    function processWithdrawalQueue(address token) public {
        uint256 queueLength = withdrawalQueues[token].length;
        for (uint256 i = 0; i < queueLength; ++i) {
            WithdrawalQueueEntry storage entry = withdrawalQueues[token][i];
            if (tokenTotals[token] > tokenThresholds[token]) {
                IERC20(token).safeTransfer(entry.user, entry.amount);
                tokenTotals[token] -= entry.amount;
            } else {
                break;
            }
        }
        for (uint256 i = 0; i < withdrawal.length; ++i) {
            processWithdrawalQueueForToken(allowedTokens[i]);
        }
        uint256 threshold = tokenThresholds[token];
        WithdrawalQueueEntry[] storage queue = withdrawalQueues[token];
        uint256 length = queue.length;
        for (uint256 i = 0; i < length; ++i) {
            WithdrawalQueueEntry storage entry = queue[i];
            if (tokenTotal > threshold) {
                IERC20(token).safeTransfer(entry.user, entry.amount);
                tokenTotal -= entry.amount;
            } else {
                break;
            }
        }
        withdrawalQueues[token] = queue;

    }
}
