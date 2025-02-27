// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
// import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract EcoDollar is IERC20, Ownable {
    uint256 public BASE = 1e6; // 1.0 initial scaling factor

    string private _name = "EcoDollar";
    string private _symbol = "eUSD";
    uint8 private _decimals = 6;
    
    uint128 public rewardMultiplier;

    uint128 public totalShares;

    uint128 public totalFees;

    address public LIT_AGENT;

    address public immutable MAILBOX;

    mapping(address => uint256) private _shares;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Rebased(uint256 newTotalSupply, uint256 rewardMultiplier);

    constructor(address _owner, address _litAgent, address _mailbox) Ownable(_owner) {
        LIT_AGENT = _litAgent;
        MAILBOX = _mailbox;
        rewardMultiplier = BASE;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return (_shares[_account] * rewardMultiplier) / BASE;
    }

    function mint(address _account, uint256 _tokens) public onlyOwner {
        uint256 shares = convertToShares(_tokens);
        _shares[_account] += shares;
        totalShares += shares;

        emit Transfer(address(0), _account, shares);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 adjustedAmount = (amount * BASE) / rewardMultiplier;
        require(_shares[msg.sender] >= adjustedAmount, "Insufficient balance");

        _shares[msg.sender] -= adjustedAmount;
        _shares[recipient] += adjustedAmount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 adjustedAmount = (amount * BASE) / rewardMultiplier;
        require(_shares[sender] >= adjustedAmount, "Insufficient balance");
        require(
            _allowances[sender][msg.sender] >= amount,
            "Allowance exceeded"
        );

        _shares[sender] -= adjustedAmount;
        _shares[recipient] += adjustedAmount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Private function to set the reward multiplier.
     * @param rewardMultiplier The new reward multiplier.
     */
    function _setRewardMultiplier(uint256 rewardMultiplier) private {
        rewardMultiplier = rewardMultiplier;

        emit RewardMultiplier(rewardMultiplier);
    }

    /**
     * @notice Converts an amount of _shares to tokens.
     * @param _shares The amount of _shares to convert.
     * @return The equivalent amount of tokens.
     */
    function convertToTokens(uint256 _shares) public view returns (uint256) {
        return (_shares * rewardMultiplier) / BASE;
    }

    /**
     * @dev Private function that transfers a specified number of tokens from one address to another.
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * @param from The address from which tokens will be transferred.
     * @param to The address to which tokens will be transferred.
     * @param amount The number of tokens to transfer.
     *
     * Note: This function does not prevent transfers to blocked accounts for gas efficiency.
     * As such, users should be aware of who they're transacting with.
     * Sending tokens to a blocked account could result in those tokens becoming inaccessible.
     */
    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) {
            revert ERC20InvalidSender(from);
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(to);
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 _shares = convertToShares(amount);
        uint256 fromShares = _shares[from];

        if (fromShares < _shares) {
            revert ERC20InsufficientBalance(from, fromShares, _shares);
        }

        unchecked {
            _shares[from] = fromShares - _shares;
            // Overflow not possible: the sum of all _shares is capped by totalShares, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += _shares;
        }

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @notice Converts an amount of _shares to tokens.
     * @param _shares The amount of _shares to convert.
     * @return The equivalent amount of tokens.
     */
    function convertToTokens(uint256 _shares) public view returns (uint256) {
        return (_shares * rewardMultiplier) / BASE;
    }

    /**
     * @notice Converts an amount of _shares to tokens.
     * @param _tokens The amount of _shares to convert.
     * @return The equivalent amount of tokens.
     */
    function convertToShares(uint256 _tokens) public view returns (uint256) {
        return (_shares * BASE) / rewardMultiplier;
    }
}
