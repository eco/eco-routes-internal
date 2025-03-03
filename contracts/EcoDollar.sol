// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEcoDollar} from "./interfaces/IEcoDollar.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
// import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract EcoDollar is IEcoDollar, Ownable {
    uint256 public BASE = 1e6; // 1.0 initial scaling factor

    string private _name = "EcoDollar";
    string private _symbol = "eUSD";
    uint8 private _decimals = 6;

    uint256 public rewardMultiplier;

    uint256 public totalShares;

    uint128 public totalFees;

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
        uint256 shares = convertToShares(_tokens);
        return (shares * BASE) / rewardMultiplier;
    }

    function balanceOf(
        address _account
    ) public view override returns (uint256) {
        return (_shares[_account] * rewardMultiplier) / BASE;
    }

    function mint(address _account, uint256 _tokens) public onlyOwner {
        uint256 shares = convertToShares(_tokens);
        _shares[_account] += shares;
        totalShares += shares;

        emit Transfer(address(0), _account, shares);
    }

    function burn(address _account, uint256 _tokens) public onlyOwner {
        uint256 shares = convertToShares(_tokens);
        _shares[_account] -= shares;
        totalShares -= shares;

        emit Transfer(_account, address(0), shares);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transferFrom(msg.sender, recipient, amount);

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
     *
     * @param rewardMultiplier The new reward multiplier.
     */
    function rebase(uint256 rewardMultiplier) external onlyOwner {
        rewardMultiplier = rewardMultiplier;

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
    function _transferFrom(address from, address to, uint256 amount) private {
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

        // _afterTokenTransfer(from, to, amount);
    }
}
