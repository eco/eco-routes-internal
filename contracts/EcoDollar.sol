// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEcoDollar} from "./interfaces/IEcoDollar.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract EcoDollar is IEcoDollar, ERC20, Ownable {
    uint256 public BASE = 1e6; // 1.0 initial scaling factor

    string private _name = "EcoDollar";
    string private _symbol = "eUSD";
    uint8 private _decimals = 6;

    uint256 public rewardMultiplier;

    uint256 public totalShares;

    address public LIT_AGENT;

    address public immutable MAILBOX;

    // in shares
    mapping(address => uint256) private _shares;

    // in tokens
    mapping(address => mapping(address => uint256)) private _allowances;

    event Rebased(uint256 newTotalSupply, uint256 rewardMultiplier);

    //owner is the pool
    constructor(
        address _owner,
        address _litAgent,
        address _mailbox
    ) Ownable(_owner) {
        LIT_AGENT = _litAgent;
        MAILBOX = _mailbox;
        rewardMultiplier = BASE;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return convertToTokens(totalShares);
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
        return (_tokens * BASE) / rewardMultiplier;
    }

    function balanceOf(
        address _account
    ) public view override returns (uint256) {
        return (_shares[_account] * rewardMultiplier) / BASE;
    }

    function mint(address _account, uint256 _tokens) public onlyOwner {
        _mint(_account, _tokens);
    }

    function burn(address _account, uint256 _tokens) public onlyOwner {
        _burn(_account, _tokens);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return super.transfer(recipient, amount);
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
        return super.transferFrom(sender, recipient, amount);
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     *
     * @param _rewardMultiplier The new reward multiplier.
     */
    function rebase(uint256 _rewardMultiplier) external onlyOwner {
        // sanity check
        require(
            _rewardMultiplier > rewardMultiplier,
            RewardMultiplierTooLow(_rewardMultiplier, rewardMultiplier)
        );
        rewardMultiplier = _rewardMultiplier;

        emit Rebased(rewardMultiplier);
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
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 shares = convertToShares(amount);

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            totalSha += shares;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);

        require(from != address(0), ERC20InvalidSender(from));
        require(to != address(0), ERC20InvalidReceiver(to));

        uint256 balance = balanceOf(from);
        require(
            balance >= amount,
            ERC20InsufficientBalance(from, amount, amount - balance)
        );

        uint256 shares = convertToShares(amount);
        uint256 fromShares = _shares[from];

        unchecked {
            _shares[from] = fromShares - shares;
            // Overflow not possible: the sum of all _shares is capped by totalShares, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += shares;
        }

        return true;
        // _afterTokenTransfer(from, to, amount);
    }
}
